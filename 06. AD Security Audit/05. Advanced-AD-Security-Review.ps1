<# 
.SYNOPSIS
Advanced Active Directory Security Review Script with Executive Dashboard, Health Score, Email Support, and HTML Report

.DESCRIPTION
Performs an advanced AD security review across password policy, privileged access,
inactive and disabled accounts, critical services, Windows features, replication,
time source, shares, security events, stale computer objects, unconstrained
delegation, Kerberos pre-auth, SPN exposure, fine-grained password policies,
audit policy, and recovery posture.

Exports a polished HTML report suitable for customer delivery, executive review,
or email attachment.

.NOTES
Run as Administrator on a Domain Controller or management server with:
- RSAT ActiveDirectory module
- Domain connectivity
- Permissions to read event logs and AD objects
- Optional SMTP relay to send report via email

Author:Vikas Singh
#>

[CmdletBinding()]
param(
    [string]$DomainName = "",
    [string]$ReportPath = ".\AD-Security-Review-$((Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')).html",
    [switch]$OpenReport,

    [switch]$SendEmail,
    [string]$From = "",
    [string]$To = "",
    [string]$Cc = "",
    [string]$SmtpServer = "",
    [int]$SmtpPort = 25,
    [string]$Subject = "",
    [switch]$UseSsl
)

$ErrorActionPreference = "SilentlyContinue"

function Write-Section {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
}

function Get-SeverityFromStatus {
    param([string]$Status)
    switch ($Status) {
        "PASS" { "pass" }
        "WARN" { "warn" }
        "FAIL" { "fail" }
        default { "info" }
    }
}

function New-ResultObject {
    param(
        [string]$Category,
        [string]$Check,
        [string]$Target,
        [string]$Status,
        [string]$Details,
        [string]$Recommendation = "",
        [int]$Weight = 1
    )

    [PSCustomObject]@{
        Category       = $Category
        Check          = $Check
        Target         = $Target
        Status         = $Status
        SeverityClass  = Get-SeverityFromStatus -Status $Status
        Details        = $Details
        Recommendation = $Recommendation
        Weight         = $Weight
    }
}

function Invoke-CommandSafe {
    param([scriptblock]$ScriptBlock)
    try { & $ScriptBlock } catch { $null }
}

function Get-CommandTextOutput {
    param([string]$Command, [string]$Arguments)

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Command
        $psi.Arguments = $Arguments
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $psi
        [void]$p.Start()
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()
        $p.WaitForExit()

        [PSCustomObject]@{
            ExitCode = $p.ExitCode
            StdOut   = $stdout.Trim()
            StdErr   = $stderr.Trim()
        }
    }
    catch {
        [PSCustomObject]@{
            ExitCode = 999
            StdOut   = ""
            StdErr   = $_.Exception.Message
        }
    }
}

function ConvertTo-HtmlTable {
    param(
        [Parameter(Mandatory)]
        [array]$Data,
        [Parameter(Mandatory)]
        [string]$Title
    )

    if (-not $Data -or $Data.Count -eq 0) {
        return "<div class='section'><h2>$Title</h2><p class='muted'>No data returned.</p></div>"
    }

    $headers = $Data[0].PSObject.Properties.Name
    $html = "<div class='section'><h2>$Title</h2><table><thead><tr>"
    foreach ($h in $headers) { $html += "<th>$h</th>" }
    $html += "</tr></thead><tbody>"

    foreach ($row in $Data) {
        $html += "<tr>"
        foreach ($h in $headers) {
            $value = $row.$h
            if ($null -eq $value) { $value = "" }

            if ($h -eq "Status") {
                $class = Get-SeverityFromStatus -Status ([string]$value)
                $html += "<td><span class='badge $class'>$value</span></td>"
            }
            else {
                $safe = [System.Web.HttpUtility]::HtmlEncode([string]$value)
                $html += "<td>$safe</td>"
            }
        }
        $html += "</tr>"
    }

    $html += "</tbody></table></div>"
    return $html
}

function Get-HealthScore {
    param([array]$Results)

    $totalWeight = 0
    $earnedWeight = 0

    foreach ($r in $Results) {
        $weight = [int]$r.Weight
        if ($weight -lt 1) { $weight = 1 }
        $totalWeight += $weight

        switch ($r.Status) {
            "PASS" { $earnedWeight += $weight }
            "WARN" { $earnedWeight += [math]::Round($weight * 0.5, 2) }
            "FAIL" { $earnedWeight += 0 }
            default { $earnedWeight += [math]::Round($weight * 0.5, 2) }
        }
    }

    if ($totalWeight -eq 0) { return 0 }
    return [math]::Round(($earnedWeight / $totalWeight) * 100, 2)
}

function Get-ScoreClass {
    param([double]$Score)
    if ($Score -ge 90) { return "green-score" }
    elseif ($Score -ge 75) { return "yellow-score" }
    else { return "red-score" }
}

