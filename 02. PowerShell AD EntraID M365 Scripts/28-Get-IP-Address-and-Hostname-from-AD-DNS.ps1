#Requires -Version 5.1
#Requires -Modules ActiveDirectory, DnsServer
<#
.SYNOPSIS  Get IP-to-hostname mappings from AD and/or DNS. Use -CrossReference to find mismatches.
.NOTES
    Usage   : .\28-Get-IP-Address-and-Hostname-from-AD-DNS.ps1 -Source AD
              .\28-Get-IP-Address-and-Hostname-from-AD-DNS.ps1 -Source Both -DnsServer DC01 -ZoneName contoso.com -CrossReference
#>
param(
    [ValidateSet('AD','DNS','Both')][string]$Source = 'Both',
    [string]$DnsServer,
    [string]$ZoneName,
    [string]$SearchBase = '',
    [string]$OutputPath = ".\IP-Hostname_$(Get-Date -Format 'yyyyMMdd').csv",
    [switch]$CrossReference,
    [switch]$EnabledOnly
)
Import-Module ActiveDirectory -ErrorAction Stop
if ($Source -in @('DNS','Both')) { Import-Module DnsServer -ErrorAction Stop }

$adList  = [System.Collections.Generic.List[PSCustomObject]]::new()
$dnsList = [System.Collections.Generic.List[PSCustomObject]]::new()

if ($Source -in @('AD','Both')) {
    Write-Host 'Querying Active Directory...' -ForegroundColor Cyan
    $p = @{Filter=if($EnabledOnly){{Enabled -eq $true}}else{{Name -like '*'}};Properties=@('Name','DNSHostName','IPv4Address','OperatingSystem','LastLogonDate','Enabled','DistinguishedName')}
    if ($SearchBase) { $p['SearchBase']=$SearchBase }
    Get-ADComputer @p | ForEach-Object {
        $adList.Add([PSCustomObject]@{Source='AD';ComputerName=$_.Name;DNSHostName=$_.DNSHostName;IPv4Address=$_.IPv4Address;OperatingSystem=$_.OperatingSystem;LastLogonDate=$_.LastLogonDate;Enabled=$_.Enabled;OU=($_.DistinguishedName -replace '^CN=[^,]+,','')})
    }
    Write-Host "  AD computers: $($adList.Count)" -ForegroundColor Green
}
if ($Source -in @('DNS','Both')) {
    if (-not $DnsServer) { $DnsServer=(Get-ADDomainController).HostName }
    if (-not $ZoneName)  { $ZoneName=(Get-ADDomain).DNSRoot }
    Write-Host "Querying DNS $DnsServer zone $ZoneName..." -ForegroundColor Cyan
    Get-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $ZoneName -RRType A | ForEach-Object {
        $dnsList.Add([PSCustomObject]@{Source='DNS';ComputerName=$_.HostName;DNSHostName="$($_.HostName).$ZoneName";IPv4Address=$_.RecordData.IPv4Address.ToString();TTL=$_.TimeToLive})
    }
    Write-Host "  DNS A records: $($dnsList.Count)" -ForegroundColor Green
}
$report = [System.Collections.Generic.List[PSCustomObject]]::new()
if ($CrossReference -and $Source -eq 'Both') {
    $dnsMap = @{}; $dnsList | ForEach-Object { $dnsMap[$_.ComputerName.ToLower()]=$_.IPv4Address }
    $adList | ForEach-Object {
        $dip   = $dnsMap[$_.ComputerName.ToLower()]
        $match = if ($dip -and $_.IPv4Address) { $dip -eq $_.IPv4Address } else { $null }
        $status= if ($null -eq $match) {'DNS missing'} elseif ($match) {'Match'} else {'MISMATCH'}
        $report.Add([PSCustomObject]@{ComputerName=$_.ComputerName;AD_IPv4=$_.IPv4Address;DNS_IPv4=$dip;Status=$status;OperatingSystem=$_.OperatingSystem;LastLogonDate=$_.LastLogonDate;OU=$_.OU})
    }
    $bad = $report | Where-Object { $_.Status -eq 'MISMATCH' }
    Write-Host "Mismatches: $($bad.Count)" -ForegroundColor $(if($bad.Count){'Red'}else{'Green'})
    if ($bad.Count) { $bad | Format-Table ComputerName,AD_IPv4,DNS_IPv4,Status -AutoSize }
} else {
    foreach ($r in $adList)  { $report.Add($r) }
    foreach ($r in $dnsList) { $report.Add($r) }
}
$report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Exported $($report.Count) record(s) to: $OutputPath" -ForegroundColor Green
$report | Select-Object -First 20 | Format-Table Source,ComputerName,IPv4Address,Status -AutoSize
