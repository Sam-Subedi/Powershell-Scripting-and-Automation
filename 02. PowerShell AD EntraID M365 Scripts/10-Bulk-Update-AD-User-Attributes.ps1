#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS  Bulk-update AD user attributes from a CSV file.
.NOTES
    CSV must include SamAccountName. Other supported columns:
    DisplayName, FirstName, LastName, Title, Department, Company, Office,
    Phone, Mobile, Email, Manager, Description, StreetAddress, City,
    State, PostalCode, Country, Enabled (True/False)
    Usage   : .\10-Bulk-Update-AD-User-Attributes.ps1 -CsvPath .\updates.csv -WhatIf
#>
param(
    [Parameter(Mandatory)][string]$CsvPath,
    [switch]$WhatIf
)
Import-Module ActiveDirectory -ErrorAction Stop
$map = @{
    DisplayName='DisplayName'; FirstName='GivenName';  LastName='Surname'
    Title='Title'; Department='Department'; Company='Company'; Office='Office'
    Phone='OfficePhone'; Mobile='MobilePhone'; Email='EmailAddress'
    Description='Description'; StreetAddress='StreetAddress'; City='City'
    State='State'; PostalCode='PostalCode'; Country='Country'
}
$updated = 0; $skipped = 0; $failed = 0

foreach ($row in (Import-Csv -Path $CsvPath)) {
    $sam = $row.SamAccountName.Trim()
    if (-not $sam) { continue }
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue)) {
        Write-Warning "User '$sam' not found. Skipping."; $skipped++; continue
    }
    $setP = @{}
    foreach ($col in $map.Keys) {
        $val = $row.$col
        if ($val -and $val.Trim() -ne '') { $setP[$map[$col]] = $val.Trim() }
    }
    if ($row.Manager -and $row.Manager.Trim()) {
        $mgr = Get-ADUser -Filter "SamAccountName -eq '$($row.Manager.Trim())'" -ErrorAction SilentlyContinue
        if ($mgr) { $setP['Manager'] = $mgr.DistinguishedName }
        else      { Write-Warning "Manager '$($row.Manager)' not found for '$sam'." }
    }
    if ($row.Enabled) {
        $v = $row.Enabled.Trim().ToLower()
        if ($v -in @('true','1'))  { Enable-ADAccount  -Identity $sam -WhatIf:$WhatIf }
        if ($v -in @('false','0')) { Disable-ADAccount -Identity $sam -WhatIf:$WhatIf }
    }
    if ($setP.Count -eq 0) { Write-Host "[$sam] Nothing to update." -ForegroundColor DarkGray; $skipped++; continue }
    try {
        Set-ADUser -Identity $sam @setP -WhatIf:$WhatIf
        Write-Host "$(if($WhatIf){'[WhatIf]'}else{'Updated'}) $sam : $($setP.Keys -join ', ')" -ForegroundColor Green
        $updated++
    } catch { Write-Error "Failed '$sam': $_"; $failed++ }
}
Write-Host "Updated: $updated | Skipped: $skipped | Failed: $failed" -ForegroundColor Cyan
