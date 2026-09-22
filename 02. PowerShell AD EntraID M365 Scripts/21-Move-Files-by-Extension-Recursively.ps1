#Requires -Version 5.1
<#
.SYNOPSIS  Find all files with given extensions recursively and move them to a single target folder.
.NOTES
    ConflictAction: Rename (default), Skip, or Overwrite
    Usage   : .\21-Move-Files-by-Extension-Recursively.ps1 -SourcePath C:\Scans -DestinationPath C:\AllPDFs -Extensions .pdf
              .\21-Move-Files-by-Extension-Recursively.ps1 -SourcePath D:\Work -DestinationPath D:\Archive -Extensions .pdf,.docx -ConflictAction Rename -WhatIf
#>
param(
    [Parameter(Mandatory)][string]$SourcePath,
    [Parameter(Mandatory)][string]$DestinationPath,
    [Parameter(Mandatory)][string[]]$Extensions,
    [ValidateSet('Rename','Skip','Overwrite')][string]$ConflictAction = 'Rename',
    [switch]$DeleteEmptySourceFolders,
    [switch]$WhatIf
)
if (-not (Test-Path $SourcePath)) { Write-Error "Source not found: $SourcePath"; exit 1 }
if (-not (Test-Path $DestinationPath) -and -not $WhatIf) { New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null }

$exts  = $Extensions | ForEach-Object { if ($_.StartsWith('.')) { $_.ToLower() } else { ".$($_.ToLower())" } }
$files = Get-ChildItem -Path $SourcePath -Recurse -File |
         Where-Object { $exts -contains $_.Extension.ToLower() -and $_.DirectoryName -ne $DestinationPath }

Write-Host "Found $($files.Count) file(s) matching: $($exts -join ', ')" -ForegroundColor Cyan
$moved = 0; $skipped = 0; $renamed = 0; $failed = 0; $i = 0

foreach ($f in $files) {
    $i++
    $dest = Join-Path $DestinationPath $f.Name
    if (Test-Path $dest) {
        switch ($ConflictAction) {
            'Skip'      { Write-Host "[$i] SKIP: $($f.Name)" -ForegroundColor Yellow; $skipped++; continue }
            'Overwrite' {}
            'Rename'    {
                $base = [IO.Path]::GetFileNameWithoutExtension($f.Name); $ext = $f.Extension; $n = 1
                do { $dest = Join-Path $DestinationPath "${base}_$n$ext"; $n++ } while (Test-Path $dest)
                $renamed++
            }
        }
    }
    if ($WhatIf) { Write-Host "[$i] [WhatIf] $($f.FullName)" -ForegroundColor Cyan; $moved++; continue }
    try { Move-Item -Path $f.FullName -Destination $dest -Force; Write-Host "[$i] Moved: $($f.Name)" -ForegroundColor Green; $moved++ }
    catch { Write-Error "[$i] Failed '$($f.Name)': $_"; $failed++ }
}
if ($DeleteEmptySourceFolders -and -not $WhatIf) {
    Get-ChildItem -Path $SourcePath -Recurse -Directory | Sort-Object FullName -Descending |
        Where-Object { (Get-ChildItem $_.FullName -Recurse -File).Count -eq 0 -and $_.FullName -ne $SourcePath } |
        Remove-Item -Force
}
Write-Host "Moved: $moved | Renamed: $renamed | Skipped: $skipped | Failed: $failed" -ForegroundColor Cyan
