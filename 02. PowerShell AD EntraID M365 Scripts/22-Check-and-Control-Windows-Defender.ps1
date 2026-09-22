#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS  Check Windows Defender status, update definitions, manage exclusions, or disable for testing.
.NOTES
    Actions : Status | Enable | Disable | UpdateDefinitions | AddExclusion | RemoveExclusion
    WARNING : Only disable Defender in ISOLATED test environments.
    Usage   : .\22-Check-and-Control-Windows-Defender.ps1 -Action Status
              .\22-Check-and-Control-Windows-Defender.ps1 -Action AddExclusion -ExclusionPath C:\TestTools
              .\22-Check-and-Control-Windows-Defender.ps1 -Action Disable -Force
#>
param(
    [ValidateSet('Status','Enable','Disable','UpdateDefinitions','AddExclusion','RemoveExclusion')]
    [string]$Action = 'Status',
    [string]$ExclusionPath,
    [string]$ExclusionProcess,
    [string]$ExclusionExtension,
    [switch]$Force
)
Import-Module Defender -ErrorAction Stop

switch ($Action) {
    'Status' {
        $s = Get-MpComputerStatus
        Write-Host '=== Windows Defender Status ===' -ForegroundColor Cyan
        [ordered]@{
            'Antivirus Enabled'       = $s.AntivirusEnabled
            'Real-Time Protection'    = $s.RealTimeProtectionEnabled
            'Behavior Monitor'        = $s.BehaviorMonitorEnabled
            'Tamper Protection'       = $s.IsTamperProtected
            'Signature Version'       = $s.AntivirusSignatureVersion
            'Signatures Last Updated' = $s.AntivirusSignatureLastUpdated
            'Quick Scan Last Run'     = $s.QuickScanEndTime
            'Engine Version'          = $s.AMEngineVersion
        }.GetEnumerator() | ForEach-Object {
            $c = if ($_.Value -is [bool]) { if ($_.Value){'Green'}else{'Red'} } else {'White'}
            Write-Host "  $($_.Key.PadRight(30)): " -NoNewline; Write-Host $_.Value -ForegroundColor $c
        }
        $p = Get-MpPreference
        Write-Host "Exclusion Paths     : $($p.ExclusionPath -join ', ')"
        Write-Host "Exclusion Extensions: $($p.ExclusionExtension -join ', ')"
        $threats = Get-MpThreatDetection -ErrorAction SilentlyContinue
        if ($threats) { Write-Host "$($threats.Count) active threat(s)!" -ForegroundColor Red }
        else          { Write-Host 'No active threats.' -ForegroundColor Green }
    }
    'Enable'  { Set-MpPreference -DisableRealtimeMonitoring $false -DisableBehaviorMonitoring $false -DisableIOAVProtection $false -DisableScriptScanning $false; Write-Host 'Defender enabled.' -ForegroundColor Green }
    'Disable' {
        if (-not $Force) { Write-Warning 'Add -Force to confirm. Only use in ISOLATED test environments.'; exit 1 }
        Set-MpPreference -DisableRealtimeMonitoring $true -DisableBehaviorMonitoring $true -DisableIOAVProtection $true -DisableScriptScanning $true
        Write-Host 'Defender disabled.' -ForegroundColor Yellow
    }
    'UpdateDefinitions' { Update-MpSignature; Write-Host 'Definitions updated.' -ForegroundColor Green }
    'AddExclusion' {
        if ($ExclusionPath)      { Add-MpPreference -ExclusionPath      $ExclusionPath;      Write-Host "Added path exclusion: $ExclusionPath" -ForegroundColor Yellow }
        if ($ExclusionProcess)   { Add-MpPreference -ExclusionProcess   $ExclusionProcess;   Write-Host "Added process exclusion: $ExclusionProcess" -ForegroundColor Yellow }
        if ($ExclusionExtension) { Add-MpPreference -ExclusionExtension $ExclusionExtension; Write-Host "Added extension exclusion: $ExclusionExtension" -ForegroundColor Yellow }
    }
    'RemoveExclusion' {
        if ($ExclusionPath)      { Remove-MpPreference -ExclusionPath      $ExclusionPath }
        if ($ExclusionProcess)   { Remove-MpPreference -ExclusionProcess   $ExclusionProcess }
        if ($ExclusionExtension) { Remove-MpPreference -ExclusionExtension $ExclusionExtension }
        Write-Host 'Exclusion(s) removed.' -ForegroundColor Green
    }
}
