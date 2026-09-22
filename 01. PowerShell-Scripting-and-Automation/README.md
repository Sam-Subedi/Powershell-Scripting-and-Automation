# 🚀 PowerShell Scripting and Automation

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=flat-square&logo=powershell)
![Active Directory](https://img.shields.io/badge/Active%20Directory-ADDS-0078D4?style=flat-square&logo=windows)
![Automation](https://img.shields.io/badge/Automation-Enterprise%20Grade-FF6B35?style=flat-square)
![Exchange Server](https://img.shields.io/badge/Exchange%20Server-2019-0078D4?style=flat-square&logo=microsoft)
![Hyper-V](https://img.shields.io/badge/Hyper--V-Network%20Config-5391FE?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

> A comprehensive collection of production-ready PowerShell scripts for enterprise automation. Automate Active Directory management, Exchange Server deployment, user provisioning, and Hyper-V network configuration with minimal manual effort.



## 📋 Table of Contents

- [The Challenge](#-the-challenge)
- [What This Project Provides](#-what-this-project-provides)
- [Script Collection](#-script-collection)
- [Active Directory Scripts](#-active-directory-scripts)
- [Exchange Server Scripts](#-exchange-server-scripts)
- [User Management Scripts](#-user-management-scripts)
- [Hyper-V Scripts](#-hyper-v-scripts)
- [Key Features](#-key-features)
- [Getting Started](#-getting-started)
- [Installation Requirements](#-installation-requirements)
- [Script Usage Guide](#-script-usage-guide)
- [Best Practices](#-best-practices)
- [Troubleshooting](#-troubleshooting)
- [Conclusion](#-conclusion)



## 🚨 The Challenge

Enterprise IT administration requires managing:

**Manual Administration Pain Points:**
- Creating hundreds of users one-by-one is extremely time-consuming
- Active Directory structure is inconsistent across deployments
- Mailbox provisioning requires multiple manual steps
- Network configuration is often error-prone and undocumented
- Organizational unit management is repetitive and manual
- Group membership management lacks automation
- User onboarding/offboarding is a lengthy process

**The Impact:**
- Onboarding a single user: 30-45 minutes manually
- Bulk user creation: Weeks or months of manual work
- Error rate: 10-15% due to manual configuration
- Inconsistent security policies across infrastructure
- No audit trail for compliance requirements
- Staff spending time on repetitive tasks instead of strategic work

**The Solution:** A comprehensive collection of PowerShell scripts that automate the entire enterprise infrastructure lifecycle.



## 📦 What This Project Provides

This repository contains **7 production-ready PowerShell scripts** for comprehensive IT automation:

| Script | Purpose | Time Saved |
|--------|---------|-----------|
| **ADDS Installation (Full)** | Fully automated Active Directory Domain Services installation | 2-3 hours |
| **ADDS Installation** | Streamlined ADDS deployment script | 1-2 hours |
| **Bulk User Creation** | Create 100s of users with mailboxes from CSV | 20-30 hours |
| **Exchange 2019 Deployment** | Complete Exchange Server 2019 with prerequisites | 4-8 hours |
| **OU Deletion** | Forceful deletion and removal of OUs | 30 minutes per OU |
| **Hyper-V NAT Setup** | Internal switch NAT setup with connectivity test | 20 minutes |
| **README Documentation** | Complete guide and best practices | N/A |

**Total Automation Value:** Save 40-50 hours of manual work for infrastructure deployment and 50+ hours for bulk user creation.



## 💻 Script Collection

### 1. ADDS Installation: Fully Automated PowerShell Script

**File:** `ADDS Installation Fully Automated Powershell Script.ps1`

**Purpose:** Completely automate Active Directory Domain Services installation on Windows Server

**What It Does:**
- Pre-flight validation (domain-joined check, prerequisites)
- Automatic Windows Feature installation (AD-Domain-Services, DNS, RSAT)
- Forest and domain creation
- Administrator account configuration
- Global Catalog setup
- DNS configuration
- Automatic reboot handling
- Complete logging and audit trail

**Best For:**
- New forest and domain creation
- Lab and test environments
- Disaster recovery scenarios
- Greenfield deployments

**Time Saved:** 2-3 hours vs. manual installation

**Typical Execution:** 15-25 minutes (including reboots)

---

### 2. ADDS Installation Powershell Script

**File:** `ADDS Installation Powershell Script.ps1`

**Purpose:** Streamlined ADDS installation for experienced administrators

**What It Does:**
- Validates prerequisites
- Installs required Windows features
- Creates forest/domain with minimal prompts
- Configures basic settings
- Handles automatic restart

**Best For:**
- Organizations familiar with AD deployments
- Non-critical environments
- Quick testing and prototyping

**Time Saved:** 1-2 hours vs. manual installation

---

### 3. Bulk User Creation and Exchange Mailbox Enablement

**File:** `Bulk User Creation and enable user Mailbox.ps1`

**Purpose:** Create hundreds of users from CSV with complete AD configuration and Exchange integration

**What It Does:**
- Imports users from CSV file
- Creates Employee OU structure (if missing)
- Creates department OUs and sub-OUs
- Creates security groups per department
- Creates individual users in correct OUs
- Assigns home drives (H:)
- Configures roaming profiles
- Forces password change at first logon
- Adds users to department security groups
- Optionally creates Exchange mailbox databases
- Optionally enables mailboxes for all users
- Complete audit logging

**CSV Structure:**
```
FirstName,LastName,FullName,Gender,Role,OU
John,Doe,John Doe,Male,Engineer,IT
Jane,Smith,Jane Smith,Female,Manager,Finance
```

**Best For:**
- Bulk user provisioning from HR systems
- New department onboarding
- Organizational migrations
- Lab and test environment setup

**Time Saved:** 20-30 hours for creating 100+ users with mailboxes

**Typical Execution:** 2-5 minutes for 100 users (excluding Exchange mailbox creation)

---

### 4. Exchange Server 2019 Deployment Script with All Prerequisites

**File:** `Exchange Server 2019 Deployment Script with All Prerequisite Files on Windows Server 2022.ps1`

**Purpose:** Fully automated Exchange Server 2019 installation with bundled prerequisites

**What It Does:**
- Validates Active Directory readiness
- Installs all Windows prerequisites
- Installs required .NET Framework
- Installs Visual C++ runtimes
- Configures Windows features
- Downloads and installs Exchange Server 2019 CU15
- Applies post-installation configuration
- Creates initial mailbox database
- Complete logging and validation

**Best For:**
- Air-gapped environments
- Organizations with restricted internet access
- Greenfield Exchange deployments
- Disaster recovery

**Time Saved:** 4-8 hours vs. manual installation

**Typical Execution:** 30-45 minutes (depends on server performance)

---

### 5. Forceful Deletion and Removal of OU in AD

**File:** `Forceful Deletion and Removal of OU in AD.ps1`

**Purpose:** Remove organizational units and all contents with force option

**What It Does:**
- Checks OU existence
- Removes OU protection flag (if enabled)
- Removes all child objects (users, groups, OUs)
- Option for recursive deletion
- Complete logging of deleted objects
- Verification of removal

**Best For:**
- Cleaning up test OUs
- Restructuring Active Directory
- Lab environment cleanup
- Departmental deprovisioning

**Time Saved:** 30 minutes per OU vs. manual deletion through GUI

**Typical Execution:** 1-2 minutes per OU

---

### 6. Hyper-V Internal Switch NAT Setup Script with Connectivity Test

**File:** `Hyper-V Internal Switch NAT Setup Script with Connectivity Test.ps1`

**Purpose:** Automate Hyper-V internal switch creation with NAT configuration and connectivity testing

**What It Does:**
- Creates internal virtual switch
- Configures NAT network address translation
- Assigns IP to Hyper-V host vNIC
- Creates NAT rules for port forwarding (optional)
- Tests connectivity between VMs
- Validates network configuration
- Provides troubleshooting output

**Best For:**
- Lab network setup automation
- Test environment provisioning
- Hyper-V cluster configuration
- Network isolation scenarios

**Time Saved:** 20 minutes vs. manual GUI configuration

**Typical Execution:** 2-3 minutes

---

### 7. README and Documentation

**File:** `README.md`

**Purpose:** Complete documentation and best practices guide

**Contents:**
- Project overview
- Script descriptions
- Installation requirements
- Usage examples
- CSV file format
- Best practices
- Troubleshooting tips
- Security recommendations



## 🔧 Active Directory Scripts

### ADDS Installation: Complete Automated Workflow

**Pre-Deployment Requirements:**
```
✓ Windows Server 2016/2019/2022/2025 installed
✓ Static IP address configured
✓ Server name set
✓ Sufficient disk space (50GB+ recommended)
✓ Administrator credentials available
```

**Automated Steps:**
```
1. Validate prerequisites (CPU, RAM, disk space)
2. Install Active Directory Domain Services feature
3. Install DNS Server (required for AD)
4. Install Remote Server Administration Tools (RSAT)
5. Create forest and root domain
6. Configure DNS zones and records
7. Setup Global Catalog replication
8. Create Administrator account
9. Configure replication partners
10. Restart and apply final configuration
```

**Post-Installation Verification:**
```powershell
# Verify AD installation
Get-ADDomain
Get-ADForest
Get-ADDomainController

# Test DNS resolution
nslookup domain.com
```

---

### Organizational Unit Structure

The bulk user creation script creates a professional, scalable AD structure:

```
DC=domain,DC=com
│
└── OU=Employee
    │
    ├── OU=Sales
    │   ├── OU=Users (contains all Sales users)
    │   └── OU=Groups (contains Sales Group)
    │
    ├── OU=IT
    │   ├── OU=Users (contains all IT users)
    │   └── OU=Groups (contains IT Group)
    │
    ├── OU=Finance
    │   ├── OU=Users (contains all Finance users)
    │   └── OU=Groups (contains Finance Group)
    │
    ├── OU=Marketing
    │   ├── OU=Users (contains all Marketing users)
    │   └── OU=Groups (contains Marketing Group)
    │
    └── OU=Accounting
        ├── OU=Users (contains all Accounting users)
        └── OU=Groups (contains Accounting Group)
```

**Benefits of This Structure:**
- Clear organizational hierarchy
- Scalable for new departments
- Granular Group Policy application
- Efficient permission management
- Easy delegation of administrative tasks
- Audit trail and compliance support



## 📧 Exchange Server Scripts

### Exchange 2019 Deployment: Complete Automation

**Supported Windows Servers:**
- Windows Server 2016 (TLS 1.2 only)
- Windows Server 2019 (TLS 1.2 only)
- Windows Server 2022 (TLS 1.2 and 1.3)
- Windows Server 2025 (TLS 1.2 and 1.3)

**Automated Components:**
```
1. AD Schema Validation (must be updated for Exchange 2019)
2. Windows Feature Installation (IIS, .NET, RSAT, etc.)
3. Visual C++ Runtime Installation (2013, 2015-2019, 2022)
4. TLS Configuration (1.2 and 1.3 where supported)
5. Performance Optimization (power plan, pagefile)
6. Exchange ISO Download and Verification
7. Silent Mailbox Role Installation
8. Post-Installation Configuration
9. Mailbox Database Creation
10. Service Health Verification
```

**Mailbox Database Creation:**
```powershell
# Script can create multiple databases
# DB1, DB2, ... DB50 with specified paths
# Example database configuration:
# Database Name: Mailbox Database 01
# EDB Path: E:\ExchangeDB\DB01\DB01.edb
# Log Path: E:\ExchangeLogs\DB01\
# Transaction Log Path: E:\ExchangeLogs\DB01\
```

**Post-Installation Steps:**
```powershell
# Mount databases
Mount-Database -Identity "Mailbox Database 01"

# Create test mailbox
New-Mailbox -UserPrincipalName user@domain.com -Database "Mailbox Database 01"

# Test send/receive
Send-TestMailMessage -RecipientAddress user@domain.com
```



## 👥 User Management Scripts

### Bulk User Creation: Complete Workflow

**CSV File Requirements:**

```csv
FirstName,LastName,FullName,Gender,Role,OU
John,Doe,John Doe,Male,Engineer,IT
Jane,Smith,Jane Smith,Female,Manager,Finance
Bob,Johnson,Bob Johnson,Male,Analyst,Finance
Alice,Williams,Alice Williams,Female,Developer,IT
```

**Column Descriptions:**
- `FirstName`: User's first name
- `LastName`: User's last name
- `FullName`: Complete display name
- `Gender`: Male or Female (for completeness)
- `Role`: Job title or position
- `OU`: Department (IT, Finance, Sales, etc.)

**Script Execution:**
```powershell
# Set CSV path
$csvPath = "C:\Users\Import.csv"

# Run script
.\BulkUserCreation.ps1

# Script will:
# 1. Create Employee OU (if missing)
# 2. Create Department OUs
# 3. Create Department Groups
# 4. Create Users from CSV
# 5. Configure Home Drives
# 6. Setup Roaming Profiles
# 7. Add Users to Groups
# 8. (Optional) Enable Exchange Mailboxes
```

**User Configuration Applied:**
- **SamAccountName:** firstname.lastname (automatically generated)
- **UserPrincipalName:** firstname.lastname@domain.com
- **Password:** Set to default (users required to change at first logon)
- **Home Drive:** H: mapped to home directory
- **Roaming Profile:** Configured for logon to any workstation
- **Group Membership:** Added to department security group
- **Exchange Mailbox:** (Optional) Enabled if parameter specified

**Verification After Execution:**
```powershell
# Verify user creation
Get-ADUser -Filter {Department -eq "IT"} | Select-Object Name, SamAccountName

# Verify group membership
Get-ADGroupMember -Identity "IT Group" | Select-Object Name

# Verify home drive assignment
Get-ADUser -Identity john.doe -Properties HomeDirectory | Select-Object HomeDirectory

# Verify Exchange mailbox (if enabled)
Get-Mailbox -ResultSize Unlimited | Where-Object {$_.PrimarySmtpAddress -like "*john.doe*"}
```



## 🖥️ Hyper-V Scripts

### Internal Switch NAT Setup: Complete Configuration

**What the Script Configures:**

**Virtual Switch Creation:**
```powershell
# Creates internal virtual switch (not connected to physical NIC)
New-VMSwitch -Name "Internal Switch" -SwitchType Internal

# Assigns IP address to host vNIC
# Example: 192.168.100.1/24
```

**NAT Configuration:**
```powershell
# Creates NAT network
New-NetNat -Name "InternalNAT" -InternalIPInterfaceAddressPrefix "192.168.100.0/24"

# Enables port forwarding (optional)
# Example: Forward port 80 to VM
```

**Connectivity Testing:**
```powershell
# Tests connectivity between host and VMs
# Tests connectivity between VMs
# Validates DHCP assignment (if applicable)
# Verifies DNS resolution
```

**Usage Example:**
```powershell
# Run script
.\Hyper-V-NAT-Setup.ps1

# Script configures:
# - Internal virtual switch named "Internal Switch"
# - NAT gateway: 192.168.100.1
# - DHCP scope: 192.168.100.2-192.168.100.254
# - VM network configuration: 192.168.100.0/24

# Assign this switch to VM during creation:
# New-VM -Name "TestVM" -SwitchName "Internal Switch"
```



## ✅ Key Features

### Automation Capabilities

**Active Directory Automation:**
- ✅ Complete ADDS installation (forest, domain, DC setup)
- ✅ OU creation and hierarchy management
- ✅ Bulk user creation from CSV (100+ users)
- ✅ Security group creation and management
- ✅ Home drive assignment and mapping
- ✅ Roaming profile configuration
- ✅ User group membership automation
- ✅ OU deletion with force option

**Exchange Server Automation:**
- ✅ Complete Exchange 2019 installation with prerequisites
- ✅ Mailbox database creation (single or multiple)
- ✅ Mailbox enablement for bulk users
- ✅ Database mounting and initialization
- ✅ Post-installation configuration
- ✅ TLS 1.2/1.3 hardening

**Hyper-V Automation:**
- ✅ Internal virtual switch creation
- ✅ NAT configuration and rules
- ✅ Connectivity testing and validation
- ✅ Network troubleshooting automation

### Security Features

**Password Management:**
- Default password enforcement
- Force password change at first logon
- Secure string handling
- No plaintext passwords in logs

**Access Control:**
- Department-based security groups
- Granular permissions per OU
- Delegation support
- Audit logging of all changes

**Active Directory Security:**
- ADDS hardening applied automatically
- TLS 1.2 minimum enforcement
- Replication security configured
- DNS security zones

### Logging and Auditing

**Comprehensive Logging:**
- Timestamped log files
- Success/failure tracking
- User creation audit trail
- Configuration change logging
- Error capture and reporting

**Log Contents:**
```
[TIMESTAMP] User: john.doe created successfully
[TIMESTAMP] Added john.doe to IT Security Group
[TIMESTAMP] Home drive configured: H:\john.doe
[TIMESTAMP] Roaming profile configured: \\server\profiles\john.doe
[TIMESTAMP] Exchange mailbox enabled: john.doe@domain.com
[TIMESTAMP] Job completed with 0 errors
```



## 🚀 Getting Started

### Prerequisites

**System Requirements:**
- Windows Server 2016 or later
- PowerShell 5.1 or higher
- Administrator privileges
- Active Directory module (for AD scripts)
- Exchange Server 2019 media (for Exchange scripts)

**Required Modules:**
```powershell
# Import Active Directory module
Import-Module ActiveDirectory

# For Exchange scripts
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
```

**Environment Setup:**
```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Verify Active Directory module
Get-Module -ListAvailable ActiveDirectory

# Enable script execution
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

### Installation Steps

**Step 1: Download Scripts**
```powershell
# Clone repository or download individual scripts
# Save to directory like C:\Scripts or D:\PowerShell

cd C:\Scripts
```

**Step 2: Prepare CSV Files (if needed)**
```powershell
# For bulk user creation, prepare CSV:
# FirstName,LastName,FullName,Gender,Role,OU
# John,Doe,John Doe,Male,Engineer,IT
```

**Step 3: Run Script as Administrator**
```powershell
# Open PowerShell as Administrator
# Navigate to script directory

cd C:\Scripts

# Run script
.\BulkUserCreation.ps1
```

**Step 4: Verify Execution**
```powershell
# Check log files
Get-Content "C:\Scripts\BulkUserCreation.log"

# Verify results in Active Directory
Get-ADUser -Filter {Department -eq "IT"} | Select-Object Name, SamAccountName
```



## 📋 Installation Requirements

### Active Directory Scripts

**Before Running ADDS Installation:**
```
✓ Windows Server 2016+ installed (not domain-joined yet)
✓ Static IP address configured
✓ Server name set (no spaces or special characters)
✓ Internet connectivity available
✓ At least 50GB free disk space
✓ Minimum 2GB RAM (4GB+ recommended)
✓ Administrator credentials
```

**Port Requirements:**
- Port 389: LDAP
- Port 636: LDAPS
- Port 88: Kerberos
- Port 53: DNS
- Port 445: SMB

---

### Exchange Server Scripts

**Before Running Exchange Installation:**
```
✓ Windows Server 2022+ (2016/2019 supported)
✓ Domain-joined and part of valid AD domain
✓ AD schema updated for Exchange 2019
✓ Static IP address configured
✓ At least 100GB free disk space
✓ Minimum 8GB RAM (16GB+ recommended)
✓ Exchange 2019 media available (or internet access to download)
✓ TLS 1.2 support available
```

**Port Requirements:**
- Port 25: SMTP mail relay
- Port 80: HTTP redirect
- Port 443: HTTPS (OWA, ECP)
- Port 110: POP3
- Port 143: IMAP
- Port 587: SMTP TLS submission
- Port 989: FTPS
- Port 990: FTPS control

---

### Bulk User Creation Scripts

**Before Running User Creation:**
```
✓ Domain already created and functional
✓ Administrator credentials for AD
✓ CSV file with user data prepared
✓ File share for home drives created (\\server\HomeDir)
✓ File share for roaming profiles created (\\server\Profiles)
✓ Home drive quota policies defined (if using quotas)
✓ Exchange Server installed (if enabling mailboxes)
```



## 💡 Script Usage Guide

### Running ADDS Installation Script

**Full Automated Deployment:**
```powershell
# Run with all default parameters
.\ADDS-Installation-Fully-Automated.ps1

# Script will prompt for:
# - Domain name (e.g., domain.com)
# - NetBIOS name (e.g., DOMAIN)
# - Safe Mode administrator password
# - Then automate everything else
```

**Verification After Deployment:**
```powershell
# Connect to the new domain
$credential = Get-Credential
$session = New-PSSession -ComputerName DC-SERVER -Credential $credential

# Check domain details
Invoke-Command -Session $session -ScriptBlock {
    Get-ADDomain
    Get-ADForest
    Get-ADDomainController
}
```

---

### Running Bulk User Creation Script

**Step 1: Prepare CSV File**
```csv
FirstName,LastName,FullName,Gender,Role,OU
John,Doe,John Doe,Male,Engineer,IT
Jane,Smith,Jane Smith,Female,Manager,Finance
Bob,Johnson,Bob Johnson,Male,Analyst,Finance
Alice,Williams,Alice Williams,Female,Developer,IT
Carol,Brown,Carol Brown,Female,Director,Sales
David,Jones,David Jones,Male,Manager,Sales
```

**Step 2: Configure Script Parameters**
```powershell
# Edit script to set:
$csvPath = "C:\Scripts\users.csv"
$defaultPassword = "Pineapple123$"
$homeDrivePath = "\\server\HomeDir"
$profilePath = "\\server\Profiles"
```

**Step 3: Execute Script**
```powershell
# Run as Administrator
.\BulkUserCreation.ps1

# Script will output progress:
# Creating employee OU...
# Creating IT OU...
# Creating IT Users OU...
# Creating IT Groups OU...
# Creating john.doe user...
# Configuring home drive for john.doe...
# Adding john.doe to IT group...
# (continues for all users)
```

**Step 4: Verify Results**
```powershell
# Check users in IT department
Get-ADUser -Filter {Department -eq "IT"} -Properties * | Select-Object Name, SamAccountName, Department

# Check group membership
Get-ADGroupMember -Identity "IT Group" | Select-Object Name

# Check home drive assignments
Get-ADUser -Identity john.doe -Properties HomeDirectory | Select-Object HomeDirectory

# Check if users must change password
Get-ADUser -Identity john.doe | Select-Object PasswordExpired
```

---

### Running Exchange Deployment Script

**Step 1: Verify Prerequisites**
```powershell
# Check AD schema for Exchange 2019
Get-ADObject -SearchBase "cn=Schema,cn=Configuration,dc=domain,dc=com" `
  -Filter {name -eq "ms-Exch-Schema-Version-Pt"} `
  -Properties rangeUpper | Select-Object rangeUpper

# Should return value ≥ 15307 for Exchange 2019
```

**Step 2: Run Exchange Deployment Script**
```powershell
# As Administrator
.\Exchange2019-Deployment-With-Prerequisites.ps1

# Script will:
# - Validate prerequisites
# - Install Windows features
# - Install .NET Framework
# - Install Visual C++ runtimes
# - Download Exchange ISO (if needed)
# - Install Mailbox Role
# - Configure Exchange
# - Create mailbox database
```

**Step 3: Post-Installation Configuration**
```powershell
# Mount mailbox database
Mount-Database -Identity "Mailbox Database 01"

# Create test mailbox
New-Mailbox -UserPrincipalName testuser@domain.com `
  -Database "Mailbox Database 01"

# Test email send/receive
Send-TestMailMessage -RecipientAddress testuser@domain.com
```



## 🏆 Best Practices

### Before Automation

**1. Test in Lab Environment**
- Deploy all scripts to test environment first
- Verify with test data
- Document any modifications needed
- Test rollback procedures
- Train administrators on usage

**2. Plan Active Directory Structure**
- Design OU hierarchy before bulk user creation
- Plan department organizational structure
- Define security group strategy
- Plan OU delegation
- Document design decisions

**3. Prepare User Data**
- Validate CSV file format
- Remove duplicate users
- Standardize naming conventions
- Verify department names
- Clean up legacy data

**4. Backup Before Automation**
- Backup Active Directory
- Backup file shares
- Backup DNS configuration
- Backup Exchange (if applicable)
- Document backup procedures

---

### During Automation

**5. Monitor Script Execution**
- Watch script output for errors
- Monitor system resource usage
- Note any warnings (even if not errors)
- Keep log files for audit
- Have rollback procedure ready

**6. Document Changes**
- Log script start time
- Record script version used
- Document any parameters changed
- Capture output logs
- Note any manual interventions

**7. Validate Results**
- Verify all users created
- Check OU structure
- Confirm group membership
- Test user logons
- Verify mail flow (if Exchange)

---

### After Automation

**8. Security Hardening**
- Change default passwords
- Enable Group Policy Objects
- Configure permissions
- Enable auditing
- Review security logs

**9. Monitoring and Maintenance**
- Setup monitoring alerts
- Configure backup automation
- Schedule regular maintenance
- Review performance metrics
- Plan capacity growth

**10. Documentation**
- Document procedures
- Create runbooks
- Train staff
- Maintain script version control
- Plan future updates



## 🛠️ Troubleshooting

### Common Issues and Solutions

**Issue: "Active Directory module not found"**
- Symptom: Cannot import ActiveDirectory module
- Cause: RSAT not installed on workstation
- Resolution:
  ```powershell
  # Install RSAT on Windows 10/11
  Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online
  
  # Or on Windows Server
  Install-WindowsFeature RSAT-AD-PowerShell
  ```

**Issue: "User already exists"**
- Symptom: Script skips user creation
- Cause: User with same SamAccountName exists
- Resolution:
  ```powershell
  # Check for existing user
  Get-ADUser -Filter {SamAccountName -eq "john.doe"}
  
  # Delete if test user
  Remove-ADUser -Identity john.doe -Confirm:$false
  ```

**Issue: "Home drive not accessible"**
- Symptom: Users cannot access H: drive
- Cause: File share permissions or path incorrect
- Resolution:
  ```powershell
  # Verify file share exists
  Get-SmbShare -Name HomeDir
  
  # Check NTFS permissions
  icacls \\server\HomeDir
  
  # Grant permissions if needed
  icacls \\server\HomeDir /grant "DOMAIN\user:(OI)(CI)F"
  ```

**Issue: "Exchange installation fails"**
- Symptom: Exchange setup error
- Cause: Prerequisite not installed or AD schema old
- Resolution:
  ```powershell
  # Verify prerequisites
  Get-WindowsFeature | Where {$_.Installed -eq $true}
  
  # Check AD schema
  Get-ADObject -SearchBase "cn=Schema,cn=Configuration,dc=domain,dc=com" `
    -Filter {name -eq "ms-Exch-Schema-Version-Pt"} `
    -Properties rangeUpper
  
  # Should be ≥ 15307 for Exchange 2019
  ```

**Issue: "OU deletion fails"**
- Symptom: Cannot delete organizational unit
- Cause: OU protection enabled or contains objects
- Resolution:
  ```powershell
  # Disable OU protection
  Set-ADOrganizationalUnit -Identity "OU=Test,DC=domain,DC=com" -ProtectedFromAccidentalDeletion $false
  
  # List objects in OU
  Get-ADObject -SearchBase "OU=Test,DC=domain,DC=com" -Filter * -ResultSetSize 10000
  
  # Delete OU with contents
  Remove-ADOrganizationalUnit -Identity "OU=Test,DC=domain,DC=com" -Recursive -Confirm:$false
  ```

**Issue: "Hyper-V NAT fails to create"**
- Symptom: New-VMSwitch or New-NetNat fails
- Cause: Switch name conflict or network conflict
- Resolution:
  ```powershell
  # List existing switches
  Get-VMSwitch
  
  # Remove if conflicting
  Remove-VMSwitch -Name "ConflictingSwitch" -Force
  
  # Check for IP conflicts
  ipconfig /all
  
  # Try again with different network range
  ```



## 🎯 Conclusion

This PowerShell Scripting and Automation repository provides comprehensive automation for:

**Active Directory Management:**
- Complete ADDS installation and configuration
- Bulk user creation and provisioning
- Organizational unit management
- Security group administration
- Home drive and profile configuration

**Exchange Server Integration:**
- Complete Exchange 2019 deployment
- Mailbox database creation
- User mailbox provisioning
- Post-installation configuration

**Hyper-V Networking:**
- Automated virtual switch creation
- NAT configuration
- Network connectivity testing
- Lab environment automation

**Key Benefits:**
- ✅ Reduce manual work from 50+ hours to minutes
- ✅ Eliminate configuration errors
- ✅ Ensure consistent infrastructure
- ✅ Improve security posture
- ✅ Enable rapid scaling
- ✅ Complete audit trail
- ✅ Production-ready quality

**Suitable For:**
- Small organizations (10-50 users)
- Medium organizations (50-500 users)
- Large enterprises (500+ users)
- Lab and test environments
- Disaster recovery scenarios
- Cloud and hybrid deployments

This collection represents enterprise-grade automation that saves time, improves consistency, and enables IT teams to focus on strategic work instead of repetitive tasks.

---

**License:** MIT License: Free to use, modify, and deploy.

*A comprehensive portfolio project demonstrating advanced PowerShell scripting, enterprise automation expertise, and infrastructure-as-code principles. Perfect for IT professionals looking to showcase automation skills and streamline enterprise operations.*

**Next Steps:**
- Test scripts in lab environment
- Customize for your organization
- Integrate with existing tools
- Expand with additional automation
- Share improvements back to community
