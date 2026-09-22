#Requires -Version 5.1
<#
.SYNOPSIS  Bulk-create local or network (UNC) folders from a CSV file with optional NTFS permissions.
.NOTES
    CSV Columns: Path, Group (optional), Permission (Read|Modify|FullControl, optional)
    Usage   : .\08-Create-Folders-from-CSV.ps1 -CsvPath .\folders.csv
              .\08-Create-Folders-from-CSV.ps1 -CsvPath .\folders.csv -SetPermissions -WhatIf
#>
param(
    [Parameter(Mandatory)][string]$CsvPath,
    [switch]$SetPermissions,
    [switch]$WhatIf
)
$created = 0; $existed = 0; $failed = 0
foreach ($row in (Import-Csv -Path $CsvPath)) {
    $path  = $row.Path.Trim()
    $group = if ($row.Group)      { $row.Group.Trim()      } else { $null }
    $perm  = if ($row.Permission) { $row.Permission.Trim() } else { 'Modify' }

    if (Test-Path -Path $path -PathType Container) {
        Write-Host "[EXISTS] $path" -ForegroundColor DarkGray; $existed++
    } else {
        try {
            if (-not $WhatIf) { New-Item -ItemType Directory -Path $path -Force | Out-Null; Write-Host "[CREATED] $path" -ForegroundColor Green }
            else              { Write-Host "[WhatIf] Would create: $path" -ForegroundColor Cyan }
            $created++
        } catch { Write-Error "Failed '$path': $_"; $failed++; continue }
    }
    if ($SetPermissions -and $group -and -not $WhatIf) {
        try {
            $acl  = Get-Acl -Path $path
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $group,
                [System.Security.AccessControl.FileSystemRights]$perm,
                'ContainerInherit,ObjectInherit',
                'None',
                'Allow'
            )
            $acl.AddAccessRule($rule)
            Set-Acl -Path $path -AclObject $acl
            Write-Host "  Permissions set: '$perm' for '$group'" -ForegroundColor DarkGreen
        } catch { Write-Warning "  Permission failed on '$path': $_" }
    }
}
Write-Host "Created: $created | Existed: $existed | Failed: $failed" -ForegroundColor Cyan
