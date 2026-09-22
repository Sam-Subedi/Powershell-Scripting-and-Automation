#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS  Find an AD user's full profile by email address. Supports single or bulk CSV lookup.
.NOTES
    Searches both mail attribute and ProxyAddresses (Exchange alias support).
    CSV Columns: Email
    Usage   : .\25-Look-Up-AD-User-Details-by-Email.ps1 -Email john.doe@contoso.com
              .\25-Look-Up-AD-User-Details-by-Email.ps1 -CsvPath emails.csv -OutputPath results.csv
#>
param(
    [string]$Email,
    [string]$CsvPath,
    [string]$OutputPath = ''
)
Import-Module ActiveDirectory -ErrorAction Stop
$props = @('SamAccountName','DisplayName','GivenName','Surname','UserPrincipalName','EmailAddress','ProxyAddresses','Title','Department','Company','Manager','OfficePhone','MobilePhone','Office','Enabled','LastLogonDate','PasswordLastSet','whenCreated','DistinguishedName','MemberOf')

function Find-ByEmail ([string]$addr) {
    $addr = $addr.Trim().ToLower()
    $u = Get-ADUser -Filter "EmailAddress -eq '$addr'" -Properties $props -ErrorAction SilentlyContinue
    if (-not $u) { $u = Get-ADUser -Filter "ProxyAddresses -like '*$addr*'" -Properties $props -ErrorAction SilentlyContinue | Select-Object -First 1 }
    if (-not $u) { Write-Warning "Not found: $addr"; return $null }
    $mgr = $null
    if ($u.Manager) { try { $mgr = (Get-ADUser -Identity $u.Manager -Properties DisplayName).DisplayName } catch {} }
    [PSCustomObject]@{
        Email=$addr; SamAccountName=$u.SamAccountName; UPN=$u.UserPrincipalName
        DisplayName=$u.DisplayName; FirstName=$u.GivenName; LastName=$u.Surname
        Title=$u.Title; Department=$u.Department; Company=$u.Company; Manager=$mgr
        Phone=$u.OfficePhone; Mobile=$u.MobilePhone; Office=$u.Office
        Enabled=$u.Enabled; LastLogonDate=$u.LastLogonDate; PasswordLastSet=$u.PasswordLastSet
        WhenCreated=$u.whenCreated; GroupCount=$u.MemberOf.Count
        ProxyAddresses=($u.ProxyAddresses -join '; ')
        OU=($u.DistinguishedName -replace '^CN=[^,]+,','')
    }
}
$emails = if ($CsvPath) { (Import-Csv $CsvPath).Email | Where-Object { $_ } }
          elseif ($Email) { @($Email) }
          else { Write-Error 'Provide -Email or -CsvPath.'; exit 1 }

$results = $emails | ForEach-Object { Find-ByEmail $_ } | Where-Object { $_ }
$results | Format-List Email,SamAccountName,DisplayName,Title,Department,Company,Manager,Phone,Mobile,Enabled,LastLogonDate
if ($OutputPath) { $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8; Write-Host "Exported: $OutputPath" -ForegroundColor Green }
