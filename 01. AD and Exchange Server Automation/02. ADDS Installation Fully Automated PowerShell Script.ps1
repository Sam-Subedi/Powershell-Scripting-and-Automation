# Check if this is first run (before rename)
if (-not (Test-Path "C:\DCSetupStage.txt"))
{
    # Mark stage
    New-Item -Path "C:\" -Name "DCSetupStage.txt" -ItemType File | Out-Null

    # Ask for Server Name
    $NewName = Read-Host "Enter new Server Name (example: DC1)"
    Rename-Computer -NewName $NewName -Force

    Write-Host "Rebooting to apply hostname change..."
    Restart-Computer -Force
    exit
}

# SECOND STAGE AFTER REBOOT

# Ask for Network Info
$IP = Read-Host "Enter Static IPv4 Address (example: 192.168.1.10)"
$SubnetMask = Read-Host "Enter Subnet Mask (example: 255.255.255.0)"
$Gateway = Read-Host "Enter Default Gateway (example: 192.168.1.1)"

# Get active adapter
$Adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}

# Convert Subnet Mask to Prefix Length
$PrefixLength = (32 - [math]::Log(([IPAddress]$SubnetMask).Address -band 0xffffffff,2))

# Remove DHCP IP if exists
Get-NetIPAddress -InterfaceIndex $Adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false

# Set Static IP
New-NetIPAddress `
    -InterfaceIndex $Adapter.InterfaceIndex `
    -IPAddress $IP `
    -PrefixLength $PrefixLength `
    -DefaultGateway $Gateway

# Set DNS to itself (best practice for first DC)
Set-DnsClientServerAddress `
    -InterfaceIndex $Adapter.InterfaceIndex `
    -ServerAddresses $IP

# Install AD DS role
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# Ask for DSRM password
$SafeModeAdminPassword = Read-Host "Enter DSRM password" -AsSecureString

# Promote to Domain Controller
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

