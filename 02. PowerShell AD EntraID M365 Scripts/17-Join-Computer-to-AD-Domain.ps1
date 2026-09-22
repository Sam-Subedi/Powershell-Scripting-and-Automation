#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS  Rename a computer and join it to an Active Directory domain.
.NOTES
    Usage   : .\17-Join-Computer-to-AD-Domain.ps1 -DomainName contoso.com -DomainCredential (Get-Credential)
              .\17-Join-Computer-to-AD-Domain.ps1 -DomainName contoso.com -NewComputerName WS-JOHN01 -OUPath 'OU=Workstations,DC=contoso,DC=com' -DomainCredential (Get-Credential) -Restart
#>
param(
    [Parameter(Mandatory)][string]$DomainName,
    [Parameter(Mandatory)][System.Management.Automation.PSCredential]$DomainCredential,
    [string]$NewComputerName,
    [string]$OUPath,
    [switch]$Restart,
    [switch]$WhatIf
)
Write-Host "Current : $env:COMPUTERNAME  ->  Domain: $DomainName" -ForegroundColor Cyan
if ($OUPath) { Write-Host "Target OU: $OUPath" }

if ($NewComputerName -and $NewComputerName -ne $env:COMPUTERNAME) {
    if ($NewComputerName.Length -gt 15) { $NewComputerName = $NewComputerName.Substring(0,15); Write-Warning 'Name truncated to 15 chars (NetBIOS limit).' }
    if (-not $WhatIf) { Rename-Computer -NewName $NewComputerName -Force; Write-Host "Renamed to '$NewComputerName'." -ForegroundColor Green }
    else              { Write-Host "[WhatIf] Would rename to '$NewComputerName'" -ForegroundColor Cyan }
}
$p = @{ DomainName=$DomainName; Credential=$DomainCredential; Force=$true; WhatIf=$WhatIf; ErrorAction='Stop' }
if ($OUPath)  { $p['OUPath']  = $OUPath }
if ($Restart) { $p['Restart'] = $true }
try {
    Add-Computer @p
    if ($WhatIf) { Write-Host "[WhatIf] Would join '$DomainName'" -ForegroundColor Cyan }
    else {
        Write-Host "Joined '$DomainName' successfully." -ForegroundColor Green
        if (-not $Restart) { if ((Read-Host 'Restart now? (yes/no)') -eq 'yes') { Restart-Computer -Force } }
    }
} catch { Write-Error "Domain join failed: $_"; exit 1 }
