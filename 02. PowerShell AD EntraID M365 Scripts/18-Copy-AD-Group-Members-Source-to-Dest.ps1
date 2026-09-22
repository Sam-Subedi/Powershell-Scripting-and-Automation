#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS  Copy all members from one AD group into another AD group.
.NOTES
    Both groups must already exist. Existing destination members are preserved.
    Usage   : .\18-Copy-AD-Group-Members-Source-to-Dest.ps1 -SourceGroup OldTeam -DestinationGroup NewTeam
              .\18-Copy-AD-Group-Members-Source-to-Dest.ps1 -SourceGroup OldTeam -DestinationGroup NewTeam -Recursive -WhatIf
#>
param(
    [Parameter(Mandatory)][string]$SourceGroup,
    [Parameter(Mandatory)][string]$DestinationGroup,
    [switch]$Recursive,
    [switch]$WhatIf
)
Import-Module ActiveDirectory -ErrorAction Stop
$src  = Get-ADGroup -Filter "Name -eq '$SourceGroup'"      -ErrorAction SilentlyContinue
$dest = Get-ADGroup -Filter "Name -eq '$DestinationGroup'" -ErrorAction SilentlyContinue
if (-not $src)  { Write-Error "Source group '$SourceGroup' not found.";      exit 1 }
if (-not $dest) { Write-Error "Destination group '$DestinationGroup' not found."; exit 1 }

$srcMembers  = if ($Recursive) { Get-ADGroupMember -Identity $SourceGroup -Recursive } else { Get-ADGroupMember -Identity $SourceGroup }
$destDNs     = (Get-ADGroupMember -Identity $DestinationGroup).DistinguishedName
Write-Host "Source: $($srcMembers.Count) members  |  Destination: $($destDNs.Count) current members" -ForegroundColor Cyan

$added = 0; $skipped = 0; $failed = 0
foreach ($m in $srcMembers) {
    if ($destDNs -contains $m.DistinguishedName) { Write-Host "  [SKIP] $($m.SamAccountName)" -ForegroundColor DarkGray; $skipped++; continue }
    try {
        Add-ADGroupMember -Identity $DestinationGroup -Members $m -WhatIf:$WhatIf -Confirm:$false
        Write-Host "  [$(if($WhatIf){'WhatIf'}else{'ADDED'})] $($m.SamAccountName) ($($m.objectClass))" -ForegroundColor Green; $added++
    } catch { Write-Warning "  [FAIL] $($m.SamAccountName): $_"; $failed++ }
}
Write-Host "Added: $added | Skipped: $skipped | Failed: $failed" -ForegroundColor Cyan
