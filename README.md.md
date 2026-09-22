<div align="center">

# PowerShell Scripting and Automation

### Windows Administration | Active Directory | Microsoft Entra ID | Microsoft 365 | Infrastructure Automation

[![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![Windows](https://img.shields.io/badge/Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![Active Directory](https://img.shields.io/badge/Active%20Directory-0078D4?style=for-the-badge&logo=microsoft&logoColor=white)](https://learn.microsoft.com/windows-server/identity/ad-ds/)
[![Microsoft Entra ID](https://img.shields.io/badge/Microsoft%20Entra%20ID-5E5CE6?style=for-the-badge&logo=microsoft&logoColor=white)](https://www.microsoft.com/security/business/identity-access/microsoft-entra-id)
[![Microsoft 365](https://img.shields.io/badge/Microsoft%20365-D83B01?style=for-the-badge&logo=microsoft&logoColor=white)](https://www.microsoft.com/microsoft-365)
[![Hyper-V](https://img.shields.io/badge/Hyper--V-5C2D91?style=for-the-badge&logo=microsoft&logoColor=white)](https://learn.microsoft.com/windows-server/virtualization/hyper-v/)
[![Exchange](https://img.shields.io/badge/Exchange-0078D4?style=for-the-badge&logo=microsoft&logoColor=white)](https://learn.microsoft.com/exchange/)
[![Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue?style=for-the-badge)](./LICENSE)

<br>

**Practical PowerShell automation for real-world IT administration and infrastructure operations.**

</div>

---

## 📌 About This Repository

This repository is a practical collection of PowerShell scripts and automation work focused on **Windows administration, Active Directory, Microsoft Entra ID, Microsoft 365, and infrastructure management**.

The work covers both focused administrative scripts and larger automation workflows. The main goal is to reduce repetitive manual work, make administrative tasks repeatable, and provide clear ways to validate the result.

The repository demonstrates practical work across:

- Windows Server and workstation administration
- Active Directory user, group, OU, and computer management
- Microsoft Entra ID identity and access administration
- Microsoft 365 administration
- Exchange and mailbox management
- PowerShell remoting
- System health and event log investigation
- File, storage, and network administration
- Scheduled task and reporting automation
- Hyper-V and lab infrastructure

---

## 🚀 What This Repository Demonstrates

| Area | Practical Work |
|---|---|
| 💙 **PowerShell** | Scripting, automation, parameters, error handling, logging |
| 🏢 **Active Directory** | Users, groups, OUs, computer accounts, reporting, lifecycle tasks |
| ☁️ **Microsoft Entra ID** | User and group provisioning, reporting, access administration |
| 📧 **Microsoft 365** | Licensing, Exchange Online, Teams, SharePoint and tenant reporting |
| 🖥️ **Windows Administration** | Health checks, services, updates, event logs, local administrators |
| 🌐 **Networking** | DNS validation, connectivity checks, network share auditing |
| 💾 **File & Storage** | Disk monitoring, file operations, permissions, archiving |
| ⚙️ **Automation** | Scheduled tasks, reusable workflows, logging and notifications |
| 🖥️ **Hyper-V** | Virtual networking and infrastructure automation |

---

## 🏆 Project Highlights

### 00. Active Directory

📂 [Open project](./00.%20Active%20Directory/)

A dedicated Active Directory administration area covering common PowerShell tasks used to manage users, groups, OUs, computers, domain information, account lifecycle, and directory troubleshooting.

The focus is on practical administration commands that can be used in day-to-day Windows and Active Directory environments.

#### Active Directory Module

```powershell
Import-Module ActiveDirectory
```

#### 👤 User Management

```powershell
Get-ADUser -Identity "sam.smith"
Get-ADUser -Identity "sam.smith" -Properties *
Get-ADUser -Filter *
Get-ADUser -SearchBase "OU=Users,DC=corp,DC=example,DC=com" -Filter *

New-ADUser `
    -Name "Sam Smith" `
    -GivenName "Sam" `
    -Surname "Smith" `
    -SamAccountName "sam.smith" `
    -UserPrincipalName "sam.smith@corp.example.com" `
    -Path "OU=Users,DC=corp,DC=example,DC=com" `
    -Enabled $true

Set-ADUser -Identity "sam.smith" -Department "IT"
Set-ADUser -Identity "sam.smith" -Title "Systems Administrator"
Set-ADUser -Identity "sam.smith" -OfficePhone "+61 7 0000 0000"

Enable-ADAccount -Identity "sam.smith"
Disable-ADAccount -Identity "sam.smith"
Unlock-ADAccount -Identity "sam.smith"

$Password = Read-Host "Enter temporary password" -AsSecureString
Set-ADAccountPassword `
    -Identity "sam.smith" `
    -Reset `
    -NewPassword $Password

Set-ADUser `
    -Identity "sam.smith" `
    -ChangePasswordAtLogon $true

Search-ADAccount -LockedOut
Search-ADAccount -AccountDisabled
Search-ADAccount -PasswordExpired
Search-ADAccount -AccountInactive -TimeSpan 90.00:00:00
```

#### 👥 Group Management

```powershell
Get-ADGroup -Identity "IT-Users"
Get-ADGroup -Filter *
Get-ADGroupMember -Identity "IT-Users"

New-ADGroup `
    -Name "IT-Users" `
    -GroupScope Global `
    -GroupCategory Security

Add-ADGroupMember `
    -Identity "IT-Users" `
    -Members "sam.smith"

Remove-ADGroupMember `
    -Identity "IT-Users" `
    -Members "sam.smith" `
    -Confirm:$false

Get-ADPrincipalGroupMembership -Identity "sam.smith"
```

#### 🏷️ Organizational Unit Management

```powershell
Get-ADOrganizationalUnit -Filter *

Get-ADOrganizationalUnit `
    -Identity "OU=Users,DC=corp,DC=example,DC=com"

New-ADOrganizationalUnit `
    -Name "Users" `
    -Path "DC=corp,DC=example,DC=com"

New-ADOrganizationalUnit `
    -Name "IT" `
    -Path "OU=Users,DC=corp,DC=example,DC=com"

Set-ADOrganizationalUnit `
    -Identity "OU=IT,OU=Users,DC=corp,DC=example,DC=com" `
    -Description "IT Department"

Move-ADObject `
    -Identity "<ObjectDN>" `
    -TargetPath "OU=IT,OU=Users,DC=corp,DC=example,DC=com"

Remove-ADOrganizationalUnit `
    -Identity "OU=Test,DC=corp,DC=example,DC=com" `
    -Recursive
```

#### 💻 Computer Account Management

```powershell
Get-ADComputer -Identity "PC-001"
Get-ADComputer -Filter *
Get-ADComputer -Filter 'OperatingSystem -like "*Server*"'

New-ADComputer `
    -Name "PC-001" `
    -SamAccountName "PC-001$" `
    -Path "OU=Computers,DC=corp,DC=example,DC=com"

Set-ADComputer `
    -Identity "PC-001" `
    -Description "Finance workstation"

Move-ADObject `
    -Identity "CN=PC-001,OU=Computers,DC=corp,DC=example,DC=com" `
    -TargetPath "OU=Workstations,DC=corp,DC=example,DC=com"

Disable-ADAccount -Identity "PC-001$"
Enable-ADAccount -Identity "PC-001$"

Remove-ADComputer `
    -Identity "PC-001" `
    -Confirm:$false
```

#### 🌐 Domain and Domain Controller Information

```powershell
Get-ADDomain
Get-ADForest
Get-ADDomainController -Filter *
Get-ADDomainController -Discover

Get-ADDefaultDomainPasswordPolicy

Get-ADTrust -Filter *
Get-ADReplicationSite -Filter *
Get-ADReplicationSubnet -Filter *
```

#### 🔎 Directory Search and Object Management

```powershell
Get-ADObject -Filter *

Get-ADObject `
    -LDAPFilter "(objectClass=user)" `
    -SearchBase "DC=corp,DC=example,DC=com"

Get-ADObject -Identity "<ObjectDN>"

Move-ADObject `
    -Identity "<ObjectDN>" `
    -TargetPath "<TargetOU-DN>"

Rename-ADObject `
    -Identity "<ObjectDN>" `
    -NewName "New Name"
```

#### 🔄 Active Directory Replication and Health Checks

```powershell
Get-ADReplicationPartnerMetadata -Target * -Scope Domain

Get-ADReplicationFailure `
    -Target * `
    -Scope Site

Get-ADReplicationConnection -Filter *

Get-ADReplicationSite -Filter *
Get-ADReplicationSubnet -Filter *
```

#### 🔐 Group Policy and Directory Reporting

```powershell
Get-GPO -All

Get-GPResultantSetOfPolicy `
    -ReportType Html `
    -Path ".\RSOP.html"

Get-ADUser -Filter * |
    Select-Object Name,SamAccountName,Enabled,LastLogonDate |
    Export-Csv ".\ADUsers.csv" -NoTypeInformation

Get-ADComputer -Filter * |
    Select-Object Name,OperatingSystem,Enabled |
    Export-Csv ".\ADComputers.csv" -NoTypeInformation
```

#### Practical AD Administration Workflows

The project demonstrates common administrative workflows such as:

- User creation and onboarding
- User attribute updates
- Password resets and account unlocks
- User enable and disable operations
- Group creation and membership management
- OU creation and object placement
- Computer account management
- Domain and domain controller discovery
- Inactive and disabled account searches
- Directory reporting and CSV exports
- Replication and domain health checks
- Group Policy reporting
- Bulk administration through PowerShell

The commands above are examples of the administration building blocks used throughout the Active Directory work in this repository.

---

### 01. PowerShell AD, Entra ID and Microsoft 365 Scripts

📂 [Open project](./01.%20PowerShell-AD-EntraID-M365-Scripts/)

PowerShell automation for hybrid identity and Microsoft cloud administration.

**Active Directory**
- Bulk user creation and modification from CSV input
- OU creation and management
- Group membership reporting and bulk updates
- Stale account detection and automated account actions
- Password policy reporting and expiry notifications
- GPO documentation and export

**Microsoft Entra ID**
- User and group provisioning through Microsoft Graph
- App registration and service principal management
- Conditional Access reporting
- Guest user lifecycle management
- Sign-in log retrieval and analysis
- Role assignment auditing

**Microsoft 365**
- License assignment, removal and reporting
- Exchange Online mailbox management
- SharePoint Online reporting
- Teams provisioning and membership management
- MFA status reporting
- Inactive mailbox detection and archiving workflows

**Key PowerShell modules**
```text
ActiveDirectory
Microsoft.Graph
ExchangeOnlineManagement
MicrosoftTeams
MSOnline
```

---

### 02. PowerShell Scripting and Automation

📂 [Open project](./02.%20PowerShell-Scripting-and-Automation/)

A broader collection of Windows administration and infrastructure automation scripts.

**System Administration**
- Windows Server health checks and uptime reporting
- Installed software auditing
- Remote service management
- Windows Update status and patch compliance checks
- Event log collection and filtering
- Local administrator auditing

**File and Storage Management**
- Disk space monitoring with threshold alerts
- Bulk file rename, move and archive operations
- Folder permission auditing
- Large and duplicate file detection
- Log cleanup and archiving

**Networking and Connectivity**
- Ping sweep utilities
- Port checking utilities
- DNS lookup and validation
- Network share auditing
- Certificate expiry monitoring

**Scheduled Tasks and Reporting**
- Scheduled task templates
- Centralised logging
- Email notification wrappers
- Script execution history
- HTML and CSV reporting
- System inventory collection
- Environment documentation exports

---

## 🔎 Example Administrative Tasks

### Check Domain Membership

```powershell
Get-CimInstance Win32_ComputerSystem |
    Select-Object Name, Domain, PartOfDomain
```

### Join a Computer to Active Directory

```powershell
Add-Computer `
    -DomainName "corp.example.com" `
    -Server "DC01.corp.example.com" `
    -Credential (Get-Credential) `
    -Restart
```

### Enable PowerShell Remoting

```powershell
Enable-PSRemoting -Force
```

### Create an Active Directory User

```powershell
$Password = Read-Host "Enter temporary password" -AsSecureString

New-ADUser `
    -Name "Sam Smith" `
    -GivenName "Sam" `
    -Surname "Smith" `
    -DisplayName "Sam Smith" `
    -SamAccountName "sam.smith" `
    -UserPrincipalName "sam.smith@corp.example.com" `
    -Path "OU=Users,OU=Employee,DC=corp,DC=example,DC=com" `
    -AccountPassword $Password `
    -Enabled $true `
    -ChangePasswordAtLogon $true
```

### Add an AD User to a Group

```powershell
Add-ADGroupMember `
    -Identity "IT-Users" `
    -Members "sam.smith"
```

### Audit Local Administrators

```powershell
Get-LocalGroupMember -Group "Administrators"
```

### Collect Windows Errors

```powershell
Get-WinEvent -FilterHashtable @{
    LogName = "System"
    Level   = 2
} -MaxEvents 20
```

These examples are intentionally simple and representative. The project folders contain the broader automation work and reporting workflows.

---

## 🧠 Automation Approach

The scripts in this repository follow a practical administration pattern:

```text
Identify the task
       ↓
Check prerequisites
       ↓
Collect input and parameters
       ↓
Perform the operation
       ↓
Handle errors and log results
       ↓
Validate the final state
```

The focus is on automation that is:

- ✅ Repeatable
- ✅ Understandable
- ✅ Configurable
- ✅ Verifiable
- ✅ Safer to operate
- ✅ Suitable for extension and reuse

Where appropriate, scripts use features such as:

- `-WhatIf`
- Parameter validation
- Error handling
- Logging
- CSV input and output
- HTML reporting
- Credential prompts
- Verification commands

---

## 🔐 Administration and Security Practices

Administrative automation can make large changes quickly, so the scripts are designed around practical operational safeguards.

### Recommended workflow

```powershell
# Preview changes where supported
.\ScriptName.ps1 -WhatIf

# Review the output

# Run the change after validation
.\ScriptName.ps1
```

Additional practices include:

- Test changes in a lab before production use
- Use least privilege and delegated permissions where possible
- Do not hardcode passwords or secrets
- Review parameters before execution
- Check logs when troubleshooting
- Validate the final state after changes

---

## 🧰 Technology Stack

### Microsoft and Windows
- Windows 10 and 11
- Windows Server
- Active Directory Domain Services
- Microsoft Entra ID
- Microsoft 365
- Exchange Online
- Microsoft Teams
- SharePoint Online
- Hyper-V

### PowerShell and Modules
- PowerShell 5.1+
- PowerShell 7+
- `ActiveDirectory`
- `Microsoft.Graph`
- `ExchangeOnlineManagement`
- `MicrosoftTeams`
- `MSOnline`

---

## 📁 Repository Structure

```text
Powershell-Scripting-and-Automation/
│
├── 00. Active Directory/
│
├── 01. PowerShell-AD-EntraID-M365-Scripts/
│
├── 02. PowerShell-Scripting-and-Automation/
│
├── 03. Hyper V Manager/
│
├── 04. Entra ID and MS365/
│
├── 05. Magic/
│
├── LICENSE
└── README.md
```

### Folder Navigation

| Folder | Focus |
|---|---|
| 📁 [00. Active Directory](./00.%20Active%20Directory/) | Active Directory related work |
| 📁 [01. AD, Entra ID and M365 Scripts](./01.%20PowerShell-AD-EntraID-M365-Scripts/) | Identity and Microsoft 365 automation |
| 📁 [02. PowerShell Scripting and Automation](./02.%20PowerShell-Scripting-and-Automation/) | Windows administration and infrastructure automation |
| 📁 [03. Hyper V Manager](./03.%20Hyper%20V%20Manager/) | Hyper-V related work |
| 📁 [04. Entra ID and MS365](./04.%20Entra%20ID%20and%20MS365/) | Microsoft cloud administration |
| 📁 [05. Magic](./05.%20Magic/) | Additional PowerShell work and experiments |

---

## ⚙️ Getting Started

### Clone the repository

```powershell
git clone https://github.com/Sam-Subedi/Powershell-Scripting-and-Automation.git
cd Powershell-Scripting-and-Automation
```

### Check the PowerShell version

```powershell
$PSVersionTable.PSVersion
```

### Review the relevant script

Before execution, check:

- Required permissions
- Target computer, server or tenant
- Parameters
- OU paths and group names
- Required PowerShell modules
- Potential system or directory changes

### Install common modules when required

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module MicrosoftTeams -Scope CurrentUser
```

The required modules and permissions depend on the script being used.

---

## 📊 Why This Repository Exists

The purpose of this repository is to demonstrate how PowerShell can be used to turn common administration tasks into **repeatable, documented and verifiable automation**.

Instead of relying only on manual GUI administration, the scripts show how administrative workflows can be performed consistently through PowerShell across Windows, Active Directory and Microsoft cloud services.

---

## 📜 License

This repository is licensed under the **Apache License 2.0**.

See the [LICENSE](./LICENSE) file for the full license text.

---

## 👨‍💻 Author

**Sam Subedi**

PowerShell | Windows Administration | Active Directory | Microsoft Entra ID | Microsoft 365 | Infrastructure Automation

[![GitHub](https://img.shields.io/badge/GitHub-Sam--Subedi-181717?style=for-the-badge&logo=github)](https://github.com/Sam-Subedi)

---

<div align="center">

### ⚡ Automate repetitive work. Build reliable administrative workflows.

</div>
