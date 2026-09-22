#Requires -Version 5.1
#Requires -Modules DnsServer, ActiveDirectory
<#
.SYNOPSIS  Find duplicate IP addresses in DNS A records and cross-reference with AD computers.
.NOTES
    Usage   : .\07-Find-Duplicate-IPs-in-DNS.ps1 -DnsServer DC01 -ZoneName contoso.com
#>
param(
    [Parameter(Mandatory)][string]$DnsServer,
    [Parameter(Mandatory)][string]$ZoneName,
    [string]$OutputPath = ".\DuplicateIPs_$(Get-Date -Format 'yyyyMMdd').csv",
    [switch]$ShowAll
)
Import-Module DnsServer, ActiveDirectory -ErrorAction Stop
Write-Host "Querying DNS zone '$ZoneName' on '$DnsServer'..." -ForegroundColor Cyan

$aRecords = Get-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $ZoneName -RRType A |
    Select-Object HostName, @{N='IPAddress';E={$_.RecordData.IPv4Address.ToString()}}, TimeToLive

$adComps  = Get-ADComputer -Filter { Enabled -eq $true } -Properties IPv4Address, LastLogonDate, OperatingSystem |
    Where-Object { $_.IPv4Address }

$duplicates = $aRecords | Group-Object IPAddress | Where-Object { $_.Count -gt 1 }
Write-Host "Total A records: $($aRecords.Count)  |  Duplicate IPs: $($duplicates.Count)" -ForegroundColor $(if($duplicates.Count){'Red'}else{'Green'})

$report = [System.Collections.Generic.List[PSCustomObject]]::new()
foreach ($dup in $duplicates) {
    Write-Host "  Duplicate: $($dup.Name)  ($($dup.Count) records)" -ForegroundColor Red
    foreach ($r in $dup.Group) {
        $adMatch = $adComps | Where-Object { $_.IPv4Address -eq $dup.Name } | Select-Object -First 1
        $report.Add([PSCustomObject]@{
            IPAddress=$dup.Name; DNSHostName=$r.HostName; ZoneName=$ZoneName
            ADComputer=$adMatch.Name; ADLastLogon=$adMatch.LastLogonDate; IsDuplicate=$true
        })
        Write-Host "    $($r.HostName)  |  AD: $(if($adMatch){$adMatch.Name}else{'Not in AD'})" -ForegroundColor DarkYellow
    }
}
if ($ShowAll) {
    $aRecords | Group-Object IPAddress | Where-Object { $_.Count -eq 1 } | ForEach-Object {
        $r = $_.Group[0]
        $report.Add([PSCustomObject]@{ IPAddress=$_.Name; DNSHostName=$r.HostName; ZoneName=$ZoneName; ADComputer=''; ADLastLogon=''; IsDuplicate=$false })
    }
}
$report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Saved to: $OutputPath" -ForegroundColor Green
