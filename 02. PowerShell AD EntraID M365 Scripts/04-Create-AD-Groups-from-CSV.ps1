#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS  Bulk-create Active Directory groups from a CSV file.
.NOTES
    CSV Columns: GroupName, GroupScope (DomainLocal|Global|Universal),
                 GroupCategory (Security|Distribution), OU, Description,
                 Members (semicolon-separated SamAccountNames)
    Usage   : .\04-Create-AD-Groups-from-CSV.ps1 -CsvPath .\groups.csv
#>
param(
    [Parameter(Mandatory)][string]$CsvPath,
    [string]$DefaultOU = 'OU=Groups,DC=domain,DC=com',
    [switch]$WhatIf
)
Import-Module ActiveDirectory -ErrorAction Stop
$created = 0; $skipped = 0; $failed = 0

foreach ($row in (Import-Csv -Path $CsvPath)) {
    $name  = $row.GroupName.Trim()
    $scope = if ($row.GroupScope    -in @('DomainLocal','Global','Universal')) { $row.GroupScope.Trim()    } else { 'Global' }
    $cat   = if ($row.GroupCategory -in @('Security','Distribution'))          { $row.GroupCategory.Trim() } else { 'Security' }
    $ou    = if ($row.OU)            { $row.OU.Trim() } else { $DefaultOU }

    if (Get-ADGroup -Filter "Name -eq '$name'" -ErrorAction SilentlyContinue) {
        Write-Warning "Group '$name' exists. Skipping."; $skipped++; continue
    }
    try {
        $params = @{ Name = $name; SamAccountName = $name; GroupScope = $scope; GroupCategory = $cat; Path = $ou }
        if ($row.Description) { $params['Description'] = $row.Description.Trim() }
        New-ADGroup @params -WhatIf:$WhatIf
        Write-Host "$(if($WhatIf){'[WhatIf]'}else{'Created'}) group: $name ($scope/$cat)" -ForegroundColor Green
        $created++

        if ($row.Members -and -not $WhatIf) {
            foreach ($m in ($row.Members -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
                $obj = Get-ADUser  -Filter "SamAccountName -eq '$m'" -ErrorAction SilentlyContinue
                if (-not $obj) { $obj = Get-ADGroup -Filter "Name -eq '$m'" -ErrorAction SilentlyContinue }
                if ($obj) { Add-ADGroupMember -Identity $name -Members $obj -Confirm:$false; Write-Host "  Added member: $m" -ForegroundColor DarkGreen }
                else      { Write-Warning "  Member '$m' not found." }
            }
        }
    } catch { Write-Error "Failed '$name': $_"; $failed++ }
}
Write-Host "Created: $created | Skipped: $skipped | Failed: $failed" -ForegroundColor Cyan
