#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS  Resolve a SID string to the AD user, group, or computer that owns it.
.NOTES
    CSV Columns: SID
    Usage   : .\19-Resolve-SID-to-AD-Object.ps1 -SID 'S-1-5-21-123-456-789-1001'
              .\19-Resolve-SID-to-AD-Object.ps1 -CsvPath sids.csv -OutputPath resolved.csv
#>
param(
    [string]$SID,
    [string]$CsvPath,
    [string]$OutputPath = ''
)
Import-Module ActiveDirectory -ErrorAction Stop

$builtIn = @{
    'S-1-1-0'='Everyone';'S-1-5-18'='Local System';'S-1-5-19'='Local Service'
    'S-1-5-20'='Network Service';'S-1-5-11'='Authenticated Users'
    'S-1-5-32-544'='Administrators';'S-1-5-32-545'='Users';'S-1-5-32-546'='Guests'
    'S-1-5-32-555'='Remote Desktop Users';'S-1-3-0'='Creator Owner'
}

function Resolve-OneSID ([string]$s) {
    $r = [PSCustomObject]@{SID=$s;SamAccountName=$null;DisplayName=$null;ObjectType=$null;Status='Not Found'}
    if ($builtIn.ContainsKey($s)) { $r.SamAccountName=$builtIn[$s]; $r.ObjectType='Built-in'; $r.Status='Found (Built-in)'; return $r }
    try {
        $o = Get-ADObject -Filter "objectSID -eq '$s'" -Properties SamAccountName,DisplayName,ObjectClass -ErrorAction Stop
        if ($o) { $r.SamAccountName=$o.SamAccountName; $r.DisplayName=$o.DisplayName; $r.ObjectType=$o.ObjectClass; $r.Status='Found (AD)'; return $r }
    } catch {}
    try {
        $n = ([Security.Principal.SecurityIdentifier]$s).Translate([Security.Principal.NTAccount])
        $r.SamAccountName=$n.Value; $r.ObjectType='Local/System'; $r.Status='Found (.NET)'; return $r
    } catch {}
    return $r
}

$sids = if ($CsvPath) { (Import-Csv $CsvPath).SID | Where-Object { $_ } }
        elseif ($SID) { @($SID) }
        else          { Write-Error 'Provide -SID or -CsvPath.'; exit 1 }

$results = $sids | ForEach-Object { Write-Host "Resolving: $_" -ForegroundColor Cyan; Resolve-OneSID $_.Trim() }
$results | Format-Table SID,SamAccountName,DisplayName,ObjectType,Status -AutoSize
if ($OutputPath) { $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8; Write-Host "Exported: $OutputPath" -ForegroundColor Green }