function Get-OverallIndicator {
    param([int]$FailCount, [int]$WarnCount, [double]$Score)

    if ($FailCount -gt 0 -or $Score -lt 75) { return "RED" }
    elseif ($WarnCount -gt 0 -or $Score -lt 90) { return "YELLOW" }
    else { return "GREEN" }
}

function Send-ReportEmail {
    param(
        [string]$From,
        [string]$To,
        [string]$Cc,
        [string]$SmtpServer,
        [int]$SmtpPort,
        [string]$Subject,
        [string]$Body,
        [string]$Attachment,
        [bool]$UseSsl
    )

    try {
        $mailParams = @{
            From        = $From
            To          = $To
            Subject     = $Subject
            Body        = $Body
            BodyAsHtml  = $true
            SmtpServer  = $SmtpServer
            Port        = $SmtpPort
            Attachments = $Attachment
        }

        if (-not [string]::IsNullOrWhiteSpace($Cc)) { $mailParams.Cc = $Cc }
        if ($UseSsl) { $mailParams.UseSsl = $true }

        Send-MailMessage @mailParams
        return $true
    }
    catch {
        Write-Warning "Email sending failed: $($_.Exception.Message)"
        return $false
    }
}

Import-Module ActiveDirectory -ErrorAction SilentlyContinue

Write-Section "AD Security Review - Domain Controller"

$Results            = New-Object System.Collections.Generic.List[Object]
$DomainOverview     = @()
$PrivilegedMembers  = @()
$PolicyResults      = @()
$DisabledAccounts   = @()
$InactiveUsers      = @()
$InstalledFeatures  = @()
$ServiceResults     = @()
$ReplicationResults = @()
$TimeResults        = @()
$ShareResults       = @()
$SecurityEvents     = @()
$StaleComputers     = @()
$DelegationResults  = @()
$SpnResults         = @()
$PreAuthResults     = @()
$FgppResults        = @()
$AuditResults       = @()
$RawCommandSections = @()

if ([string]::IsNullOrWhiteSpace($DomainName)) {
    $DomainName = (Invoke-CommandSafe { (Get-ADDomain).DNSRoot })
}

if ([string]::IsNullOrWhiteSpace($DomainName)) {
    throw "Unable to determine domain name. Please provide -DomainName."
}

$Now = Get-Date
$Forest = Invoke-CommandSafe { Get-ADForest }
$Domain = Invoke-CommandSafe { Get-ADDomain }

Write-Section "Collecting Domain Overview"

if ($Forest -and $Domain) {
    $DomainOverview += [PSCustomObject]@{
        ForestName           = $Forest.Name
        DomainName           = $Domain.DNSRoot
        NetBIOSName          = $Domain.NetBIOSName
        ForestMode           = $Forest.ForestMode
        DomainMode           = $Domain.DomainMode
        PDCEmulator          = $Domain.PDCEmulator
        RIDMaster            = $Domain.RIDMaster
        InfrastructureMaster = $Domain.InfrastructureMaster
        RecycleBinEnabled    = [bool]$Forest.RecycleBinEnabled
    }

    $Results.Add((New-ResultObject -Category "Directory" -Check "Domain Discovery" -Target $DomainName -Status "PASS" -Details "Forest/domain information collected successfully." -Recommendation "No action required." -Weight 5))
}
else {
    $Results.Add((New-ResultObject -Category "Directory" -Check "Domain Discovery" -Target $DomainName -Status "FAIL" -Details "Unable to collect forest/domain information." -Recommendation "Verify AD module and required permissions." -Weight 5))
}

Write-Section "1. Privileged Group Members"

$PrivGroups = @("Domain Admins","Enterprise Admins","Schema Admins","Administrators","Account Operators","Server Operators","Backup Operators")
foreach ($group in $PrivGroups) {
    $members = Invoke-CommandSafe {
        Get-ADGroupMember $group -Recursive | Select-Object Name, SamAccountName, objectClass
    }

    if ($members) {
        foreach ($m in $members) {
            $PrivilegedMembers += [PSCustomObject]@{
                Group          = $group
                Name           = $m.Name
                SamAccountName = $m.SamAccountName
                ObjectClass    = $m.objectClass
            }
        }

        $memberCount = @($members).Count
        $status = if ($memberCount -gt 15) { "WARN" } else { "PASS" }
        $Results.Add((New-ResultObject -Category "Privilege" -Check "Privileged Group Membership" -Target $group -Status $status -Details "$memberCount members found." -Recommendation "Review least privilege and remove unnecessary permanent admin access." -Weight 5))
    }
    else {
        $Results.Add((New-ResultObject -Category "Privilege" -Check "Privileged Group Membership" -Target $group -Status "WARN" -Details "No members returned or unable to query group." -Recommendation "Validate permissions and confirm group membership intentionally." -Weight 3))
    }
}

Write-Section "2. Default Password Policy"

