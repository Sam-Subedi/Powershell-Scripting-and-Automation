#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS  Disable the default built-in Administrator and create a new named local admin account.
.NOTES
    Security best practice: rename/disable the default -500 admin account and use a custom one.
    Usage   : .\23-Setup-Custom-Local-Admin-Account.ps1 -NewAdminUsername ITAdmin -DisableBuiltinAdmin
              .\23-Setup-Custom-Local-Admin-Account.ps1 -NewAdminUsername ITAdmin -DisableBuiltinAdmin -RenameBuiltinAdmin -WhatIf
#>
param(
    [Parameter(Mandatory)][string]$NewAdminUsername,
    [string]$NewAdminFullName    = 'IT Local Administrator',
    [string]$NewAdminDescription = 'Custom local admin - replaces built-in',
    [switch]$DisableBuiltinAdmin,
    [switch]$RenameBuiltinAdmin,
    [string]$BuiltinAdminNewName = 'BuiltinAdmin_Disabled',
    [switch]$WhatIf
)
Import-Module Microsoft.PowerShell.LocalAccounts -ErrorAction Stop

$builtin = Get-LocalUser | Where-Object { $_.SID.Value -match '-500$' }
if ($builtin) {
    Write-Host "Built-in admin: '$($builtin.Name)' (Enabled: $($builtin.Enabled))" -ForegroundColor Yellow
    if ($DisableBuiltinAdmin -and $builtin.Enabled) {
        Disable-LocalUser -Name $builtin.Name -WhatIf:$WhatIf
        if (-not $WhatIf) { Write-Host "Disabled '$($builtin.Name)'." -ForegroundColor Green }
    }
    if ($RenameBuiltinAdmin) {
        Rename-LocalUser -Name $builtin.Name -NewName $BuiltinAdminNewName -WhatIf:$WhatIf
        if (-not $WhatIf) { Write-Host "Renamed to '$BuiltinAdminNewName'." -ForegroundColor Green }
    }
}
if (Get-LocalUser -Name $NewAdminUsername -ErrorAction SilentlyContinue) {
    Write-Warning "User '$NewAdminUsername' already exists."
} else {
    $pwd = Read-Host "Password for '$NewAdminUsername'" -AsSecureString
    New-LocalUser -Name $NewAdminUsername -Password $pwd -FullName $NewAdminFullName `
        -Description $NewAdminDescription -PasswordNeverExpires $false -UserMayNotChangePassword $false -WhatIf:$WhatIf
    if (-not $WhatIf) {
        Add-LocalGroupMember -Group 'Administrators' -Member $NewAdminUsername
        Write-Host "Created '$NewAdminUsername' and added to Administrators." -ForegroundColor Green
    } else { Write-Host "[WhatIf] Would create '$NewAdminUsername' in Administrators." -ForegroundColor Cyan }
}
Write-Host '=== Current Administrators ===' -ForegroundColor Cyan
Get-LocalGroupMember -Group 'Administrators' | Format-Table Name, ObjectClass, PrincipalSource -AutoSize
