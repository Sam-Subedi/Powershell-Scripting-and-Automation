<div align="center">

# PowerShell Scripting and Automation

### Windows Administration | Active Directory | Microsoft Entra ID | Microsoft 365 | Hyper-V | Windows Security

[![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![Windows Server](https://img.shields.io/badge/Windows%20Server-0078D4?style=for-the-badge&logo=windows&logoColor=white)](https://learn.microsoft.com/windows-server/)
[![Active Directory](https://img.shields.io/badge/Active%20Directory-0078D4?style=for-the-badge&logo=microsoft&logoColor=white)](https://learn.microsoft.com/windows-server/identity/ad-ds/)
[![Microsoft Entra ID](https://img.shields.io/badge/Microsoft%20Entra%20ID-5E5CE6?style=for-the-badge&logo=microsoft&logoColor=white)](https://www.microsoft.com/security/business/identity-access/microsoft-entra-id)
[![Microsoft 365](https://img.shields.io/badge/Microsoft%20365-D83B01?style=for-the-badge&logo=microsoft&logoColor=white)](https://www.microsoft.com/microsoft-365)
[![Hyper-V](https://img.shields.io/badge/Hyper--V-5C2D91?style=for-the-badge&logo=microsoft&logoColor=white)](https://learn.microsoft.com/windows-server/virtualization/hyper-v/)
[![Exchange](https://img.shields.io/badge/Exchange-0078D4?style=for-the-badge&logo=microsoft&logoColor=white)](https://learn.microsoft.com/exchange/)
[![Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue?style=for-the-badge)](./LICENSE)

**Practical PowerShell commands, scripts, and automation for Windows and Microsoft environments.**

</div>

---

## 📌 About This Repository

This repository is a practical PowerShell portfolio focused on **Windows administration, Active Directory, Microsoft Entra ID, Microsoft 365, Exchange, Hyper-V, and Windows security**.

It combines command references with reusable PowerShell scripts for common infrastructure, identity, endpoint, and security tasks. The repository is organized to show both day-to-day administration skills and larger automation workflows.

### What this repository demonstrates

- Active Directory user, group, OU, and computer administration
- Domain Controller deployment and Active Directory health checks
- Bulk user provisioning and directory automation
- Exchange Server and Exchange Online administration
- Microsoft Entra ID identity and group management
- Microsoft 365 licensing and tenant administration
- Microsoft Teams and SharePoint Online administration
- Intune and endpoint management
- Security, Defender, audit log, and sign-in investigation
- Hybrid identity and Entra Connect administration
- Windows local account, service, process, networking, and update management
- PowerShell remoting and remote administration
- Hyper-V networking, ACLs, VLANs, and NAT configuration

---

## 🏆 Repository Highlights

| Area | Practical Work |
|---|---|
| 🏢 **Active Directory** | Users, groups, OUs, computers, domain discovery, account lifecycle, replication, FSMO roles |
| ⚙️ **AD DS Automation** | AD DS installation, Domain Controller promotion, DNS configuration, automated deployment |
| 📧 **Exchange** | Exchange Server 2019 deployment, mailbox enablement, Exchange Online permissions |
| ☁️ **Entra ID** | Users, groups, authentication methods, licensing, security alerts, audit logs |
| 🔄 **Hybrid Identity** | On-premises AD, Entra Connect, Delta sync, Initial sync |
| 🧰 **Windows Administration** | Local users, services, scheduled tasks, updates, WinRM, Defender |
| 🖥️ **Hyper-V** | Virtual switches, VLANs, ACLs, HNS networking, VM networking, NAT |
| 🔐 **Windows Security** | Defender controls, connectivity checks, WinRM, event logs, system administration |
| 📊 **Reporting & Automation** | CSV workflows, transcripts, exports, tenant reports, remote execution |

---

# 📂 Repository Structure

```text
Powershell-Scripting-and-Automation/
│
├── 00. Active Directory/
│   ├── 01. Active Directory User, Group and Computer Management.txt
│   └── 02. System Administrator PowerShell Commands.txt
│
├── 01. AD and Exchange Server Automation/
│   ├── 01. ADDS Installation PowerShell Script.ps1
│   ├── 02. ADDS Installation Fully Automated PowerShell Script.ps1
│   ├── 03. Bulk User Creation and Enable user Mailbox.ps1
│   ├── 04. Forceful Deletion and Removal of OU in AD.ps1
│   ├── 05. Exchange Server 2019 Deployment Script with All Prerequisite Files on Windows Server 2022.ps1
│   ├── 06. AD Bulk User Deployment.txt
│   ├── 07. AD Replication and Health Check Commands.txt
│   ├── 08. Upgrade Active Directory to Windows Server 2025.txt
│   └── 09. CSV File Format Sample.txt
│
├── 02. PowerShell AD EntraID M365 Scripts/
│   ├── 01 to 34 numbered PowerShell scripts
│   └── AD, Microsoft 365, DNS, Windows, security, remoting and reporting tasks
│
├── 03. Entra ID and MS365 PowerShell Scripts/
│   ├── 01. Authentication & Service Connection
│   ├── 02. Identity & User Management
│   ├── 03. Password & Authentication Methods
│   ├── 04. Group Management (Entra ID)
│   ├── 05. Licensing Management
│   ├── 06. Exchange Online Management
│   ├── 07. Microsoft Teams & SharePoint Online
│   ├── 08. Intune & Endpoint Management
│   ├── 09. Security, Defender & Audit Logs
│   ├── 10. Hybrid Identity (Active Directory & Entra Connect)
│   └── 11. System Administration, Reporting & Automation
│
├── 04. Hyper V Management PowerShell Commands/
│   ├── 01. Powershell Cmdlets
│   ├── 02. Powershell Cmdlets
│   ├── 03. Hyper-V ACLs.txt
│   └── 04. Hyper-V Internal Switch NAT Configuration.ps1
│
├── 05. Windows Security/
│   ├── 00. PowerShell Commands and Tricks.txt
│   └── 01. Windows PC Administration and Security PowerShell Cmdlets.txt
│
├── LICENSE
└── README.md
```

---

# 🏢 00. Active Directory

📂 [Open Active Directory](./00.%20Active%20Directory/)

This section is a practical reference for day-to-day Active Directory and Windows administration.

### Active Directory coverage

- Domain and forest discovery
- Domain Controller discovery
- OU creation, modification, movement, and removal
- User creation and attribute management
- Account enable, disable, unlock, password reset, and expiration
- Group creation and membership management
- Nested group membership
- Computer account management
- Domain join and computer rename
- Local user and local group management
- Remote Desktop administration
- PowerShell remoting
- Basic domain policy administration

### Common Active Directory commands

```powershell
Import-Module ActiveDirectory

Get-ADDomain
Get-ADForest
Get-ADDomainController -Filter *

Get-ADOrganizationalUnit -Filter *

New-ADOrganizationalUnit `
    -Name "IT" `
    -Path "DC=corp,DC=example,DC=com"

Get-ADUser -Identity "sam.smith" -Properties *

New-ADUser `
    -Name "Sam Smith" `
    -SamAccountName "sam.smith" `
    -UserPrincipalName "sam.smith@corp.example.com" `
    -Enabled $true

Set-ADUser -Identity "sam.smith" -Department "IT"
Enable-ADAccount -Identity "sam.smith"
Disable-ADAccount -Identity "sam.smith"
Unlock-ADAccount -Identity "sam.smith"

Get-ADGroup -Filter *
Get-ADGroupMember -Identity "IT-Users"

Add-ADGroupMember `
    -Identity "IT-Users" `
    -Members "sam.smith"

Get-ADPrincipalGroupMembership -Identity "sam.smith"

Get-ADComputer -Filter *

Set-ADComputer `
    -Identity "PC-001" `
    -Description "Finance workstation"

Search-ADAccount -LockedOut
Search-ADAccount -AccountDisabled
Search-ADAccount -PasswordExpired
```

### Directory administration

```powershell
Move-ADObject `
    -Identity "<ObjectDN>" `
    -TargetPath "<TargetOU-DN>"

Rename-ADObject `
    -Identity "<ObjectDN>" `
    -NewName "New Name"

Remove-ADUser -Identity "sam.smith"

Remove-ADComputer `
    -Identity "PC-001" `
    -Confirm:$false
```

The two reference files in this section provide a broader set of Active Directory, local Windows, Remote Desktop, remoting, and system administration commands.

---

# ⚙️ 01. AD and Exchange Server Automation

📂 [Open AD and Exchange automation](./01.%20AD%20and%20Exchange%20Server%20Automation/)

This section contains the larger infrastructure automation work in the repository.

### AD DS deployment

The repository contains both a standard AD DS installation script and a fully automated deployment workflow.

```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

Install-ADDSForest `
    -DomainName "abc.com" `
    -CreateDnsDelegation:$false
```

The fully automated workflow also covers:

- Server renaming
- Restart and staged execution
- Static IP configuration
- DNS configuration
- AD DS role installation
- Domain Controller promotion

### Bulk user provisioning

The automation covers:

- Employee and department OU structure
- Department security groups
- CSV-based user creation
- Group membership assignment
- Mailbox enablement

Common commands include:

```powershell
New-ADOrganizationalUnit
New-ADGroup
New-ADUser
Add-ADGroupMember
Enable-Mailbox
```

### AD cleanup

The repository includes a dedicated script for controlled cleanup and removal of an OU and contained directory objects.

```powershell
Remove-ADUser
Remove-ADGroup
Set-ADOrganizationalUnit
Remove-ADOrganizationalUnit
```

### Exchange Server 2019

The repository includes a large Exchange Server 2019 deployment script for Windows Server 2022, covering prerequisite preparation, installation workflow, logging, and mailbox database preparation.

### AD replication and health checks

The repository documents practical Domain Controller diagnostics:

```text
dcdiag
dcdiag /v
dcdiag /test:dns
dcdiag /test:replications

repadmin /replsummary
repadmin /showrepl
repadmin /syncall
```

### Active Directory upgrade work

The repository also includes a documented Active Directory upgrade workflow for Windows Server 2025.

Examples include:

```powershell
Get-ADObject (Get-ADRootDSE).schemaNamingContext -Property objectVersion

Get-ADDomainController -Filter *

Get-ADReplicationPartnerMetadata -Target *
Get-ADReplicationFailure -Target *

Resolve-DnsName

Invoke-Command

Install-ADDSDomainController

Move-ADDirectoryServerOperationMasterRole

Set-ADDomainMode
Set-ADForestMode
Enable-ADOptionalFeature
```

---

# 🧰 02. PowerShell AD EntraID M365 Scripts

📂 [Open the 34-script automation collection](./02.%20PowerShell%20AD%20EntraID%20M365%20Scripts/)

This folder contains **34 numbered PowerShell scripts** covering Active Directory, Microsoft 365, Windows administration, DNS, networking, security, remoting, reporting, and file administration.

### Active Directory and identity automation

```text
03-Create-AD-Users-from-CSV.ps1
04-Create-AD-Groups-from-CSV.ps1
05-Find-Inactive-AD-Users-and-Computers.ps1
06-List-and-Move-AD-Computers.ps1
09-Get-AD-User-LastLogon-All-DCs.ps1
10-Bulk-Update-AD-User-Attributes.ps1
14-Show-Nested-AD-Group-Memberships.ps1
17-Join-Computer-to-AD-Domain.ps1
18-Copy-AD-Group-Members-Source-to-Dest.ps1
19-Resolve-SID-to-AD-Object.ps1
20-Export-All-AD-Objects-MultiDomain.ps1
25-Look-Up-AD-User-Details-by-Email.ps1
26-List-AD-Users-Created-in-Last-N-Days.ps1
29-Grant-Temporary-AD-Group-Membership.ps1
30-List-DCs-and-FSMO-Roles.ps1
31-Fix-Domain-Trust-Relationship.ps1
32-Migrate-AD-Users-to-New-Domain.ps1
34-Find-Inactive-AD-Computers.ps1
```

### Windows administration and remote management

```text
11-Manage-Local-Windows-Users.ps1
12-Migrate-User-Profile-with-Robocopy.ps1
15-Get-Services-on-Remote-Computers.ps1
23-Setup-Custom-Local-Admin-Account.ps1
24-Run-Commands-Remotely-on-Domain-Computers.ps1
27-Get-All-Microsoft-Updates-Installed.ps1
```

### Networking, DNS, files and permissions

```text
07-Find-Duplicate-IPs-in-DNS.ps1
08-Create-Folders-from-CSV.ps1
16-Assign-NTFS-Permissions-on-Shared-Resources.ps1
21-Move-Files-by-Extension-Recursively.ps1
28-Get-IP-Address-and-Hostname-from-AD-DNS.ps1
```

### Security and credential-related tasks

```text
13-Encrypt-Decrypt-Script-Passwords.ps1
22-Check-and-Control-Windows-Defender.ps1
```

### Microsoft 365

```text
01-Assign-M365-Licenses-from-CSV.ps1
02-Manage-ExchangeOnline-Mailbox-Permissions.ps1
33-M365-Tenant-Information-Report.ps1
```

This collection demonstrates practical scripting for repetitive administration, reporting, troubleshooting, and operational tasks across Windows and Microsoft environments.

---

# ☁️ 03. Entra ID and Microsoft 365 PowerShell Scripts

📂 [Open Entra ID and Microsoft 365](./03.%20Entra%20ID%20and%20MS365%20PowerShell%20Scripts/)

This section is organized into **11 administration areas**.

| Section | Focus |
|---|---|
| 01 | Authentication and service connections |
| 02 | Identity and user management |
| 03 | Passwords and authentication methods |
| 04 | Entra ID group management |
| 05 | Licensing management |
| 06 | Exchange Online |
| 07 | Microsoft Teams and SharePoint Online |
| 08 | Intune and endpoint management |
| 09 | Security, Defender and audit logs |
| 10 | Hybrid identity and Entra Connect |
| 11 | System administration, reporting and automation |

### Authentication and service connections

```powershell
Connect-MgGraph -Scopes `
    "User.ReadWrite.All",
    "Group.ReadWrite.All",
    "Directory.ReadWrite.All"

Connect-ExchangeOnline
Connect-MicrosoftTeams

Connect-SPOService `
    -Url "https://<tenant>-admin.sharepoint.com"

Disconnect-MgGraph
```

### Entra ID users

```powershell
Get-MgUser -UserId "user@domain.com"

Get-MgUser `
    -All `
    -Property "displayName,userPrincipalName,accountEnabled"

New-MgUser

Update-MgUser `
    -UserId "user@domain.com" `
    -Department "IT" `
    -JobTitle "Systems Administrator"

Get-MgUserManager -UserId "user@domain.com"
Get-MgUserMemberOf -UserId "user@domain.com"
```

### Authentication methods

```powershell
Get-MgUserAuthenticationMethod `
    -UserId "user@domain.com"

Remove-MgUserAuthenticationMethod `
    -UserId "user@domain.com" `
    -AuthenticationMethodId "<MethodID>"
```

### Groups and licensing

```powershell
Get-MgGroup -All

New-MgGroup `
    -DisplayName "Sec-Engineering" `
    -MailEnabled:$false `
    -SecurityEnabled:$true `
    -MailNickname "sec-eng"

Get-MgGroupMember `
    -GroupId "<GroupID>" `
    -All

Get-MgSubscribedSku

Set-MgUserLicense `
    -UserId "user@domain.com" `
    -AddLicenses @{SkuId = $Sku.SkuId} `
    -RemoveLicenses @()
```

### Exchange Online

```powershell
Connect-ExchangeOnline

Get-Mailbox `
    -ResultSize Unlimited `
    -RecipientTypeDetails UserMailbox

Get-MailboxStatistics `
    -Identity "user@domain.com"

Get-MailboxPermission `
    -Identity "shared@domain.com"

Add-MailboxPermission `
    -Identity "shared@domain.com" `
    -User "user@domain.com" `
    -AccessRights FullAccess `
    -AutoMapping $true

Get-DistributionGroup -ResultSize Unlimited
Add-DistributionGroupMember
Get-TransportRule
New-TransportRule
```

### Teams and SharePoint Online

```powershell
Connect-MicrosoftTeams

Get-Team
Get-TeamUser -GroupId "<GroupID>"

Add-TeamUser `
    -GroupId "<GroupID>" `
    -User "user@domain.com" `
    -Role "Member"

Connect-SPOService `
    -Url "https://<tenant>-admin.sharepoint.com"

Get-SPOSite -Detailed
Get-SPOUser -Site "https://<tenant>.sharepoint.com/sites/sitename"
Set-SPOSite
```

### Intune and endpoint management

```powershell
Get-MgDeviceManagementManagedDevice -All
Get-MgDeviceManagementDeviceCompliancePolicy -All
Get-MgDeviceManagementDeviceConfiguration -All
Get-MgDeviceManagementDetectedApp -All

Invoke-MgGraphRequest `
    -Method GET `
    -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices"
```

### Security and auditing

```powershell
Get-MgSecurityAlert -Top 20
Get-MgSecurityIncident -Top 10
Get-MgAuditLogSignIn -Top 50
Get-MgAuditLogDirectoryAudit -Top 50

Search-UnifiedAuditLog `
    -StartDate (Get-Date).AddDays(-7) `
    -EndDate (Get-Date) `
    -ResultSize 100
```

### Hybrid identity

```powershell
Get-ADUser -Identity "username" -Properties *
Get-ADGroupMember -Identity "Domain Admins"

Start-ADSyncSyncCycle -PolicyType Delta
Start-ADSyncSyncCycle -PolicyType Initial
```

### Reporting and remote administration

```powershell
Start-Transcript `
    -Path "C:\Logs\PowerShellSession.log"

Get-MgUser -All |
    Select-Object DisplayName, UserPrincipalName, Department |
    Export-Csv `
        -Path "C:\Reports\Users.csv" `
        -NoTypeInformation

Invoke-Command `
    -ComputerName "Server01" `
    -ScriptBlock { Get-Service -Name "Spooler" }

New-PSSession -ComputerName "Server01"

Test-NetConnection `
    -ComputerName "outlook.office365.com" `
    -Port 443

Get-WinEvent -FilterHashtable @{
    LogName = "System"
    Level   = 2
} -MaxEvents 20
```

---

# 🖥️ 04. Hyper-V Management PowerShell Commands

📂 [Open Hyper-V section](./04.%20Hyper%20V%20Management%20PowerShell%20Commands/)

This section focuses on Hyper-V administration and virtual networking.

### Hyper-V networking

```powershell
Get-VMSwitch
Get-VMNetworkAdapter -All
Get-VMNetworkAdapterVlan -VMName "VMName"

Get-NetAdapter
Get-NetIPAddress
Get-NetNat

Test-NetConnection 192.168.10.1 -Port 4444

Set-VMNetworkAdapterVlan `
    -VMName "Windows 10 (PC1)" `
    -Access `
    -VlanId 20
```

### Host Networking Service

```powershell
Get-NetIPConfiguration
Get-HnsNetwork | Format-List *
Get-HnsEndpoint | Format-List *

Get-VMProcessor -VMName "GNS3 VM" |
    Select-Object ExposeVirtualizationExtensions

Set-VMProcessor `
    -VMName "GNS3 VM" `
    -ExposeVirtualizationExtensions $true
```

### Hyper-V ACLs and segmentation

```powershell
Get-VM | Get-VMNetworkAdapterExtendedAcl

Add-VMNetworkAdapterAcl `
    -VMName "Your AD VM" `
    -RemoteIPAddress "192.168.2.0/24" `
    -Direction Inbound `
    -Action Deny

Add-VMNetworkAdapterAcl `
    -VMName "Your AD VM" `
    -RemoteIPAddress "192.168.2.50" `
    -Direction Inbound `
    -Action Allow
```

### Internal Switch and NAT

```powershell
New-VMSwitch `
    -Name "Internal Switch" `
    -SwitchType Internal

New-NetIPAddress `
    -IPAddress "192.168.1.1" `
    -PrefixLength 24 `
    -InterfaceAlias "vEthernet (Internal Switch)"

New-NetNat `
    -Name "Internal Switch NAT" `
    -InternalIPInterfaceAddressPrefix "192.168.1.0/24"
```

The section also includes VM checkpoints, Sysprep commands, VLAN configuration, and Hyper-V network inspection.

---

# 🔐 05. Windows Security

📂 [Open Windows Security](./05.%20Windows%20Security/)

This section contains Windows administration, security, troubleshooting, networking, and PowerShell command references.

### Connectivity and networking

```powershell
Test-NetConnection google.com -Port 443
Test-NetConnection google.com -TraceRoute

Test-Connection google.com -Count 10

Get-NetIPConfiguration
Get-NetIPAddress
Get-NetTCPConnection
```

### Local Windows administration

```powershell
Get-LocalUser
Get-LocalGroup
Get-LocalGroupMember -Group "Administrators"

Get-ComputerInfo
Get-Service
Get-Process
Get-ScheduledTask
```

### PowerShell remoting and WinRM

```powershell
Enable-PSRemoting -Force

Get-Service WinRM

Test-WSMan

Enter-PSSession `
    -ComputerName "Server01"
```

### Updates and Windows features

```powershell
Get-HotFix

Get-WindowsOptionalFeature `
    -Online
```

The command references also include file inspection, service filtering, clipboard operations, networking checks, and other useful PowerShell administration techniques.

---

# 🔄 Common Administration Workflow

The repository follows a practical automation approach:

```text
Identify the task
       ↓
Check the current state
       ↓
Collect input and parameters
       ↓
Perform the change
       ↓
Handle errors and record output
       ↓
Validate the final state
```

For example:

```powershell
# Check current state
Get-CimInstance Win32_ComputerSystem |
    Select-Object Name, Domain, PartOfDomain

# Perform the domain join
Add-Computer `
    -DomainName "corp.example.com" `
    -Server "DC01.corp.example.com" `
    -Credential (Get-Credential) `
    -Restart

# Validate after restart
Get-CimInstance Win32_ComputerSystem |
    Select-Object Name, Domain, PartOfDomain
```

This pattern is used throughout the repository for identity, endpoint, Windows, Microsoft 365, and infrastructure tasks.

---

# 🔐 Administration and Security Practices

These scripts are intended for learning, lab environments, and controlled administrative use.

Recommended practices:

- Test scripts in a lab before production use
- Use least privilege
- Review parameters before execution
- Never commit real passwords, tokens, API keys, or other secrets
- Use `-WhatIf` where the cmdlet supports it
- Log important administrative operations
- Validate changes after execution
- Treat destructive operations such as OU deletion, account removal, and ACL changes carefully

---

# 🚀 Getting Started

### Clone the repository

```powershell
git clone https://github.com/Sam-Subedi/Powershell-Scripting-and-Automation.git
cd Powershell-Scripting-and-Automation
```

### Check the PowerShell version

```powershell
$PSVersionTable.PSVersion
```

### Load the Active Directory module when required

```powershell
Import-Module ActiveDirectory
```

### Install common Microsoft 365 modules when required

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module MicrosoftTeams -Scope CurrentUser
```

The required modules and permissions depend on the script being used.

---

# 📊 Technology Areas

| Technology | Areas Covered |
|---|---|
| **PowerShell** | Commands, scripting, automation, remoting, reporting |
| **Active Directory** | Users, groups, OUs, computers, DCs, replication, FSMO |
| **AD DS** | Installation, promotion, deployment, upgrades |
| **Exchange Server** | Deployment, prerequisites, mailbox management |
| **Exchange Online** | Mailboxes, permissions, transport rules |
| **Microsoft Entra ID** | Users, groups, authentication, licensing |
| **Microsoft Graph** | Identity, Intune, security, audit and reporting |
| **Microsoft 365** | Licensing, Exchange, Teams, SharePoint |
| **Intune** | Devices, compliance, configuration, software inventory |
| **Hyper-V** | Switches, VLANs, ACLs, NAT, VM networking |
| **Windows Security** | Defender, WinRM, services, updates, event logs |

---

# 📜 License

This repository is licensed under the **Apache License 2.0**.

See the [LICENSE](./LICENSE) file for the full license text.

---

# 👨‍💻 Author

**Sam Subedi**

PowerShell | Windows Administration | Active Directory | Microsoft Entra ID | Microsoft 365 | Infrastructure Automation

[![GitHub](https://img.shields.io/badge/GitHub-Sam--Subedi-181717?style=for-the-badge&logo=github)](https://github.com/Sam-Subedi)

<div align="center">

### ⚡ Automate repetitive work. Build reliable administrative workflows.

</div>
