#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS  List all Domain Controllers and FSMO role holders in the AD domain and forest.
.NOTES
    FSMO roles: Schema Master, Domain Naming Master (forest-wide)
                PDC Emulator, RID Master, Infrastructure Master (domain-wide)
    Usage   : .\30-List-DCs-and-FSMO-Roles.ps1
              .\30-List-DCs-and-FSMO-Roles.ps1 -CheckReplication -OutputPath dcs.csv
#>
param(
    [string]$Domain = '',
    [switch]$CheckReplication,
    [string]$OutputPath = ''
)
Import-Module ActiveDirectory -ErrorAction Stop
$dom    = if ($Domain) { Get-ADDomain -Identity $Domain } else { Get-ADDomain }
$forest = Get-ADForest

Write-Host '=== Domain Information ===' -ForegroundColor Cyan
Write-Host "Domain      : $($dom.DNSRoot)"
Write-Host "Forest Root : $($forest.RootDomain)"
Write-Host "Domain Mode : $($dom.DomainMode)"
Write-Host "Forest Mode : $($forest.ForestMode)"

Write-Host "`n=== FSMO Roles ===" -ForegroundColor Yellow
[ordered]@{
    'Schema Master (Forest)'         = $forest.SchemaMaster
    'Domain Naming Master (Forest)'  = $forest.DomainNamingMaster
    'PDC Emulator (Domain)'          = $dom.PDCEmulator
    'RID Master (Domain)'            = $dom.RIDMaster
    'Infrastructure Master (Domain)' = $dom.InfrastructureMaster
}.GetEnumerator() | ForEach-Object { Write-Host "  $($_.Key.PadRight(38)): $($_.Value)" -ForegroundColor White }

$p = @{Filter='*'}; if ($Domain) { $p['Server']=$Domain }
$dcs = Get-ADDomainController @p

$dcReport = $dcs | ForEach-Object {
    $fsmo = @()
    if ($_.HostName -eq $forest.SchemaMaster)         { $fsmo += 'Schema Master' }
    if ($_.HostName -eq $forest.DomainNamingMaster)   { $fsmo += 'Domain Naming' }
    if ($_.HostName -eq $dom.PDCEmulator)             { $fsmo += 'PDC Emulator' }
    if ($_.HostName -eq $dom.RIDMaster)               { $fsmo += 'RID Master' }
    if ($_.HostName -eq $dom.InfrastructureMaster)    { $fsmo += 'Infrastructure' }
    [PSCustomObject]@{
        Name=$_.Name; HostName=$_.HostName; IPv4=$_.IPv4Address; Site=$_.Site
        IsGC=$_.IsGlobalCatalog; IsRODC=$_.IsReadOnly; OS=$_.OperatingSystem
        Online=(Test-Connection -ComputerName $_.HostName -Count 1 -Quiet -ErrorAction SilentlyContinue)
        FSMORoles=($fsmo -join ', ')
    }
}

Write-Host "`n=== Domain Controllers ($($dcReport.Count)) ===" -ForegroundColor Cyan
$dcReport | Format-Table Name,IPv4,Site,IsGC,IsRODC,Online,FSMORoles -AutoSize

if ($CheckReplication) {
    Write-Host "`n=== Replication Status ===" -ForegroundColor Cyan
    try {
        $repl = Get-ADReplicationPartnerMetadata -Target $dom.DNSRoot -Scope Domain
        $repl | Select-Object Server,Partner,LastReplicationSuccess,LastReplicationResult,FailureCount | Sort-Object Server | Format-Table -AutoSize
        $bad = $repl | Where-Object { $_.LastReplicationResult -ne 0 -or $_.FailureCount -gt 0 }
        if ($bad) { Write-Host "WARNING: $($bad.Count) replication issue(s)!" -ForegroundColor Red }
        else      { Write-Host 'All replication partnerships healthy.' -ForegroundColor Green }
    } catch { Write-Warning "Could not retrieve replication data: $_" }
}
if ($OutputPath) { $dcReport | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8; Write-Host "Exported: $OutputPath" -ForegroundColor Green }