$pwdPolicy = Invoke-CommandSafe { Get-ADDefaultDomainPasswordPolicy }
if ($pwdPolicy) {
    $PolicyResults += [PSCustomObject]@{
        Policy               = "Default Domain Password Policy"
        MinPasswordLength    = $pwdPolicy.MinPasswordLength
        PasswordHistoryCount = $pwdPolicy.PasswordHistoryCount
        MaxPasswordAge       = $pwdPolicy.MaxPasswordAge
        MinPasswordAge       = $pwdPolicy.MinPasswordAge
        ComplexityEnabled    = $pwdPolicy.ComplexityEnabled
        ReversibleEncryption = $pwdPolicy.ReversibleEncryptionEnabled
        LockoutThreshold     = $pwdPolicy.LockoutThreshold
        LockoutDuration      = $pwdPolicy.LockoutDuration
        ObservationWindow    = $pwdPolicy.LockoutObservationWindow
    }

    $pwdStatus = "PASS"
    if ($pwdPolicy.MinPasswordLength -lt 12 -or -not $pwdPolicy.ComplexityEnabled -or $pwdPolicy.ReversibleEncryptionEnabled) {
        $pwdStatus = "FAIL"
    } elseif ($pwdPolicy.MinPasswordLength -lt 14 -or $pwdPolicy.PasswordHistoryCount -lt 12) {
        $pwdStatus = "WARN"
    }

    $Results.Add((New-ResultObject -Category "Policy" -Check "Default Password Policy" -Target $DomainName -Status $pwdStatus -Details "Password policy evaluated successfully." -Recommendation "Use strong password length, history, lockout, and never allow reversible encryption." -Weight 5))
}
else {
    $Results.Add((New-ResultObject -Category "Policy" -Check "Default Password Policy" -Target $DomainName -Status "FAIL" -Details "Unable to retrieve default domain password policy." -Recommendation "Verify RSAT module and permissions." -Weight 5))
}

Write-Section "3. Disabled Accounts"

$disabled = Invoke-CommandSafe {
    Search-ADAccount -AccountDisabled | Select-Object Name, SamAccountName, ObjectClass
}
if ($disabled) {
    $DisabledAccounts = $disabled
    $Results.Add((New-ResultObject -Category "Accounts" -Check "Disabled Accounts Review" -Target $DomainName -Status "PASS" -Details "$(@($disabled).Count) disabled accounts identified for review." -Recommendation "Periodically clean up or document disabled accounts kept for business reasons." -Weight 2))
}
else {
    $Results.Add((New-ResultObject -Category "Accounts" -Check "Disabled Accounts Review" -Target $DomainName -Status "WARN" -Details "No disabled accounts found or unable to query." -Recommendation "Validate directory visibility and confirm expected state." -Weight 2))
}

Write-Section "4. Inactive User Accounts"

$inactive = Invoke-CommandSafe {
    Search-ADAccount -AccountInactive -UsersOnly -TimeSpan 90.00:00:00 | Select-Object Name, SamAccountName
}
if ($inactive) {
    $InactiveUsers = $inactive
    $count = @($inactive).Count
    $status = if ($count -gt 50) { "WARN" } else { "PASS" }
    $Results.Add((New-ResultObject -Category "Accounts" -Check "Inactive Users (90 Days)" -Target $DomainName -Status $status -Details "$count inactive users detected." -Recommendation "Disable, move, or remove stale accounts after business validation." -Weight 4))
}
else {
    $Results.Add((New-ResultObject -Category "Accounts" -Check "Inactive Users (90 Days)" -Target $DomainName -Status "PASS" -Details "No inactive users returned." -Recommendation "No action required." -Weight 4))
}

Write-Section "5. Installed Windows Features"

$features = Invoke-CommandSafe {
    Get-WindowsFeature | Where-Object {$_.InstallState -eq "Installed"} | Select-Object DisplayName, Name
}
if ($features) {
    $InstalledFeatures = $features
    $Results.Add((New-ResultObject -Category "Hardening" -Check "Installed Windows Features" -Target $env:COMPUTERNAME -Status "PASS" -Details "$(@($features).Count) installed features identified." -Recommendation "Review unnecessary installed roles/features and remove unused attack surface." -Weight 3))
}
else {
    $Results.Add((New-ResultObject -Category "Hardening" -Check "Installed Windows Features" -Target $env:COMPUTERNAME -Status "WARN" -Details "Unable to enumerate installed Windows features." -Recommendation "Run on Windows Server with required module access." -Weight 2))
}

Write-Section "6. Critical Services"

$CriticalServices = "NTDS","DNS","Netlogon","DFSR","W32Time","KDC","ADWS"
foreach ($svc in $CriticalServices) {
    $service = Invoke-CommandSafe { Get-Service $svc }
    if ($service) {
        $status = if ($service.Status -eq "Running") { "PASS" } else { "FAIL" }
        $ServiceResults += [PSCustomObject]@{
            Service      = $service.Name
            DisplayName  = $service.DisplayName
            Status       = $status
            CurrentState = $service.Status
        }

        $Results.Add((New-ResultObject -Category "Services" -Check $service.Name -Target $env:COMPUTERNAME -Status $status -Details "Service state: $($service.Status)." -Recommendation "Ensure critical AD services are running and set properly." -Weight 5))
    }
    else {
        $ServiceResults += [PSCustomObject]@{
            Service      = $svc
            DisplayName  = $svc
            Status       = "WARN"
            CurrentState = "Unknown"
        }
        $Results.Add((New-ResultObject -Category "Services" -Check $svc -Target $env:COMPUTERNAME -Status "WARN" -Details "Unable to query service." -Recommendation "Verify service access and server role." -Weight 3))
    }
}

