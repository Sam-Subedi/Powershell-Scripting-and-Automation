#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS  Bulk-create Active Directory users from a CSV file.
.NOTES
    CSV Columns: FirstName, LastName, Username, Password, OU, Department,
                 Title, Email, Phone, Manager, Company, Description
    Usage   : .\03-Create-AD-Users-from-CSV.ps1 -CsvPath .\users.csv
              .\03-Create-AD-Users-from-CSV.ps1 -CsvPath .\users.csv -WhatIf
#>
param(
    [Parameter(Mandatory)][string]$CsvPath,
    [string]$DefaultOU     = 'OU=Users,DC=domain,DC=com',
    [string]$DefaultDomain = 'domain.com',
    [switch]$WhatIf
)
Import-Module ActiveDirectory -ErrorAction Stop
$created = 0; $skipped = 0; $failed = 0

foreach ($row in (Import-Csv -Path $CsvPath)) {
    $sam      = $row.Username.Trim()
    $full     = "$($row.FirstName.Trim()) $($row.LastName.Trim())"
    $ou       = if ($row.OU)    { $row.OU.Trim()    } else { $DefaultOU }
    $email    = if ($row.Email) { $row.Email.Trim() } else { "$sam@$DefaultDomain" }

    if (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue) {
        Write-Warning "User '$sam' exists. Skipping."; $skipped++; continue
    }
    try {
        $params = @{
            SamAccountName = $sam; UserPrincipalName = $email; Name = $full
            DisplayName = $full; GivenName = $row.FirstName.Trim(); Surname = $row.LastName.Trim()
            EmailAddress = $email; Path = $ou; Enabled = $true
            AccountPassword       = (ConvertTo-SecureString $row.Password -AsPlainText -Force)
            PasswordNeverExpires  = $false
            ChangePasswordAtLogon = $true
        }
        if ($row.Department)  { $params['Department']  = $row.Department.Trim() }
        if ($row.Title)       { $params['Title']       = $row.Title.Trim() }
        if ($row.Phone)       { $params['OfficePhone'] = $row.Phone.Trim() }
        if ($row.Company)     { $params['Company']     = $row.Company.Trim() }
        if ($row.Description) { $params['Description'] = $row.Description.Trim() }

        New-ADUser @params -WhatIf:$WhatIf

        if ($row.Manager -and -not $WhatIf) {
            $mgr = Get-ADUser -Filter "SamAccountName -eq '$($row.Manager)'" -ErrorAction SilentlyContinue
            if ($mgr) { Set-ADUser -Identity $sam -Manager $mgr.DistinguishedName }
        }
        Write-Host "$(if($WhatIf){'[WhatIf]'}else{'Created'}) user: $sam ($full)" -ForegroundColor Green
        $created++
    } catch { Write-Error "Failed '$sam': $_"; $failed++ }
}
Write-Host "Created: $created | Skipped: $skipped | Failed: $failed" -ForegroundColor Cyan
