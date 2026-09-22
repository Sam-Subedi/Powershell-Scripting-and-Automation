#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS  Diagnose and repair 'Trust relationship between workstation and domain failed' errors.
.NOTES
    Run as LOCAL administrator on the affected workstation.
    Usage   : .\31-Fix-Domain-Trust-Relationship.ps1 -DomainCredential (Get-Credential DOMAIN\Admin) -DiagnoseOnly
              .\31-Fix-Domain-Trust-Relationship.ps1 -DomainCredential (Get-Credential DOMAIN\Admin) -ForceRepair
#>
param(
    [Parameter(Mandatory)][System.Management.Automation.PSCredential]$DomainCredential,
    [string]$DomainName = '',
    [string]$DCName     = '',
    [switch]$DiagnoseOnly,
    [switch]$ForceRepair
)
$domain = if ($DomainName) { $DomainName } else { (Get-CimInstance -ClassName Win32_ComputerSystem).Domain }
Write-Host "=== Domain Trust Troubleshooter ===" -ForegroundColor Cyan
Write-Host "Computer : $env:COMPUTERNAME  |  Domain: $domain"

Write-Host "`n[1] Diagnosing..." -ForegroundColor Yellow
$channel = Test-ComputerSecureChannel -ErrorAction SilentlyContinue
Write-Host "Secure Channel : $(if($channel){'OK'}else{'BROKEN'})" -ForegroundColor $(if($channel){'Green'}else{'Red'})

try {
    Import-Module ActiveDirectory -ErrorAction Stop
    $ca = Get-ADComputer -Filter "Name -eq '$env:COMPUTERNAME'" -ErrorAction Stop
    Write-Host "AD Account     : FOUND (Enabled: $($ca.Enabled))" -ForegroundColor Green
} catch { Write-Warning "Could not verify AD account: $_" }

$netlogon = Get-Service -Name Netlogon -ErrorAction SilentlyContinue
Write-Host "Netlogon       : $($netlogon.Status)" -ForegroundColor $(if($netlogon.Status -eq 'Running'){'Green'}else{'Red'})

$dcTarget = if ($DCName) { $DCName } else { $domain }
$ping = Test-Connection -ComputerName $dcTarget -Count 1 -Quiet -ErrorAction SilentlyContinue
Write-Host "DC Reachable   : $ping" -ForegroundColor $(if($ping){'Green'}else{'Red'})

if ($DiagnoseOnly) { Write-Host "`nDiagnosis complete. Use -ForceRepair to attempt repair." -ForegroundColor Cyan; exit 0 }
if ($channel -and -not $ForceRepair) { Write-Host "`nSecure channel is healthy. Use -ForceRepair to reset anyway." -ForegroundColor Yellow; exit 0 }

Write-Host "`n[2] Attempting repair..." -ForegroundColor Yellow
try {
    $rP = @{Credential=$DomainCredential;ErrorAction='Stop'}
    if ($DCName) { $rP['Server']=$DCName }
    Reset-ComputerMachinePassword @rP
    Write-Host "Machine password reset successfully." -ForegroundColor Green
} catch {
    Write-Warning "Reset-ComputerMachinePassword failed: $_"
    try {
        $repaired = Test-ComputerSecureChannel -Repair -Credential $DomainCredential -ErrorAction Stop
        Write-Host "Test-ComputerSecureChannel -Repair result: $repaired" -ForegroundColor $(if($repaired){'Green'}else{'Red'})
    } catch {
        Write-Error "Both repair methods failed: $_"
        Write-Host @'

MANUAL STEPS:
1. Log in with a local administrator account (not domain)
2. Run: Reset-ComputerMachinePassword -Credential (Get-Credential DOMAIN\Admin)
   OR in ADUC: find the computer > right-click > Reset Account
3. If still failing, rejoin the domain:
   Remove-Computer -Credential (Get-Credential) -WorkgroupName WORKGROUP -Force -Restart
   Add-Computer -DomainName YOURDOMAIN -Credential (Get-Credential) -Restart -Force
'@ -ForegroundColor Yellow
        exit 1
    }
}
Write-Host "`n[3] Verifying..." -ForegroundColor Yellow
$verify = Test-ComputerSecureChannel -ErrorAction SilentlyContinue
Write-Host "Secure Channel after repair: $(if($verify){'OK - FIXED'}else{'STILL BROKEN - restart may be needed'})" -ForegroundColor $(if($verify){'Green'}else{'Red'})
