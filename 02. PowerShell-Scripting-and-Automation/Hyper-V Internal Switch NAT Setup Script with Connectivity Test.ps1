# Hyper-V Internal Switch NAT Setup Script

# 0️⃣ Temporarily allow running scripts
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 1️⃣ Variables
$SwitchName      = "LAN Switch"          # EXACT name of your Internal switch
$InternalSubnet = "192.168.2.0/24"            # VM subnet
$GatewayIP      = "192.168.2.1"               # Host gateway IP
$NatName        = "LANSwitchNAT"

$vAdapter = "vEthernet ($SwitchName)"

# 2️⃣ Verify vEthernet adapter exists
if (-not (Get-NetAdapter -Name $vAdapter -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: vEthernet adapter '$vAdapter' not found."
    exit
}
Write-Host "Found vEthernet adapter: $vAdapter"

# 3️⃣ Assign static gateway IP to Internal Switch (if missing)
if (-not (Get-NetIPAddress -InterfaceAlias $vAdapter -IPAddress $GatewayIP -ErrorAction SilentlyContinue)) {
    Write-Host "Assigning gateway IP $GatewayIP to $vAdapter..."
    New-NetIPAddress `
        -InterfaceAlias $vAdapter `
        -IPAddress $GatewayIP `
        -PrefixLength 24
} else {
    Write-Host "Gateway IP already assigned."
}

# 4️⃣ Remove old NAT if it exists
if (Get-NetNat -Name $NatName -ErrorAction SilentlyContinue) {
    Write-Host "Removing existing NAT: $NatName..."
    Remove-NetNat -Name $NatName
}

# 5️⃣ Create NAT
Write-Host "Creating NAT '$NatName' for subnet $InternalSubnet..."
New-NetNat `
    -Name $NatName `
    -InternalIPInterfaceAddressPrefix $InternalSubnet

Write-Host "✅ NAT created successfully!"
Write-Host "-----------------------------------"

# 6️⃣ Connectivity Test (Host Side)
Write-Host "Running connectivity test..."

# Verify gateway IP
Get-NetIPAddress -InterfaceAlias $vAdapter |
    Where-Object { $_.IPAddress -eq $GatewayIP } |
    Format-Table IPAddress, InterfaceAlias

# Test internet reachability
Test-NetConnection 8.8.8.8 -InformationLevel Detailed

Write-Host "-----------------------------------"

# 7️⃣ VM Configuration Reminder
Write-Host "VM Configuration:"
Write-Host "• Switch: $SwitchName"
Write-Host "• IP: 192.168.2.2 – 192.168.2.254"
Write-Host "• Mask: 255.255.255.0"
Write-Host "• Gateway: $GatewayIP"
Write-Host "• DNS: 8.8.8.8 or $GatewayIP"
Write-Host "-----------------------------------"

# 8️⃣ Verify NATs (Default Switch unaffected)
Write-Host "Existing NATs on host:"
Get-NetNat | Format-Table Name, InternalIPInterfaceAddressPrefix


