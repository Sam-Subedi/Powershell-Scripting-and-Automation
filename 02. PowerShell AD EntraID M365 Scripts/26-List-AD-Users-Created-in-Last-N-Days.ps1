#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS  List all AD users created in the last N days, sorted newest first.
.NOTES
    Usage   : .\26-List-AD-Users-Created-in-Last-N-Days.ps1 -Days 30
              .\26-List-AD-Users-Created-in-Last-N-Days.ps1 -Days 7 -EnabledOnly
              .\26-List-AD-Users-Created-in-Last-N-Days.ps1 -Days 90 -SearchBase 'OU=Sales,DC=contoso,DC=com'
#>
param(
    [int]$Days          = 30,
    [string]$SearchBase = '',
    [string]$NameFilter = '',
    [string]$OutputPath = ".\NewADUsers_$(Get-Date -Format 'yyyyMMdd').csv",
    [switch]$EnabledOnly
)
Import-Module ActiveDirectory -ErrorAction Stop
$cutoff = (Get-Date).AddDays(-$Days)
Write-Host "Users created since $($cutoff.ToString('yyyy-MM-dd')) (last $Days days)" -ForegroundColor Cyan

$p = @{
    Filter     = { whenCreated -ge $cutoff }
    Properties = @('SamAccountName','DisplayName','GivenName','Surname','UserPrincipalName','EmailAddress','Title','Department','Company','Manager','Enabled','whenCreated','PasswordLastSet','DistinguishedName')
}
if ($SearchBase) { $p['SearchBase'] = $SearchBase }
$users = Get-ADUser @p
if ($EnabledOnly) { $users = $users | Where-Object { $_.Enabled -eq $true } }
if ($NameFilter)  { $users = $users | Where-Object { $_.DisplayName -like $NameFilter -or $_.SamAccountName -like $NameFilter } }
$users = $users | Sort-Object whenCreated -Descending

$report = $users | ForEach-Object {
    $mgr = $null
    if ($_.Manager) { try { $mgr = (Get-ADUser -Identity $_.Manager -Properties DisplayName).DisplayName } catch {} }
    [PSCustomObject]@{
        WhenCreated=$_.whenCreated; DaysAgo=[int](New-TimeSpan -Start $_.whenCreated -End (Get-Date)).TotalDays
        SamAccountName=$_.SamAccountName; DisplayName=$_.DisplayName; Email=$_.EmailAddress
        Title=$_.Title; Department=$_.Department; Company=$_.Company; Manager=$mgr; Enabled=$_.Enabled
        OU=($_.DistinguishedName -replace '^CN=[^,]+,','')
    }
}
$report | Format-Table WhenCreated,DaysAgo,SamAccountName,DisplayName,Department,Enabled -AutoSize
$report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Exported $($report.Count) users to: $OutputPath" -ForegroundColor Green
Write-Host 'By Department:' -ForegroundColor Cyan
$report | Where-Object { $_.Department } | Group-Object Department | Sort-Object Count -Descending | Select-Object Count,Name | Format-Table -AutoSize
