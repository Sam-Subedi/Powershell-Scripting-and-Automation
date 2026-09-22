#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS  Get the true last logon for every AD user by querying ALL Domain Controllers.
.DESCRIPTION
    LastLogon is NOT replicated between DCs. This script queries every DC and returns
    the most recent value per user — the only accurate way to know last logon time.
.NOTES
    Usage   : .\09-Get-AD-User-LastLogon-All-DCs.ps1
              .\09-Get-AD-User-LastLogon-All-DCs.ps1 -DaysInactive 60 -EnabledOnly
#>
param(
    [string]$OutputPath  = ".\ADUsers_LastLogon_$(Get-Date -Format 'yyyyMMdd').csv",
    [string]$SearchBase  = '',
    [int]$DaysInactive   = 0,
    [switch]$EnabledOnly
)
Import-Module ActiveDirectory -ErrorAction Stop

$dcs = Get-ADDomainController -Filter * | Select-Object -ExpandProperty HostName
Write-Host "Querying $($dcs.Count) Domain Controller(s)..." -ForegroundColor Cyan

$filter = if ($EnabledOnly) { { Enabled -eq $true } } else { { SamAccountName -like '*' } }
$uParams = @{
    Filter     = $filter
    Properties = @('DisplayName','LastLogon','LastLogonDate','Enabled','PasswordLastSet','Department','DistinguishedName')
}
if ($SearchBase) { $uParams['SearchBase'] = $SearchBase }
$allUsers = Get-ADUser @uParams

$llMap = @{}
foreach ($dc in $dcs) {
    Write-Host "  $dc" -ForegroundColor DarkCyan
    try {
        Get-ADUser -Filter $filter -Server $dc -Properties LastLogon -ErrorAction Stop |
            ForEach-Object {
                if (-not $llMap.ContainsKey($_.SamAccountName) -or $_.LastLogon -gt $llMap[$_.SamAccountName]) {
                    $llMap[$_.SamAccountName] = $_.LastLogon
                }
            }
    } catch { Write-Warning "  Could not query '$dc': $_" }
}

$report = $allUsers | ForEach-Object {
    $raw = $llMap[$_.SamAccountName]
    $ll  = if ($raw -and $raw -gt 0) { [DateTime]::FromFileTime($raw) } else { $null }
    [PSCustomObject]@{
        SamAccountName    = $_.SamAccountName
        DisplayName       = $_.DisplayName
        Enabled           = $_.Enabled
        Department        = $_.Department
        LastLogon_AllDCs  = $ll
        LastLogonDate_Repl= $_.LastLogonDate
        PasswordLastSet   = $_.PasswordLastSet
        DaysSinceLogon    = if ($ll) { [int](New-TimeSpan -Start $ll -End (Get-Date)).TotalDays } else { 99999 }
        OU                = ($_.DistinguishedName -replace '^CN=[^,]+,','')
    }
} | Sort-Object DaysSinceLogon -Descending

if ($DaysInactive -gt 0) { $report = $report | Where-Object { $_.DaysSinceLogon -ge $DaysInactive } }
$report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Exported $($report.Count) users to: $OutputPath" -ForegroundColor Green
$report | Select-Object SamAccountName, DisplayName, LastLogon_AllDCs, DaysSinceLogon, Enabled | Format-Table -AutoSize