Write-Section "7. Replication Summary"

$replSummary = Get-CommandTextOutput -Command "repadmin.exe" -Arguments "/replsummary"
$RawCommandSections += [PSCustomObject]@{ Title = "repadmin /replsummary"; Output = $replSummary.StdOut; ExitCode = $replSummary.ExitCode }

if ($replSummary.StdOut) {
    $ReplicationResults += [PSCustomObject]@{
        Check   = "repadmin /replsummary"
        Status  = if ($replSummary.StdOut -match "fails|error") { "WARN" } else { "PASS" }
        Details = $replSummary.StdOut
    }

    $status = if ($replSummary.StdOut -match "fails|error" -or $replSummary.ExitCode -ne 0) { "WARN" } else { "PASS" }
    $Results.Add((New-ResultObject -Category "Replication" -Check "Replication Summary" -Target $DomainName -Status $status -Details "Replication summary executed." -Recommendation "Investigate failed partners, large deltas, and stale replication." -Weight 5))
}
else {
    $Results.Add((New-ResultObject -Category "Replication" -Check "Replication Summary" -Target $DomainName -Status "FAIL" -Details $replSummary.StdErr -Recommendation "Ensure repadmin is installed and run with proper permissions." -Weight 5))
}

Write-Section "8. Time Source"

$timeSource = Get-CommandTextOutput -Command "w32tm.exe" -Arguments "/query /source"
$TimeResults += [PSCustomObject]@{
    Check   = "Time Source"
    Status  = if ($timeSource.ExitCode -eq 0) { "PASS" } else { "WARN" }
    Details = if ($timeSource.StdOut) { $timeSource.StdOut } else { $timeSource.StdErr }
}
$Results.Add((New-ResultObject -Category "Time" -Check "Time Source" -Target $env:COMPUTERNAME -Status (if($timeSource.ExitCode -eq 0){"PASS"}else{"WARN"}) -Details (if($timeSource.StdOut){$timeSource.StdOut}else{$timeSource.StdErr}) -Recommendation "Ensure the PDC emulator has a reliable time source and all systems sync correctly." -Weight 4))

Write-Section "9. Shares"

$shares = Invoke-CommandSafe { Get-SmbShare | Select-Object Name, Path, Description }
if ($shares) {
    $ShareResults = $shares
    $sysvol = @($shares | Where-Object Name -eq "SYSVOL").Count
    $netlogon = @($shares | Where-Object Name -eq "NETLOGON").Count
    $status = if ($sysvol -ge 1 -and $netlogon -ge 1) { "PASS" } else { "FAIL" }
    $Results.Add((New-ResultObject -Category "SYSVOL" -Check "SYSVOL and NETLOGON Shares" -Target $env:COMPUTERNAME -Status $status -Details "SYSVOL count: $sysvol, NETLOGON count: $netlogon." -Recommendation "If either share is missing, review SYSVOL replication and Netlogon health." -Weight 5))
}
else {
    $Results.Add((New-ResultObject -Category "SYSVOL" -Check "SYSVOL and NETLOGON Shares" -Target $env:COMPUTERNAME -Status "FAIL" -Details "Unable to retrieve shares." -Recommendation "Check SMB share enumeration and server health." -Weight 5))
}

Write-Section "10. Recent Security Events"

$events = Invoke-CommandSafe {
    Get-WinEvent -LogName Security -MaxEvents 50 | Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message
}
if ($events) {
    $SecurityEvents = $events | Select-Object -First 20
    $specialIds = @(4624,4625,4672,4688,4720,4722,4723,4724,4725,4726,4732,4733,4740,4768,4769,4771,4776,1102)
    $interesting = @($events | Where-Object { $specialIds -contains $_.Id }).Count
    $status = if ($interesting -gt 25) { "WARN" } else { "PASS" }

    $Results.Add((New-ResultObject -Category "Audit" -Check "Recent Security Events" -Target $env:COMPUTERNAME -Status $status -Details "$interesting relevant security events found in recent sample." -Recommendation "Review failed logons, privilege use, group changes, account lockouts, and cleared logs." -Weight 4))
}
else {
    $Results.Add((New-ResultObject -Category "Audit" -Check "Recent Security Events" -Target $env:COMPUTERNAME -Status "WARN" -Details "Unable to query Security log." -Recommendation "Run with rights to access Security event logs." -Weight 4))
}

Write-Section "Advanced Security Checks"

