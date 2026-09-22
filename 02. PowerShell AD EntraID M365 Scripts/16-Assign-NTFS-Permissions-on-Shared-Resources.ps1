#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS  Assign NTFS permissions to AD users/groups on folders. Optionally create SMB shares.
.NOTES
    Install NTFSSecurity module for best results: Install-Module NTFSSecurity -Scope CurrentUser
    Falls back to built-in Set-Acl if NTFSSecurity is not available.
    CSV Columns: Path, ADObject, Permission (Read|Modify|FullControl), Action (Add|Remove), ShareName (optional)
    Usage   : .\16-Assign-NTFS-Permissions-on-Shared-Resources.ps1 -CsvPath permissions.csv
#>
param(
    [Parameter(Mandatory)][string]$CsvPath,
    [switch]$CreateShares,
    [switch]$WhatIf
)
$hasNTFS = $null -ne (Get-Module -ListAvailable -Name NTFSSecurity)
if ($hasNTFS) { Import-Module NTFSSecurity; Write-Host 'NTFSSecurity loaded.' -ForegroundColor Green }
else { Write-Warning 'NTFSSecurity not found; using Set-Acl. Install: Install-Module NTFSSecurity' }

foreach ($row in (Import-Csv -Path $CsvPath)) {
    $path   = $row.Path.Trim()
    $obj    = $row.ADObject.Trim()
    $perm   = $row.Permission.Trim()
    $action = if ($row.Action) { $row.Action.Trim() } else { 'Add' }
    $share  = if ($row.ShareName) { $row.ShareName.Trim() } else { $null }

    if (-not (Test-Path $path)) {
        if (-not $WhatIf) { New-Item -ItemType Directory -Path $path -Force | Out-Null; Write-Host "Created: $path" -ForegroundColor DarkGreen }
    }
    Write-Host "$action '$perm' for '$obj' on '$path'" -ForegroundColor Cyan
    if ($WhatIf) { Write-Host '  [WhatIf] Skipped.' -ForegroundColor Yellow }
    elseif ($hasNTFS) {
        try {
            if ($action -eq 'Remove') { Remove-NTFSAccess -Path $path -Account $obj -AccessRights $perm }
            else                      { Add-NTFSAccess    -Path $path -Account $obj -AccessRights $perm -AppliesTo ThisFolderSubfoldersAndFiles }
            Write-Host '  Done (NTFSSecurity).' -ForegroundColor Green
        } catch { Write-Error "  Failed: $_" }
    } else {
        $rMap = @{'Read'='Read';'List'='ListDirectory';'Modify'='Modify';'FullControl'='FullControl'}
        try {
            $acl  = Get-Acl -Path $path
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($obj,$rMap[$perm],'ContainerInherit,ObjectInherit','None','Allow')
            if ($action -eq 'Remove') { $acl.RemoveAccessRule($rule) | Out-Null } else { $acl.AddAccessRule($rule) }
            Set-Acl -Path $path -AclObject $acl
            Write-Host '  Done (Set-Acl).' -ForegroundColor Green
        } catch { Write-Error "  Failed: $_" }
    }
    if ($CreateShares -and $share -and -not $WhatIf) {
        if (-not (Get-SmbShare -Name $share -ErrorAction SilentlyContinue)) {
            New-SmbShare -Name $share -Path $path -FullAccess 'Administrators' -ChangeAccess $obj
            Write-Host "  SMB share '$share' created." -ForegroundColor Green
        } else { Write-Host "  Share '$share' already exists." -ForegroundColor Yellow }
    }
}
