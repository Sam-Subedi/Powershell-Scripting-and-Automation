#Requires -Version 5.1
#Requires -Modules Microsoft.Graph.Users, Microsoft.Graph.Identity.DirectoryManagement, Microsoft.Graph.Groups
<#
.SYNOPSIS  Gather a full M365 tenant report: users, groups, licenses, domains, admin roles, mailboxes.
.DESCRIPTION
    Updated 2026: MSOnline (retired March 2024) fully replaced by Microsoft Graph SDK.
    All Get-Msol* cmdlets are replaced with Get-Mg* equivalents.
    Exchange Online report requires ExchangeOnlineManagement module.
.NOTES
    Install : Install-Module Microsoft.Graph         -Scope CurrentUser
              Install-Module ExchangeOnlineManagement -Scope CurrentUser (for mailbox report)
    Usage   : .\33-M365-Tenant-Information-Report.ps1 -OutputFolder .\M365Report
              .\33-M365-Tenant-Information-Report.ps1 -OutputFolder .\M365Report -ConnectExchange -AdminUPN admin@contoso.com
#>
param(
    [string]$TenantId,
    [string]$OutputFolder  = ".\M365_Report_$(Get-Date -Format 'yyyyMMdd')",
    [switch]$ConnectExchange,
    [string]$AdminUPN
)
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

# Connect Graph
Write-Host 'Connecting to Microsoft Graph...' -ForegroundColor Cyan
$gP = @{Scopes=@('User.Read.All','Group.Read.All','Directory.Read.All','Organization.Read.All','RoleManagement.Read.Directory');NoWelcome=$true}
if ($TenantId) { $gP['TenantId']=$TenantId }
Connect-MgGraph @gP

if ($ConnectExchange) {
    Write-Host 'Connecting to Exchange Online...' -ForegroundColor Cyan
    $eP = @{ShowBanner=$false}; if ($AdminUPN) { $eP['UserPrincipalName']=$AdminUPN }
    Connect-ExchangeOnline @eP
}

# 1. Organization
Write-Host '[1] Organization info...' -ForegroundColor Yellow
$org = Get-MgOrganization
[PSCustomObject]@{DisplayName=$org.DisplayName;TenantId=$org.Id;TechContact=($org.TechnicalNotificationMails -join ', ');Country=$org.CountryLetterCode;ForestMode=$org.PreferredLanguage;Created=$org.CreatedDateTime} |
    Export-Csv "$OutputFolder\OrgInfo.csv" -NoTypeInformation -Encoding UTF8

# 2. Licenses
Write-Host '[2] License SKUs...' -ForegroundColor Yellow
Get-MgSubscribedSku | Select-Object SkuPartNumber,SkuId,
    @{N='Assigned'; E={$_.ConsumedUnits}},
    @{N='Available';E={$_.PrepaidUnits.Enabled - $_.ConsumedUnits}},
    @{N='Total';    E={$_.PrepaidUnits.Enabled}} |
    Tee-Object -Variable skuReport | Format-Table -AutoSize
$skuReport | Export-Csv "$OutputFolder\Licenses.csv" -NoTypeInformation -Encoding UTF8

# 3. All Users
Write-Host '[3] Users...' -ForegroundColor Yellow
$mgUsers = Get-MgUser -All -Property 'id,displayName,userPrincipalName,mail,accountEnabled,assignedLicenses,department,jobTitle,officeLocation,mobilePhone,createdDateTime,usageLocation,passwordPolicies'
$userRpt = $mgUsers | ForEach-Object {
    [PSCustomObject]@{UPN=$_.UserPrincipalName;DisplayName=$_.DisplayName;Email=$_.Mail;Enabled=$_.AccountEnabled;Department=$_.Department;JobTitle=$_.JobTitle;LicenseCount=$_.AssignedLicenses.Count;UsageLocation=$_.UsageLocation;Created=$_.CreatedDateTime;PasswordPolicies=$_.PasswordPolicies}
}
Write-Host "  Total users: $($userRpt.Count)" -ForegroundColor Green
$userRpt | Export-Csv "$OutputFolder\Users.csv" -NoTypeInformation -Encoding UTF8
$userRpt | Select-Object UPN,DisplayName,Enabled,Department,LicenseCount | Format-Table -AutoSize