$fgpps = Invoke-CommandSafe {
    Get-ADFineGrainedPasswordPolicy -Filter * | Select-Object Name, Precedence, MinPasswordLength, PasswordHistoryCount, ComplexityEnabled, LockoutThreshold
}
if ($fgpps) {
    $FgppResults = $fgpps
    $Results.Add((New-ResultObject -Category "Policy" -Check "Fine-Grained Password Policies" -Target $DomainName -Status "PASS" -Details "$(@($fgpps).Count) FGPP objects found." -Recommendation "Validate FGPP scope and ensure privileged users have stronger controls where required." -Weight 3))
}
else {
    $Results.Add((New-ResultObject -Category "Policy" -Check "Fine-Grained Password Policies" -Target $DomainName -Status "WARN" -Details "No FGPP found or unable to query." -Recommendation "Consider FGPP for privileged or sensitive user populations." -Weight 2))
}

$staleComputersQuery = Invoke-CommandSafe {
    Search-ADAccount -AccountInactive -ComputersOnly -TimeSpan 90.00:00:00 | Select-Object Name, SamAccountName
}
if ($staleComputersQuery) {
    $StaleComputers = $staleComputersQuery
    $count = @($staleComputersQuery).Count
    $status = if ($count -gt 25) { "WARN" } else { "PASS" }
    $Results.Add((New-ResultObject -Category "Assets" -Check "Inactive Computers (90 Days)" -Target $DomainName -Status $status -Details "$count inactive computer accounts detected." -Recommendation "Disable or remove stale computer objects after validation." -Weight 3))
}
else {
    $Results.Add((New-ResultObject -Category "Assets" -Check "Inactive Computers (90 Days)" -Target $DomainName -Status "PASS" -Details "No inactive computer accounts returned." -Recommendation "No action required." -Weight 3))
}

$delegation = Invoke-CommandSafe {
    Get-ADObject -LDAPFilter "(&(userAccountControl:1.2.840.113556.1.4.803:=524288)(|(objectClass=user)(objectClass=computer)))" -Properties userAccountControl,servicePrincipalName |
    Select-Object Name, ObjectClass, DistinguishedName
}
if ($delegation) {
    $DelegationResults = $delegation
    $count = @($delegation).Count
    $status = if ($count -gt 0) { "WARN" } else { "PASS" }
    $Results.Add((New-ResultObject -Category "Delegation" -Check "Unconstrained Delegation" -Target $DomainName -Status $status -Details "$count objects found with unconstrained delegation." -Recommendation "Remove unconstrained delegation where possible and use constrained or resource-based delegation instead." -Weight 5))
}
else {
    $Results.Add((New-ResultObject -Category "Delegation" -Check "Unconstrained Delegation" -Target $DomainName -Status "PASS" -Details "No unconstrained delegation objects returned." -Recommendation "No action required." -Weight 5))
}

$preauth = Invoke-CommandSafe {
    Get-ADUser -LDAPFilter "(userAccountControl:1.2.840.113556.1.4.803:=4194304)" -Properties SamAccountName |
    Select-Object Name, SamAccountName
}
if ($preauth) {
    $PreAuthResults = $preauth
    $count = @($preauth).Count
    $status = if ($count -gt 0) { "WARN" } else { "PASS" }
    $Results.Add((New-ResultObject -Category "Kerberos" -Check "Kerberos Pre-Auth Disabled" -Target $DomainName -Status $status -Details "$count accounts found without Kerberos pre-auth." -Recommendation "Review AS-REP roast exposure and re-enable pre-auth unless explicitly required." -Weight 5))
}
else {
    $Results.Add((New-ResultObject -Category "Kerberos" -Check "Kerberos Pre-Auth Disabled" -Target $DomainName -Status "PASS" -Details "No accounts found without Kerberos pre-auth." -Recommendation "No action required." -Weight 5))
}

$spnUsers = Invoke-CommandSafe {
    Get-ADUser -LDAPFilter "(servicePrincipalName=*)" -Properties servicePrincipalName,PasswordLastSet,Enabled |
    Select-Object Name, SamAccountName, Enabled, PasswordLastSet
}
if ($spnUsers) {
    $SpnResults = $spnUsers
    $count = @($spnUsers).Count
    $status = if ($count -gt 20) { "WARN" } else { "PASS" }
    $Results.Add((New-ResultObject -Category "Kerberos" -Check "SPN-Enabled User Accounts" -Target $DomainName -Status $status -Details "$count user accounts with SPNs found." -Recommendation "Review service accounts for strong passwords, gMSA adoption, and Kerberoast exposure." -Weight 4))
}
else {
    $Results.Add((New-ResultObject -Category "Kerberos" -Check "SPN-Enabled User Accounts" -Target $DomainName -Status "PASS" -Details "No SPN-enabled user accounts returned." -Recommendation "No action required." -Weight 4))
}

