# Step 1: Install AD DS role and management tools
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# Step 2: Set DSRM password
$SafeModeAdminPassword = Read-Host "Enter DSRM password" -AsSecureString

# Step 3: Promote server to Domain Controller and create new forest abc.com
Install-ADDSForest `
    -DomainName "abc.com" `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "Default" `
    -ForestMode "Default" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -SafeModeAdministratorPassword $SafeModeAdminPassword `
    -NoRebootOnCompletion:$false `
    -Force:$true