# 4. Groups
Write-Host '[4] Groups...' -ForegroundColor Yellow
$grpRpt = Get-MgGroup -All -Property 'id,displayName,groupTypes,mailEnabled,securityEnabled,createdDateTime' | ForEach-Object {
    [PSCustomObject]@{DisplayName=$_.DisplayName;Type=if($_.GroupTypes -contains 'Unified'){'Microsoft 365'}elseif($_.MailEnabled){'Mail-Enabled Security'}elseif($_.SecurityEnabled){'Security'}else{'Distribution'};SecurityEnabled=$_.SecurityEnabled;MailEnabled=$_.MailEnabled;IsDynamic=($_.GroupTypes -contains 'DynamicMembership');Created=$_.CreatedDateTime}
}
Write-Host "  Total groups: $($grpRpt.Count)" -ForegroundColor Green
$grpRpt | Export-Csv "$OutputFolder\Groups.csv" -NoTypeInformation -Encoding UTF8
$grpRpt | Format-Table DisplayName,Type,SecurityEnabled,MailEnabled -AutoSize

# 5. Domains
Write-Host '[5] Domains...' -ForegroundColor Yellow
Get-MgDomain | Select-Object Id,IsDefault,IsVerified,AuthenticationType |
    Tee-Object -Variable domRpt | Format-Table -AutoSize
$domRpt | Export-Csv "$OutputFolder\Domains.csv" -NoTypeInformation -Encoding UTF8

# 6. Admin Roles
Write-Host '[6] Admin role assignments...' -ForegroundColor Yellow
try {
    $roleRpt = Get-MgDirectoryRole -All | ForEach-Object {
        $role = $_
        Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -ErrorAction SilentlyContinue | ForEach-Object {
            [PSCustomObject]@{Role=$role.DisplayName;MemberUPN=$_.AdditionalProperties['userPrincipalName'];MemberName=$_.AdditionalProperties['displayName'];MemberId=$_.Id}
        }
    }
    $roleRpt | Sort-Object Role,MemberUPN | Format-Table -AutoSize
    $roleRpt | Export-Csv "$OutputFolder\AdminRoles.csv" -NoTypeInformation -Encoding UTF8
} catch { Write-Warning "Role assignments failed: $_" }

# 7. Exchange Online mailboxes
if ($ConnectExchange) {
    Write-Host '[7] Mailboxes...' -ForegroundColor Yellow
    $mbxRpt = Get-Mailbox -ResultSize Unlimited | Select-Object DisplayName,UserPrincipalName,PrimarySmtpAddress,RecipientTypeDetails,ArchiveStatus,LitigationHoldEnabled,ProhibitSendQuota
    Write-Host "  Total mailboxes: $($mbxRpt.Count)" -ForegroundColor Green
    $mbxRpt | Export-Csv "$OutputFolder\Mailboxes.csv" -NoTypeInformation -Encoding UTF8
    $mbxRpt | Format-Table DisplayName,RecipientTypeDetails,ArchiveStatus -AutoSize

    Write-Host '[7b] Shared Mailboxes...' -ForegroundColor Yellow
    Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited |
        Select-Object DisplayName,PrimarySmtpAddress,WhenCreated |
        Export-Csv "$OutputFolder\SharedMailboxes.csv" -NoTypeInformation -Encoding UTF8

    Disconnect-ExchangeOnline -Confirm:$false
}

Disconnect-MgGraph
Write-Host "All reports saved to: $OutputFolder" -ForegroundColor Green
Get-ChildItem -Path $OutputFolder | Select-Object Name,Length | Format-Table -AutoSize
