#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS  Add a user to an AD group temporarily — auto-removed after N minutes via Scheduled Task.
.NOTES
    For Entra ID / cloud: use Microsoft Entra Privileged Identity Management (PIM) instead.
    Usage   : .\29-Grant-Temporary-AD-Group-Membership.ps1 -UserName jdoe -GroupName ServerAdmins -DurationMinutes 60 -Reason 'Emergency patch'
              .\29-Grant-Temporary-AD-Group-Membership.ps1 -UserName jdoe -GroupName VPN_Access -DurationMinutes 480 -WhatIf
#>
param(
    [Parameter(Mandatory)][string]$UserName,
    [Parameter(Mandatory)][string]$GroupName,
    [Parameter(Mandatory)][int]$DurationMinutes,
    [string]$Reason = 'Temporary access',
    [switch]$WhatIf
)
Import-Module ActiveDirectory -ErrorAction Stop
$user  = Get-ADUser  -Filter "SamAccountName -eq '$UserName'"  -ErrorAction SilentlyContinue
$group = Get-ADGroup -Filter "Name -eq '$GroupName'" -ErrorAction SilentlyContinue
if (-not $user)  { Write-Error "User '$UserName' not found.";  exit 1 }
if (-not $group) { Write-Error "Group '$GroupName' not found."; exit 1 }
$expiry = (Get-Date).AddMinutes($DurationMinutes)

Write-Host "User: $UserName | Group: $GroupName | Expires: $($expiry.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
Write-Host "Reason: $Reason"

$isMember = (Get-ADGroupMember -Identity $GroupName -Recursive | Where-Object { $_.SamAccountName -eq $UserName }).Count -gt 0
if ($isMember) { Write-Warning "'$UserName' is already a member of '$GroupName'." }
else {
    Add-ADGroupMember -Identity $GroupName -Members $UserName -WhatIf:$WhatIf -Confirm:$false
    if (-not $WhatIf) { Write-Host "Added '$UserName' to '$GroupName'." -ForegroundColor Green }
}
if (-not $WhatIf) {
    $taskName = "TempAccess_${UserName}_${GroupName}_$(Get-Date -Format 'HHmmss')"
    $cmd = "Import-Module ActiveDirectory; Remove-ADGroupMember -Identity '$GroupName' -Members '$UserName' -Confirm:`$false; Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false"
    $action   = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NonInteractive -NoProfile -Command `"$cmd`""
    $trigger  = New-ScheduledTaskTrigger -Once -At $expiry
    $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 5) -StartWhenAvailable $true
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Description "Auto-remove $UserName from $GroupName. Reason: $Reason" -Force | Out-Null
    Write-Host "Scheduled auto-removal at $($expiry.ToString('HH:mm:ss'))." -ForegroundColor Green
    Write-Host "To cancel early: Remove-ADGroupMember -Identity '$GroupName' -Members '$UserName' -Confirm:`$false" -ForegroundColor Yellow
    Write-Host "                 Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false" -ForegroundColor Yellow
}
