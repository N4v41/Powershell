$VMLocalAdminUser = "kali"
$Pass = Read-Host -Prompt "Digite uma senha para o usuario local" -AsSecureString 
$instancenumber = Read-Host -Prompt  "Digite o numero da Instancia"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "$Pass" -AsPlainText -Force
$LocationName = "eastus2"
$ResourceGroupName = "kali" + $instancenumber
$ComputerName = "kali" + $instancenumber
$VMName = "kali" + $instancenumber
$VMSize = "Standard_B2s"

$NetworkName = "MyNet"
$NICName = "MyNIC"
$SubnetName = "MySubnet"
$SubnetAddressPrefix = "10.0.0.0/24"
$VnetAddressPrefix = "10.0.0.0/16"
$sshPublicKey = Read-Host -Prompt "Informe uma chave publica para o SSH da maquina"
import-module AzureRM.Compute
import-module AzureRM.Network
# Create a resource group
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $LocationName

# Create a public IP address and specify a DNS name
$pip = New-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $LocationName `
  -Name "mypublicdns$(Get-Random)" -AllocationMethod Dynamic -DomainNameLabel $ComputerName -IdleTimeoutInMinutes 30

# Create an inbound network security group rule for port 22
$nsgRuleSSH = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH  -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 22 -Access Allow

# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Location $LocationName `
  -Name myNetworkSecurityGroup -SecurityRules $nsgRuleSSH

$SingleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
$Vnet = New-AzureRmVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -Location $LocationName `
 -AddressPrefix $VnetAddressPrefix -Subnet $SingleSubnet
$NIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $LocationName `
 -SubnetId $Vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

Get-AzureRmMarketplaceTerms -Publisher kali-linux -Product kali-linux -Name kali | Set-AzureRmMarketplaceTerms -Accept

$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize

$VirtualMachine = Set-AzureRmVMPlan -VM $VirtualMachine -Name kali  -Product kali-linux -Publisher kali-linux

$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName $ComputerName `
 -Credential $Credential -DisablePasswordAuthentication

$VirtualMachine = Add-AzureRmVMSshPublicKey -VM $VirtualMachine -KeyData $sshPublicKey -Path "/home/kali/.ssh/authorized_keys"

$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id

$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName kali-linux -Offer kali-linux -Skus kali -Version 2018.4.0

New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $VirtualMachine -Verbose