#Requires -Version 5.1
#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS  Add or remove Exchange Online mailbox permissions from CSV.
.NOTES
    Install : Install-Module ExchangeOnlineManagement -Scope CurrentUser
    CSV Columns: UserPrincipalName, SharedMailbox, Permission (FullAccess|SendAs|SendOnBehalf)
    Usage   : .\02-Manage-ExchangeOnline-Mailbox-Permissions.ps1 -CsvPath .\perms.csv
              .\02-Manage-ExchangeOnline-Mailbox-Permissions.ps1 -CsvPath .\perms.csv -Remove
#>
param(
    [Parameter(Mandatory)][string]$CsvPath,
    [string]$AdminUPN,
    [switch]$Remove
)
$p = @{ ShowBanner = $false }
if ($AdminUPN) { $p['UserPrincipalName'] = $AdminUPN }
Connect-ExchangeOnline @p

foreach ($row in (Import-Csv -Path $CsvPath)) {
    $mbx  = $row.SharedMailbox.Trim()
    $user = $row.UserPrincipalName.Trim()
    $perm = $row.Permission.Trim().ToLower()
    Write-Host "$(if($Remove){'Removing'}else{'Adding'}) [$perm] $user on $mbx" -ForegroundColor Cyan
    try {
        switch ($perm) {
            'fullaccess' {
                if ($Remove) { Remove-MailboxPermission -Identity $mbx -User $user -AccessRights FullAccess -Confirm:$false }
                else         { Add-MailboxPermission    -Identity $mbx -User $user -AccessRights FullAccess -AutoMapping $true -Confirm:$false | Out-Null }
            }
            'sendas' {
                if ($Remove) { Remove-RecipientPermission -Identity $mbx -Trustee $user -AccessRights SendAs -Confirm:$false }
                else         { Add-RecipientPermission    -Identity $mbx -Trustee $user -AccessRights SendAs -Confirm:$false | Out-Null }
            }
            'sendonbehalf' {
                $box     = Get-Mailbox -Identity $mbx
                $updated = if ($Remove) { $box.GrantSendOnBehalfTo | Where-Object { $_ -ne $user } }
                           else         { $box.GrantSendOnBehalfTo + $user }
                Set-Mailbox -Identity $mbx -GrantSendOnBehalfTo $updated
            }
            default { Write-Warning "Unknown permission '$perm'. Use FullAccess, SendAs, or SendOnBehalf." }
        }
        Write-Host "  Done." -ForegroundColor Green
    } catch { Write-Error "  Failed: $_" }
}
Disconnect-ExchangeOnline -Confirm:$false
