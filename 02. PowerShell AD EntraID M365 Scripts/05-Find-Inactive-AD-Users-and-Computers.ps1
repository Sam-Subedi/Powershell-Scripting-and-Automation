#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS  Find AD users and computers inactive for more than N days. Optionally disable them.
.NOTES
    Usage   : .\05-Find-Inactive-AD-Users-and-Computers.ps1 -DaysInactive 90
              .\05-Find-Inactive-AD-Users-and-Computers.ps1 -DaysInactive 90 -IncludeUsers -DisableInactive -WhatIf
#>
param(
    [int]$DaysInactive    = 90,
    [string]$OutputPath   = ".\InactiveObjects_$(Get-Date -Format 'yyyyMMdd').csv",
    [switch]$IncludeUsers,
    [switch]$IncludeComputers,
    [switch]$DisableInactive,
    [switch]$WhatIf,
    [string]$SearchBase   = ''
)
Import-Module ActiveDirectory -ErrorAction Stop
if (-not $IncludeUsers -and -not $IncludeComputers) { $IncludeUsers = $true; $IncludeComputers = $true }
$cutoff  = (Get-Date).AddDays(-$DaysInactive)
$results = [System.Collections.Generic.List[PSCustomObject]]::new()
$baseParams = @{
    Filter     = { Enabled -eq $true }
    Properties = @('LastLogonDate','PasswordLastSet','DistinguishedName','whenCreated')
}
if ($SearchBase) { $baseParams['SearchBase'] = $SearchBase }

if ($IncludeUsers) {
    Write-Host "Scanning users inactive > $DaysInactive days..." -ForegroundColor Cyan
    Get-ADUser @baseParams | Where-Object {
        $_.whenCreated -lt $cutoff -and ($null -eq $_.LastLogonDate -or $_.LastLogonDate -lt $cutoff)
    } | ForEach-Object {
        $results.Add([PSCustomObject]@{
            ObjectType='User'; SamAccountName=$_.SamAccountName; Name=$_.Name
            LastLogonDate=$_.LastLogonDate; PasswordLastSet=$_.PasswordLastSet
            WhenCreated=$_.whenCreated
            OU=($_.DistinguishedName -replace '^CN=[^,]+,','')
        })
        if ($DisableInactive) { Disable-ADAccount -Identity $_.SamAccountName -WhatIf:$WhatIf }
    }
}
if ($IncludeComputers) {
    Write-Host "Scanning computers inactive > $DaysInactive days..." -ForegroundColor Cyan
    Get-ADComputer @baseParams | Where-Object {
        $_.whenCreated -lt $cutoff -and ($null -eq $_.LastLogonDate -or $_.LastLogonDate -lt $cutoff)
    } | ForEach-Object {
        $results.Add([PSCustomObject]@{
            ObjectType='Computer'; SamAccountName=$_.SamAccountName; Name=$_.Name
            LastLogonDate=$_.LastLogonDate; PasswordLastSet=$_.PasswordLastSet
            WhenCreated=$_.whenCreated
            OU=($_.DistinguishedName -replace '^CN=[^,]+,','')
        })
        if ($DisableInactive) { Disable-ADAccount -Identity $_.SamAccountName -WhatIf:$WhatIf }
    }
}
$results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Found $($results.Count) inactive objects -> $OutputPath" -ForegroundColor Green
$results | Format-Table ObjectType, SamAccountName, LastLogonDate, WhenCreated -AutoSize