$auditPol = Get-CommandTextOutput -Command "auditpol.exe" -Arguments "/get /category:*"
$RawCommandSections += [PSCustomObject]@{ Title = "auditpol /get /category:*"; Output = $auditPol.StdOut; ExitCode = $auditPol.ExitCode }
if ($auditPol.StdOut) {
    $AuditResults += [PSCustomObject]@{
        Check   = "Audit Policy"
        Status  = "PASS"
        Details = "Audit policy retrieved successfully."
    }
    $Results.Add((New-ResultObject -Category "Audit" -Check "Audit Policy Review" -Target $env:COMPUTERNAME -Status "PASS" -Details "Audit policy data collected." -Recommendation "Ensure advanced auditing covers logon, account management, DS access, policy change, privilege use, and process creation as required." -Weight 4))
}
else {
    $Results.Add((New-ResultObject -Category "Audit" -Check "Audit Policy Review" -Target $env:COMPUTERNAME -Status "WARN" -Details $auditPol.StdErr -Recommendation "Verify auditpol availability and permissions." -Weight 4))
}

if ($Forest -and $Forest.RecycleBinEnabled) {
    $Results.Add((New-ResultObject -Category "Recovery" -Check "AD Recycle Bin" -Target $DomainName -Status "PASS" -Details "Recycle Bin is enabled." -Recommendation "No action required." -Weight 3))
}
else {
    $Results.Add((New-ResultObject -Category "Recovery" -Check "AD Recycle Bin" -Target $DomainName -Status "WARN" -Details "Recycle Bin is not enabled or could not be confirmed." -Recommendation "Consider enabling AD Recycle Bin after change approval and validation." -Weight 3))
}

$adminCountUsers = Invoke-CommandSafe {
    Get-ADObject -LDAPFilter "(adminCount=1)" -Properties adminCount,sAMAccountName | Select-Object Name, ObjectClass, sAMAccountName
}
if ($adminCountUsers) {
    $count = @($adminCountUsers).Count
    $status = if ($count -gt 25) { "WARN" } else { "PASS" }
    $Results.Add((New-ResultObject -Category "Privilege" -Check "adminCount=1 Objects" -Target $DomainName -Status $status -Details "$count protected/adminCount objects found." -Recommendation "Review protected groups and stale privileged assignments." -Weight 4))
}

Write-Section "Calculating Executive Summary"

$PassCount = @($Results | Where-Object Status -eq "PASS").Count
$WarnCount = @($Results | Where-Object Status -eq "WARN").Count
$FailCount = @($Results | Where-Object Status -eq "FAIL").Count
$TotalChecks = @($Results).Count

$HealthScore = Get-HealthScore -Results $Results
$ScoreClass = Get-ScoreClass -Score $HealthScore
$ExecutiveIndicator = Get-OverallIndicator -FailCount $FailCount -WarnCount $WarnCount -Score $HealthScore
$IndicatorClass = switch ($ExecutiveIndicator) {
    "GREEN" { "green-score" }
    "YELLOW" { "yellow-score" }
    default { "red-score" }
}

$TopFindings = $Results |
    Where-Object { $_.Status -in @("FAIL","WARN") } |
    Select-Object -First 20 Category, Check, Target, Status, Details, Recommendation

$Recommendations = $Results |
    Where-Object { $_.Status -in @("FAIL","WARN") } |
    Select-Object Category, Check, Target, Status, Recommendation

