#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS  Migrate AD users from a source domain to a target domain, recreating accounts with attributes.
.NOTES
    For full SID history migration, use Microsoft ADMT (Active Directory Migration Tool).
    This script handles attribute-based recreation and group membership matching by name.
    CSV Columns: SamAccountName, TargetOU (optional), NewPassword (optional)
    Usage   : .\32-Migrate-AD-Users-to-New-Domain.ps1 -SourceDomain old.local -TargetDomain new.local -CsvPath users.csv -SourceCredential (Get-Credential) -TargetCredential (Get-Credential)
#>
param(
    [Parameter(Mandatory)][string]$SourceDomain,
    [Parameter(Mandatory)][string]$TargetDomain,
    [string]$CsvPath,
    [string]$DefaultTargetOU,
    [Parameter(Mandatory)][System.Management.Automation.PSCredential]$SourceCredential,
    [Parameter(Mandatory)][System.Management.Automation.PSCredential]$TargetCredential,
    [string]$DefaultPassword = '',
    [switch]$MigrateGroupMemberships,
    [switch]$WhatIf
)
Write-Host "Source: $SourceDomain  ->  Target: $TargetDomain" -ForegroundColor Cyan
$srcP = @{Server=$SourceDomain;Credential=$SourceCredential;Filter={Enabled -eq $true};Properties=@('SamAccountName','DisplayName','GivenName','Surname','UserPrincipalName','EmailAddress','Title','Department','Company','OfficePhone','MobilePhone','Description','StreetAddress','City','State','PostalCode','Country','PasswordNeverExpires','MemberOf')}

$csvUsers = if ($CsvPath) { Import-Csv -Path $CsvPath } else { $null }
if ($csvUsers) {
    $sams = $csvUsers.SamAccountName
    $srcP['Filter'] = { Enabled -eq $true }
}
$sourceUsers = Get-ADUser @srcP
if ($csvUsers) { $sourceUsers = $sourceUsers | Where-Object { $_.SamAccountName -in $csvUsers.SamAccountName } }
Write-Host "Migrating $($sourceUsers.Count) user(s)." -ForegroundColor Green

$migrated=0; $skipped=0; $failed=0
foreach ($u in $sourceUsers) {
    $sam = $u.SamAccountName
    Write-Host "Processing: $sam" -ForegroundColor Yellow
    $targetOU = $DefaultTargetOU
    if ($csvUsers) {
        $row = $csvUsers | Where-Object { $_.SamAccountName -eq $sam }
        if ($row.TargetOU) { $targetOU = $row.TargetOU }
    }
    if (-not $targetOU) { Write-Warning "  No TargetOU for '$sam'. Skipping."; $skipped++; continue }
    if (Get-ADUser -Filter "SamAccountName -eq '$sam'" -Server $TargetDomain -Credential $TargetCredential -ErrorAction SilentlyContinue) {
        Write-Warning "  '$sam' already exists in target. Skipping."; $skipped++; continue
    }
    $pwd = $DefaultPassword
    if ($csvUsers) { $row = $csvUsers | Where-Object { $_.SamAccountName -eq $sam }; if ($row.NewPassword) { $pwd = $row.NewPassword } }
    if (-not $pwd) { $pwd = "Migrate@$(Get-Random -Minimum 1000 -Maximum 9999)!" }
    $np = @{
        Server=$TargetDomain; Credential=$TargetCredential
        SamAccountName=$sam; UserPrincipalName="$sam@$TargetDomain"; Name=$u.Name
        DisplayName=$u.DisplayName; GivenName=$u.GivenName; Surname=$u.Surname
        AccountPassword=(ConvertTo-SecureString $pwd -AsPlainText -Force)
        Enabled=$true; ChangePasswordAtLogon=$true; Path=$targetOU
    }
    foreach ($a in @('EmailAddress','Title','Department','Company','OfficePhone','MobilePhone','Description','StreetAddress','City','State','PostalCode','Country')) {
        if ($u.$a) { $np[$a]=$u.$a }
    }
    if ($u.PasswordNeverExpires) { $np['PasswordNeverExpires']=$true }
    try {
        New-ADUser @np -WhatIf:$WhatIf
        Write-Host "  $(if($WhatIf){'[WhatIf] Would create'}else{'Created'}) '$sam' in '$targetOU'" -ForegroundColor Green
        $migrated++
        if ($MigrateGroupMemberships -and -not $WhatIf) {
            foreach ($dn in $u.MemberOf) {
                try {
                    $sg = Get-ADGroup -Identity $dn -Server $SourceDomain -Credential $SourceCredential
                    $tg = Get-ADGroup -Filter "Name -eq '$($sg.Name)'" -Server $TargetDomain -Credential $TargetCredential -ErrorAction SilentlyContinue
                    if ($tg) { Add-ADGroupMember -Identity $tg.Name -Members $sam -Server $TargetDomain -Credential $TargetCredential -Confirm:$false; Write-Host "    Group: $($sg.Name)" -ForegroundColor DarkGreen }
                    else     { Write-Warning "    Group '$($sg.Name)' not in target domain." }
                } catch { Write-Warning "    Group error: $_" }
            }
        }
    } catch { Write-Error "  Failed '$sam': $_"; $failed++ }
}
Write-Host "Migrated: $migrated | Skipped: $skipped | Failed: $failed" -ForegroundColor Cyan
Write-Host "Remind users of new UPN: username@$TargetDomain" -ForegroundColor Yellow
