#Requires -Version 5.1
#Requires -Modules Microsoft.Graph.Users, Microsoft.Graph.Identity.DirectoryManagement
<#
.SYNOPSIS  Assign Microsoft 365 licenses to users from a CSV file.
.NOTES
    Install : Install-Module Microsoft.Graph -Scope CurrentUser
    Permissions: User.ReadWrite.All, Organization.Read.All
    CSV Columns: UserPrincipalName, LicenseSku  (e.g. ENTERPRISEPREMIUM)
    Usage   : .\01-Assign-M365-Licenses-from-CSV.ps1 -CsvPath .\users.csv
#>
param(
    [Parameter(Mandatory)][string]$CsvPath,
    [string]$TenantId
)
$connectParams = @{ Scopes = @('User.ReadWrite.All','Organization.Read.All') }
if ($TenantId) { $connectParams['TenantId'] = $TenantId }
Connect-MgGraph @connectParams -NoWelcome

$availableSkus = Get-MgSubscribedSku | Select-Object SkuId, SkuPartNumber
Write-Host "Available SKUs:" -ForegroundColor Cyan
$availableSkus | Format-Table -AutoSize

foreach ($row in (Import-Csv -Path $CsvPath)) {
    $upn     = $row.UserPrincipalName.Trim()
    $skuPart = $row.LicenseSku.Trim()
    $sku     = $availableSkus | Where-Object { $_.SkuPartNumber -eq $skuPart }
    if (-not $sku) { Write-Warning "[$upn] SKU '$skuPart' not found. Skipping."; continue }
    try {
        $mgUser = Get-MgUser -UserId $upn -Property 'assignedLicenses' -ErrorAction Stop
        if ($mgUser.AssignedLicenses.SkuId -contains $sku.SkuId) {
            Write-Host "[$upn] Already licensed with '$skuPart'." -ForegroundColor Yellow; continue
        }
        Set-MgUserLicense -UserId $upn -BodyParameter @{
            AddLicenses    = @(@{ SkuId = $sku.SkuId })
            RemoveLicenses = @()
        }
        Write-Host "[$upn] License '$skuPart' assigned." -ForegroundColor Green
    } catch { Write-Error "[$upn] Failed: $_" }
}
Disconnect-MgGraph
