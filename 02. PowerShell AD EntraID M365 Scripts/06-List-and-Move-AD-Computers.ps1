#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS  List AD computers and optionally move them to a new OU (single or bulk via CSV).
.NOTES
    CSV Columns: ComputerName, TargetOU
    Usage   : .\06-List-and-Move-AD-Computers.ps1 -GetOnly
              .\06-List-and-Move-AD-Computers.ps1 -CsvPath .\computers.csv -WhatIf
              .\06-List-and-Move-AD-Computers.ps1 -ComputerName PC01 -TargetOU 'OU=Retired,DC=domain,DC=com'
#>
param(
    [string]$CsvPath,
    [string]$ComputerName,
    [string]$TargetOU,
    [string]$SourceOU,
    [switch]$GetOnly,
    [switch]$WhatIf
)
Import-Module ActiveDirectory -ErrorAction Stop

if ($GetOnly) {
    $p = @{ Filter = { Enabled -eq $true }; Properties = @('Name','LastLogonDate','OperatingSystem','IPv4Address','DistinguishedName') }
    if ($SourceOU) { $p['SearchBase'] = $SourceOU }
    $comps = Get-ADComputer @p
    $comps | Select-Object Name, OperatingSystem, IPv4Address, LastLogonDate,
        @{N='OU'; E={$_.DistinguishedName -replace '^CN=[^,]+,',''}} |
        Sort-Object Name | Format-Table -AutoSize
    $out = ".\ADComputers_$(Get-Date -Format 'yyyyMMdd').csv"
    $comps | Select-Object Name, OperatingSystem, IPv4Address, LastLogonDate, DistinguishedName |
        Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
    Write-Host "Exported $($comps.Count) computers to $out" -ForegroundColor Green
    return
}

function Move-ADComp ([string]$Name,[string]$OUPath) {
    $c = Get-ADComputer -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue
    if (-not $c) { Write-Warning "Computer '$Name' not found."; return }
    Write-Host "Moving '$Name' -> '$OUPath'" -ForegroundColor Cyan
    try { Move-ADObject -Identity $c.DistinguishedName -TargetPath $OUPath -WhatIf:$WhatIf; Write-Host "  Done." -ForegroundColor Green }
    catch { Write-Error "  Failed: $_" }
}

if ($CsvPath)                     { Import-Csv $CsvPath | ForEach-Object { Move-ADComp $_.ComputerName.Trim() $_.TargetOU.Trim() } }
elseif ($ComputerName -and $TargetOU) { Move-ADComp $ComputerName $TargetOU }
else { Write-Host 'Use -GetOnly, -CsvPath, or -ComputerName + -TargetOU' -ForegroundColor Yellow }
