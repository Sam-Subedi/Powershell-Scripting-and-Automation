#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS  Find inactive AD computers based on LastLogonDate and PasswordLastSet. Optionally disable or move them.
.NOTES
    A computer is inactive when BOTH LastLogonDate AND PasswordLastSet exceed the threshold.
    This dual-check reduces false positives from computers offline during DC sync.
    Usage   : .\34-Find-Inactive-AD-Computers.ps1 -DaysInactive 90
              .\34-Find-Inactive-AD-Computers.ps1 -DaysInactive 90 -DisableInactive -WhatIf
              .\34-Find-Inactive-AD-Computers.ps1 -DaysInactive 90 -MoveInactive -MoveToOU 'OU=Disabled,DC=domain,DC=com'
#>
param(
    [int]$DaysInactive    = 90,
    [string]$SearchBase   = '',
    [string]$MoveToOU     = '',
    [string]$OutputPath   = ".\InactiveComputers_$(Get-Date -Format 'yyyyMMdd').csv",
    [switch]$DisableInactive,
    [switch]$MoveInactive,
    [switch]$WhatIf,
    [switch]$IncludeAlreadyDisabled
)
Import-Module ActiveDirectory -ErrorAction Stop
$cutoff = (Get-Date).AddDays(-$DaysInactive)
Write-Host "=== Inactive AD Computers (> $DaysInactive days) ===" -ForegroundColor Cyan

$p = @{
    Filter     = if ($IncludeAlreadyDisabled) { {Name -like '*'} } else { {Enabled -eq $true} }
    Properties = @('Name','DNSHostName','IPv4Address','OperatingSystem','OperatingSystemVersion','LastLogonDate','PasswordLastSet','Enabled','whenCreated','DistinguishedName','Description')
}
if ($SearchBase) { $p['SearchBase']=$SearchBase }
$all = Get-ADComputer @p

$inactive = $all | Where-Object {
    $_.whenCreated -lt $cutoff -and
    ($null -eq $_.LastLogonDate  -or $_.LastLogonDate  -lt $cutoff) -and
    ($null -eq $_.PasswordLastSet -or $_.PasswordLastSet -lt $cutoff)
}
Write-Host "Total: $($all.Count)  |  Inactive: $($inactive.Count)" -ForegroundColor $(if($inactive.Count){'Yellow'}else{'Green'})

$report = $inactive | ForEach-Object {
    [PSCustomObject]@{
        ComputerName     = $_.Name
        DNSHostName      = $_.DNSHostName
        IPv4Address      = $_.IPv4Address
        OperatingSystem  = $_.OperatingSystem
        OSVersion        = $_.OperatingSystemVersion
        Enabled          = $_.Enabled
        LastLogonDate    = $_.LastLogonDate
        DaysSinceLogon   = if ($_.LastLogonDate) { [int](New-TimeSpan -Start $_.LastLogonDate -End (Get-Date)).TotalDays } else { 99999 }
        PasswordLastSet  = $_.PasswordLastSet
        WhenCreated      = $_.whenCreated
        AgeInDays        = [int](New-TimeSpan -Start $_.whenCreated -End (Get-Date)).TotalDays
        Description      = $_.Description
        OU               = ($_.DistinguishedName -replace '^CN=[^,]+,','')
        DistinguishedName= $_.DistinguishedName
    }
} | Sort-Object DaysSinceLogon -Descending

$report | Format-Table ComputerName,OperatingSystem,LastLogonDate,DaysSinceLogon,Enabled -AutoSize

if ($DisableInactive) {
    Write-Host 'Disabling inactive computers...' -ForegroundColor Yellow
    $inactive | Where-Object { $_.Enabled -eq $true } | ForEach-Object {
        try {
            Disable-ADAccount -Identity $_.SamAccountName -WhatIf:$WhatIf
            if (-not $WhatIf) { Set-ADComputer -Identity $_.SamAccountName -Description "Disabled $(Get-Date -Format 'yyyy-MM-dd') - Inactive >$DaysInactive days"; Write-Host "  Disabled: $($_.Name)" -ForegroundColor Yellow }
            else               { Write-Host "  [WhatIf] Would disable: $($_.Name)" -ForegroundColor Cyan }
        } catch { Write-Warning "  Failed to disable '$($_.Name)': $_" }
    }
}
if ($MoveInactive -and $MoveToOU) {
    Write-Host "Moving inactive computers to '$MoveToOU'..." -ForegroundColor Yellow
    $inactive | ForEach-Object {
        try {
            Move-ADObject -Identity $_.DistinguishedName -TargetPath $MoveToOU -WhatIf:$WhatIf
            if (-not $WhatIf) { Write-Host "  Moved: $($_.Name)" -ForegroundColor Yellow }
            else               { Write-Host "  [WhatIf] Would move: $($_.Name)" -ForegroundColor Cyan }
        } catch { Write-Warning "  Failed to move '$($_.Name)': $_" }
    }
}
$report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Exported to: $OutputPath" -ForegroundColor Green

Write-Host 'By OS:' -ForegroundColor Cyan
$report | Group-Object OperatingSystem | Sort-Object Count -Descending | Select-Object Count,Name | Format-Table -AutoSize
Write-Host 'By OU:' -ForegroundColor Cyan
$report | Group-Object OU | Sort-Object Count -Descending | Select-Object Count,Name | Format-Table -AutoSize
