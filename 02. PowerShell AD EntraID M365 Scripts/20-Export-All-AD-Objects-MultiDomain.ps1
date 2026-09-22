#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS  Export all AD users, groups, and computers from every domain in the forest to CSV.
.NOTES
    Run from a machine with Global Catalog access.
    Optional XLSX: Install-Module ImportExcel -Scope CurrentUser
    Usage   : .\20-Export-All-AD-Objects-MultiDomain.ps1 -OutputFolder .\ADExport
              .\20-Export-All-AD-Objects-MultiDomain.ps1 -ExportXLSX -IncludeDisabled
#>
param(
    [string]$OutputFolder   = ".\ADExport_$(Get-Date -Format 'yyyyMMdd')",
    [switch]$ExportXLSX,
    [switch]$IncludeDisabled,
    [string[]]$Domains
)
Import-Module ActiveDirectory -ErrorAction Stop
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
if (-not $Domains) {
    try   { $Domains = (Get-ADForest).Domains }
    catch { $Domains = @((Get-ADDomain).DNSRoot) }
    Write-Host "Domains: $($Domains -join ', ')" -ForegroundColor Cyan
}
$users=[System.Collections.Generic.List[PSCustomObject]]::new()
$groups=[System.Collections.Generic.List[PSCustomObject]]::new()
$comps=[System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($d in $Domains) {
    Write-Host "Processing: $d" -ForegroundColor Yellow
    $uF = if ($IncludeDisabled) { {SamAccountName -like '*'} } else { {Enabled -eq $true} }
    try {
        Get-ADUser -Filter $uF -Server $d -Properties SamAccountName,DisplayName,GivenName,Surname,UserPrincipalName,EmailAddress,Title,Department,Company,Enabled,LastLogonDate,PasswordLastSet,whenCreated,DistinguishedName | ForEach-Object {
            $users.Add([PSCustomObject]@{Domain=$d;SamAccountName=$_.SamAccountName;DisplayName=$_.DisplayName;FirstName=$_.GivenName;LastName=$_.Surname;UPN=$_.UserPrincipalName;Email=$_.EmailAddress;Title=$_.Title;Department=$_.Department;Company=$_.Company;Enabled=$_.Enabled;LastLogonDate=$_.LastLogonDate;PasswordLastSet=$_.PasswordLastSet;WhenCreated=$_.whenCreated;OU=($_.DistinguishedName -replace '^CN=[^,]+,','')})
        }
    } catch { Write-Warning "  Users failed: $_" }
    try {
        Get-ADGroup -Filter * -Server $d -Properties Name,SamAccountName,GroupScope,GroupCategory,Description,whenCreated,Members | ForEach-Object {
            $groups.Add([PSCustomObject]@{Domain=$d;Name=$_.Name;SamAccountName=$_.SamAccountName;GroupScope=$_.GroupScope;GroupCategory=$_.GroupCategory;Description=$_.Description;MemberCount=$_.Members.Count;WhenCreated=$_.whenCreated;OU=($_.DistinguishedName -replace '^CN=[^,]+,','')})
        }
    } catch { Write-Warning "  Groups failed: $_" }
    $cF = if ($IncludeDisabled) { {Name -like '*'} } else { {Enabled -eq $true} }
    try {
        Get-ADComputer -Filter $cF -Server $d -Properties Name,DNSHostName,IPv4Address,OperatingSystem,OperatingSystemVersion,LastLogonDate,PasswordLastSet,Enabled,whenCreated,DistinguishedName | ForEach-Object {
            $fqdn = if ($_.DNSHostName) { $_.DNSHostName } else { "$($_.Name).$d" }
            $comps.Add([PSCustomObject]@{Domain=$d;Name=$_.Name;FQDN=$fqdn;IPv4Address=$_.IPv4Address;OperatingSystem=$_.OperatingSystem;OSVersion=$_.OperatingSystemVersion;Enabled=$_.Enabled;LastLogonDate=$_.LastLogonDate;PasswordLastSet=$_.PasswordLastSet;WhenCreated=$_.whenCreated;OU=($_.DistinguishedName -replace '^CN=[^,]+,','')})
        }
    } catch { Write-Warning "  Computers failed: $_" }
    Write-Host "  Users: $($users.Count) | Groups: $($groups.Count) | Computers: $($comps.Count)" -ForegroundColor Green
}
$users  | Export-Csv "$OutputFolder\ADUsers.csv"     -NoTypeInformation -Encoding UTF8
$groups | Export-Csv "$OutputFolder\ADGroups.csv"    -NoTypeInformation -Encoding UTF8
$comps  | Export-Csv "$OutputFolder\ADComputers.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Saved to: $OutputFolder" -ForegroundColor Green
if ($ExportXLSX -and (Get-Module -ListAvailable -Name ImportExcel)) {
    Import-Module ImportExcel
    $x = "$OutputFolder\ADExport.xlsx"
    $users  | Export-Excel -Path $x -WorksheetName Users     -AutoSize -FreezeTopRow -BoldTopRow
    $groups | Export-Excel -Path $x -WorksheetName Groups    -AutoSize -FreezeTopRow -BoldTopRow
    $comps  | Export-Excel -Path $x -WorksheetName Computers -AutoSize -FreezeTopRow -BoldTopRow
    Write-Host "XLSX: $x" -ForegroundColor Green
}
