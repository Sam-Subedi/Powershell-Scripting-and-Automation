#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS  Create, enable, disable, delete, list, or change passwords for local Windows users.
.NOTES
    Actions : Create | Enable | Disable | Delete | List | SetPassword | CheckPrivileges
    Usage   : .\11-Manage-Local-Windows-Users.ps1 -Action List
              .\11-Manage-Local-Windows-Users.ps1 -Action Create -Username ITAdmin -GroupName Administrators
              .\11-Manage-Local-Windows-Users.ps1 -Action Disable -Username jdoe
#>
param(
    [ValidateSet('Create','Enable','Disable','Delete','List','SetPassword','CheckPrivileges')]
    [string]$Action   = 'List',
    [string]$Username,
    [string]$FullName,
    [string]$Description,
    [string]$GroupName  = 'Administrators',
    [string]$PasswordFile,
    [switch]$WhatIf
)
Import-Module Microsoft.PowerShell.LocalAccounts -ErrorAction Stop

function Get-SecurePwd ([string]$File) {
    if ($File -and (Test-Path $File)) { return ConvertTo-SecureString (Get-Content $File) }
    return (Read-Host "Enter password for '$Username'" -AsSecureString)
}
function Test-IsAdmin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

switch ($Action) {
    'List' {
        Write-Host '=== Local Users ===' -ForegroundColor Cyan
        Get-LocalUser | Select-Object Name, FullName, Enabled, LastLogon, PasswordLastSet | Format-Table -AutoSize
        Write-Host '=== Administrators ===' -ForegroundColor Cyan
        Get-LocalGroupMember -Group 'Administrators' | Format-Table Name, ObjectClass, PrincipalSource -AutoSize
    }
    'Create' {
        if (-not $Username) { throw '-Username is required.' }
        $p = @{ Name=$Username; Password=(Get-SecurePwd $PasswordFile); PasswordNeverExpires=$false; Disabled=$false }
        if ($FullName)    { $p['FullName']    = $FullName }
        if ($Description) { $p['Description'] = $Description }
        New-LocalUser @p -WhatIf:$WhatIf
        if (-not $WhatIf) { Add-LocalGroupMember -Group $GroupName -Member $Username; Write-Host "Created '$Username' in '$GroupName'." -ForegroundColor Green }
    }
    'Enable'      { if (-not $Username) { throw '-Username required.' }; Enable-LocalUser  -Name $Username -WhatIf:$WhatIf; Write-Host "Enabled '$Username'."  -ForegroundColor Green }
    'Disable'     { if (-not $Username) { throw '-Username required.' }; Disable-LocalUser -Name $Username -WhatIf:$WhatIf; Write-Host "Disabled '$Username'." -ForegroundColor Yellow }
    'Delete'      { if (-not $Username) { throw '-Username required.' }
                    if ((Read-Host "Delete '$Username'? (yes/no)") -eq 'yes') { Remove-LocalUser -Name $Username -WhatIf:$WhatIf; Write-Host "Deleted." -ForegroundColor Red } }
    'SetPassword' { if (-not $Username) { throw '-Username required.' }; Set-LocalUser -Name $Username -Password (Get-SecurePwd $PasswordFile) -WhatIf:$WhatIf; Write-Host "Password updated." -ForegroundColor Green }
    'CheckPrivileges' { $a = Test-IsAdmin; Write-Host "Running as Administrator: $a" -ForegroundColor $(if($a){'Green'}else{'Red'}) }
}
