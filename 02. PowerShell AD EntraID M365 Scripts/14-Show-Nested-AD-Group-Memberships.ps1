#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS  Show all inherited (nested) group memberships for an AD user or group.
.NOTES
    Uses LDAP_MATCHING_RULE_IN_CHAIN (OID 1.2.840.113556.1.4.1941) for fast recursive lookup.
    Usage   : .\14-Show-Nested-AD-Group-Memberships.ps1 -Identity jdoe
              .\14-Show-Nested-AD-Group-Memberships.ps1 -Identity HelpDesk -ObjectType Group
              .\14-Show-Nested-AD-Group-Memberships.ps1 -Identity jdoe -MaxLevels 5 -OutputPath result.csv
#>
param(
    [Parameter(Mandatory)][string]$Identity,
    [ValidateSet('User','Group')][string]$ObjectType = 'User',
    [int]$MaxLevels     = 3,
    [string]$OutputPath = '',
    [switch]$UseChainQuery
)
Import-Module ActiveDirectory -ErrorAction Stop

function Expand-Groups ([string]$DN,[int]$Lvl,[int]$Max,[System.Collections.Generic.HashSet[string]]$Seen) {
    if ($Lvl -gt $Max) { return }
    Get-ADGroupMember -Identity $DN -ErrorAction SilentlyContinue |
        Where-Object { $_.objectClass -eq 'group' } | ForEach-Object {
            if ($Seen.Add($_.DistinguishedName)) {
                [PSCustomObject]@{ Level=$Lvl; Name=$_.Name; SamAccountName=$_.SamAccountName; DistinguishedName=$_.DistinguishedName }
                Expand-Groups $_.DistinguishedName ($Lvl+1) $Max $Seen
            }
        }
}

$results = if ($UseChainQuery -or $ObjectType -eq 'Group') {
    $dn = if ($ObjectType -eq 'User') { (Get-ADUser  -Filter "SamAccountName -eq '$Identity'" -ErrorAction Stop).DistinguishedName }
          else                        { (Get-ADGroup -Filter "Name -eq '$Identity'"           -ErrorAction Stop).DistinguishedName }
    Get-ADObject -LDAPFilter "(&(objectClass=group)(member:1.2.840.113556.1.4.1941:=$dn))" -Properties Name,SamAccountName,Description |
        Select-Object @{N='Level';E={'*'}},Name,SamAccountName,Description,DistinguishedName
} else {
    $user = Get-ADUser -Filter "SamAccountName -eq '$Identity'" -Properties MemberOf -ErrorAction Stop
    $seen = [System.Collections.Generic.HashSet[string]]::new()
    $out  = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($dn in $user.MemberOf) {
        if ($seen.Add($dn)) {
            try {
                $g = Get-ADGroup -Identity $dn -Properties Description
                $out.Add([PSCustomObject]@{ Level=1; Name=$g.Name; SamAccountName=$g.SamAccountName; GroupScope=$g.GroupScope; Description=$g.Description; DistinguishedName=$dn })
                if ($MaxLevels -gt 1) { Expand-Groups $dn 2 $MaxLevels $seen | ForEach-Object { $out.Add($_) } }
            } catch {}
        }
    }
    $out
}

if (-not $results) { Write-Host 'No inherited groups found.' -ForegroundColor Yellow; exit 0 }
Write-Host "Found $(($results | Measure-Object).Count) group(s) for '$Identity':" -ForegroundColor Green
$results | Sort-Object Level, Name | Format-Table Level, Name, SamAccountName, Description -AutoSize
if ($OutputPath) { $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8; Write-Host "Exported: $OutputPath" -ForegroundColor Green }