$css = @"
<style>
body {
    font-family: Segoe UI, Arial, sans-serif;
    background: #0a1220;
    color: #e8edf7;
    margin: 0;
    padding: 0;
}
.wrapper {
    width: 96%;
    margin: 20px auto;
}
.header {
    background: linear-gradient(135deg, #0f1a31, #1d335e);
    border: 1px solid #2f4a81;
    border-radius: 16px;
    padding: 24px;
    box-shadow: 0 8px 24px rgba(0,0,0,0.35);
}
.brand {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 16px;
}
h1 {
    margin: 0;
    font-size: 34px;
    color: #ffffff;
}
.subtitle {
    margin-top: 8px;
    color: #bfd0f3;
    font-size: 14px;
}
.meta {
    margin-top: 12px;
    color: #e0e8f8;
    font-size: 13px;
}
.dashboard-row {
    display: flex;
    flex-wrap: wrap;
    gap: 16px;
    margin: 20px 0;
}
.dashboard-card {
    flex: 1 1 220px;
    background: #121d34;
    border: 1px solid #273a63;
    border-radius: 14px;
    padding: 20px;
    box-shadow: 0 4px 16px rgba(0,0,0,0.28);
}
.dashboard-card h3 {
    margin: 0 0 8px 0;
    font-size: 14px;
    color: #bfd0f3;
    text-transform: uppercase;
    letter-spacing: .5px;
}
.dashboard-value {
    font-size: 34px;
    font-weight: 800;
}
.green-score { color: #33d17a; }
.yellow-score { color: #ffb020; }
.red-score { color: #ff5d5d; }
.cards {
    display: flex;
    flex-wrap: wrap;
    gap: 16px;
    margin: 20px 0;
}
.card {
    flex: 1 1 180px;
    background: #121c31;
    border: 1px solid #27385f;
    border-radius: 12px;
    padding: 18px;
    box-shadow: 0 4px 18px rgba(0,0,0,0.28);
}
.card h3 {
    margin: 0 0 8px 0;
    font-size: 14px;
    color: #bcd0f5;
    text-transform: uppercase;
    letter-spacing: .5px;
}
.card .value {
    font-size: 34px;
    font-weight: 700;
}
.pass-text { color: #30d158; }
.warn-text { color: #ffb020; }
.fail-text { color: #ff5d5d; }
.info-text { color: #72b4ff; }
.section {
    background: #11192c;
    border: 1px solid #263556;
    border-radius: 12px;
    padding: 18px;
    margin: 18px 0;
    box-shadow: 0 3px 14px rgba(0,0,0,0.22);
}
.section h2 {
    margin-top: 0;
    font-size: 21px;
    color: #ffffff;
    border-left: 5px solid #5aa9ff;
    padding-left: 10px;
}
table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 12px;
}
th {
    background: #1d2b49;
    color: #ffffff;
    text-align: left;
    padding: 10px;
    font-size: 13px;
    border-bottom: 1px solid #31456e;
}
td {
    padding: 10px;
    font-size: 13px;
    color: #e8edf7;
    border-bottom: 1px solid #21304e;
    vertical-align: top;
}
tr:nth-child(even) td {
    background: #0f1728;
}
.badge {
    display: inline-block;
    padding: 4px 10px;
    border-radius: 999px;
    font-size: 12px;
    font-weight: 700;
    min-width: 48px;
    text-align: center;
}
.badge.pass { background: rgba(48,209,88,0.16); color: #5be37c; border: 1px solid rgba(48,209,88,0.35); }
.badge.warn { background: rgba(255,176,32,0.16); color: #ffc35b; border: 1px solid rgba(255,176,32,0.35); }
.badge.fail { background: rgba(255,93,93,0.16); color: #ff8484; border: 1px solid rgba(255,93,93,0.35); }
.badge.info { background: rgba(114,180,255,0.16); color: #9cccff; border: 1px solid rgba(114,180,255,0.35); }
pre {
    white-space: pre-wrap;
    word-break: break-word;
    background: #0a1020;
    border: 1px solid #243459;
    color: #e0ebff;
    padding: 12px;
    border-radius: 10px;
    overflow-x: auto;
    font-size: 12px;
}
.footer {
    margin: 24px 0 40px 0;
    font-size: 12px;
    color: #9eb1d6;
    text-align: center;
}
.muted { color: #9fb0cf; }
.logo-box {
    text-align: right;
    font-size: 13px;
    color: #dbe6fb;
}
.logo-box strong {
    display: block;
    font-size: 16px;
    color: #ffffff;
}
</style>
"@

$headerHtml = @"
<div class='header'>
    <div class='brand'>
        <div>
            <h1>Advanced Active Directory Security Review Report</h1>
            <div class='subtitle'>Executive-ready AD security assessment covering privileged access, password policy, stale accounts, Kerberos, delegation, audit policy, replication, critical services, and operational security posture.</div>
            <div class='meta'>
                <strong>Domain:</strong> $DomainName |
                <strong>Generated:</strong> $Now |
                <strong>Executive Status:</strong> <span class='badge $(Get-SeverityFromStatus -Status $(if($ExecutiveIndicator -eq "GREEN"){"PASS"}elseif($ExecutiveIndicator -eq "YELLOW"){"WARN"}else{"FAIL"}))'>$ExecutiveIndicator</span>
            </div>
        </div>
        <div class='logo-box'>
            <strong>YouTube - Labs Hands On</strong>
            Vikas Singh<br/>
            vikas.9452@gmail.com
        </div>
    </div>
</div>
"@

$dashboardHtml = @"
<div class='dashboard-row'>
    <div class='dashboard-card'>
        <h3>Health Score</h3>
        <div class='dashboard-value $ScoreClass'>$HealthScore%</div>
    </div>
    <div class='dashboard-card'>
        <h3>Executive Indicator</h3>
        <div class='dashboard-value $IndicatorClass'>$ExecutiveIndicator</div>
    </div>
    <div class='dashboard-card'>
        <h3>Total Security Checks</h3>
        <div class='dashboard-value info-text'>$TotalChecks</div>
    </div>
</div>
"@

$cardsHtml = @"
<div class='cards'>
    <div class='card'>
        <h3>Passed</h3>
        <div class='value pass-text'>$PassCount</div>
    </div>
    <div class='card'>
        <h3>Warnings</h3>
        <div class='value warn-text'>$WarnCount</div>
    </div>
    <div class='card'>
        <h3>Failures</h3>
        <div class='value fail-text'>$FailCount</div>
    </div>
    <div class='card'>
        <h3>Domain</h3>
        <div class='value info-text'>$DomainName</div>
    </div>
</div>
"@

$rawHtml = ""
foreach ($section in $RawCommandSections) {
    $safeTitle = [System.Web.HttpUtility]::HtmlEncode($section.Title)
    $safeOut = [System.Web.HttpUtility]::HtmlEncode($section.Output)
    $rawHtml += "<div class='section'><h2>Raw Command Output - $safeTitle</h2><div class='muted'>Exit Code: $($section.ExitCode)</div><pre>$safeOut</pre></div>"
}

$htmlParts = @()
$htmlParts += "<html><head><title>AD Security Review - $DomainName</title>$css</head><body><div class='wrapper'>"
$htmlParts += $headerHtml
$htmlParts += $dashboardHtml
$htmlParts += $cardsHtml
$htmlParts += ConvertTo-HtmlTable -Data $TopFindings -Title "Top Findings"
$htmlParts += ConvertTo-HtmlTable -Data $Recommendations -Title "Recommended Actions"
$htmlParts += ConvertTo-HtmlTable -Data $DomainOverview -Title "Domain Overview"
$htmlParts += ConvertTo-HtmlTable -Data $PrivilegedMembers -Title "Privileged Group Members"
$htmlParts += ConvertTo-HtmlTable -Data $PolicyResults -Title "Password Policy Review"
$htmlParts += ConvertTo-HtmlTable -Data $FgppResults -Title "Fine-Grained Password Policies"
$htmlParts += ConvertTo-HtmlTable -Data $DisabledAccounts -Title "Disabled Accounts"
$htmlParts += ConvertTo-HtmlTable -Data $InactiveUsers -Title "Inactive User Accounts (90 Days)"
$htmlParts += ConvertTo-HtmlTable -Data $StaleComputers -Title "Inactive Computer Accounts (90 Days)"
$htmlParts += ConvertTo-HtmlTable -Data $InstalledFeatures -Title "Installed Windows Features"
$htmlParts += ConvertTo-HtmlTable -Data $ServiceResults -Title "Critical Services"
$htmlParts += ConvertTo-HtmlTable -Data $ReplicationResults -Title "Replication Review"
$htmlParts += ConvertTo-HtmlTable -Data $TimeResults -Title "Time Source Review"
$htmlParts += ConvertTo-HtmlTable -Data $ShareResults -Title "Shares Review"
$htmlParts += ConvertTo-HtmlTable -Data $DelegationResults -Title "Unconstrained Delegation Review"
$htmlParts += ConvertTo-HtmlTable -Data $PreAuthResults -Title "Kerberos Pre-Authentication Disabled"
$htmlParts += ConvertTo-HtmlTable -Data $SpnResults -Title "SPN-Enabled User Accounts"
$htmlParts += ConvertTo-HtmlTable -Data $AuditResults -Title "Audit Policy Review"
$htmlParts += ConvertTo-HtmlTable -Data $SecurityEvents -Title "Recent Security Events"
$htmlParts += ConvertTo-HtmlTable -Data $Results -Title "Complete Security Review Results"
$htmlParts += $rawHtml
$htmlParts += "<div class='footer'>Generated by Advanced AD Security Review Script | Email-ready HTML output for reporting and customer delivery.</div>"
$htmlParts += "</div></body></html>"

$html = $htmlParts -join "`r`n"
Set-Content -Path $ReportPath -Value $html -Encoding UTF8

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Review Complete." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Report saved to: $ReportPath" -ForegroundColor Cyan
Write-Host "Health Score: $HealthScore%" -ForegroundColor Cyan
Write-Host "Executive Indicator: $ExecutiveIndicator" -ForegroundColor Cyan

if ($OpenReport) {
    Start-Process $ReportPath
}

if ($SendEmail) {
    if ([string]::IsNullOrWhiteSpace($From) -or
        [string]::IsNullOrWhiteSpace($To) -or
        [string]::IsNullOrWhiteSpace($SmtpServer)) {
        Write-Warning "Email parameters missing. Provide -From, -To, and -SmtpServer to send the report."
    }
    else {
        if ([string]::IsNullOrWhiteSpace($Subject)) {
            $Subject = "AD Security Review Report - $DomainName - $ExecutiveIndicator - $HealthScore%"
        }

        $mailBody = @"
<html>
<body style='font-family:Segoe UI,Arial,sans-serif; color:#1f2937;'>
    <h2>Advanced Active Directory Security Review Report</h2>
    <p>Please find the attached AD security review report.</p>
    <p>
        <strong>Domain:</strong> $DomainName<br/>
        <strong>Generated:</strong> $Now<br/>
        <strong>Health Score:</strong> $HealthScore%<br/>
        <strong>Executive Indicator:</strong> $ExecutiveIndicator
    </p>
    <p>Regards,<br/>Vikas Singh<br/>Labs Hands On</p>
</body>
</html>
"@

        $sent = Send-ReportEmail -From $From -To $To -Cc $Cc -SmtpServer $SmtpServer -SmtpPort $SmtpPort -Subject $Subject -Body $mailBody -Attachment $ReportPath -UseSsl:$UseSsl
        if ($sent) {
            Write-Host "Email sent successfully." -ForegroundColor Green
        }
    }
}
