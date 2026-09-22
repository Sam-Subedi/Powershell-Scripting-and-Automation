#Requires -Version 5.1
<#
.SYNOPSIS  Copy a user's profile folders to a new computer using Robocopy.
.NOTES
    Robocopy is built into Windows — no install needed.
    Source and Destination can be local paths or UNC paths (\\Server\C$\Users\username).
    Usage   : .\12-Migrate-User-Profile-with-Robocopy.ps1 -SourceUser '\\OldPC\c$\Users\jdoe' -DestUser '\\NewPC\c$\Users\jdoe'
              .\12-Migrate-User-Profile-with-Robocopy.ps1 -SourceUser 'C:\Users\jdoe' -DestUser 'D:\Users\jdoe' -IncludeAll
#>
param(
    [Parameter(Mandatory)][string]$SourceUser,
    [Parameter(Mandatory)][string]$DestUser,
    [string]$LogPath  = ".\MigrateProfile_$(Get-Date -Format 'yyyyMMdd_HHmm').log",
    [switch]$IncludeAll,
    [switch]$WhatIf
)
if (-not (Test-Path $SourceUser)) { Write-Error "Source not found: $SourceUser"; exit 1 }
$essential = @('Desktop','Documents','Downloads','Pictures','Videos','Music','Favorites',
    'AppData\Roaming\Microsoft\Signatures','AppData\Roaming\Microsoft\Templates',
    'AppData\Roaming\Mozilla\Firefox\Profiles')
$all       = @('Desktop','Documents','Downloads','Pictures','Videos','Music','Favorites',
    'Links','Searches','Contacts','AppData\Roaming')
$folders   = if ($IncludeAll) { $all } else { $essential }

Write-Host "Migrating: $SourceUser -> $DestUser" -ForegroundColor Cyan
$ok = 0; $fail = 0

foreach ($f in $folders) {
    $src  = Join-Path $SourceUser $f
    $dest = Join-Path $DestUser   $f
    if (-not (Test-Path $src)) { Write-Host "  [SKIP] $f" -ForegroundColor DarkGray; continue }
    if (-not $WhatIf) { New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null }
    $args = @($src, $dest, '/E', '/COPYALL', '/R:3', '/W:5', '/MT:8',
              '/XF', 'desktop.ini', '*.tmp', '/LOG+:{0}' -f $LogPath, '/TEE')
    if ($WhatIf) { $args += '/L' }
    & robocopy @args | Out-Null
    if ($LASTEXITCODE -lt 8) { Write-Host "  [OK] $f" -ForegroundColor Green; $ok++ }
    else                     { Write-Host "  [ERR] $f (exit $LASTEXITCODE)" -ForegroundColor Red; $fail++ }
}
Write-Host "Done. Success: $ok | Failed: $fail | Log: $LogPath" -ForegroundColor Cyan
if ($WhatIf) { Write-Host '(WhatIf mode — no files copied)' -ForegroundColor Yellow }
