$location = "uksouth"
$resourceGroupName = "mate-azure-task-9"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"
$publicIpAddressName = "linuxboxpip"
$sshKeyName = "linuxboxsshkey"
$sshKeyPublicKey = Get-Content "~/.ssh/id_rsa.pub" 
$vmName = "matebox"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_B1s"

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating a network security group $networkSecurityGroupName ..."
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name SSH  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow;
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP  -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow;
New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $nsgRuleSSH, $nsgRuleHTTP

# Creating a virtual network and subnet
Write-Host "Creating virtual network $virtualNetworkName with subnet $subnetName ..."
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location `
    -Name $virtualNetworkName -AddressPrefix $vnetAddressPrefix

$subnet = Add-AzVirtualNetworkSubnetConfig -Name $subnetName `
    -VirtualNetwork $vnet -AddressPrefix $subnetAddressPrefix

Set-AzVirtualNetwork -VirtualNetwork $vnet

# Creating a public IP address
Write-Host "Creating public IP address $publicIpAddressName ..."
$publicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location `
    -Name $publicIpAddressName -AllocationMethod Static -Sku Basic -DnsName "matebox-dns"

# Creating an SSH key resource
Write-Host "Creating SSH key resource $sshKeyName ..."
$sshKey = New-AzSshKey -ResourceGroupName $resourceGroupName -Location $location `
    -Name $sshKeyName -PublicKey $sshKeyPublicKey

# Retrieving resources to create a network interface
$vnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $virtualNetworkName
$subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $networkSecurityGroupName
$publicIp = Get-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Name $publicIpAddressName

# Creating a network interface for the VM
Write-Host "Creating network interface for VM ..."
$nic = New-AzNetworkInterface -ResourceGroupName $resourceGroupName -Location $location `
    -Name "$vmName-nic" -SubnetId $subnet.Id -PublicIpAddressId $publicIp.Id -NetworkSecurityGroupId $nsg.Id

# Creating a virtual machine
Write-Host "Creating virtual machine $vmName ..."
New-AzVm -ResourceGroupName $resourceGroupName -Location $location `
    -Name $vmName -Size $vmSize -Image $vmImage `
    -PublicIpAddressName $publicIpAddressName `
    -VirtualNetworkName $virtualNetworkName -SubnetName $subnetName `
    -SecurityGroupName $networkSecurityGroupName -SshKeyName $sshKeyName `
    -OpenPorts 22,8080

Write-Host "Deployment completed successfully."

