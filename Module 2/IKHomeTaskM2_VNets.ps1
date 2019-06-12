#This script create two Azure VNETs connected 
#by Ihar Kuvaldzin

#Connect to Azure subscription
Connect-AzAccount

#Select subscription
Select-AzSubscription -Subscription "6d272dbf-3653-4dbf-a97a-4a31ba45602f"

Write-Host "Selected subscription is:"
write-host "###################################"
Get-AzSubscription
write-host "###################################"

#Variables
$RGName = "IKMod2RG"
$Location = "NorthEurope"

#Vnet1 variables
$VNetName1 = "IKVNet1"
$SubName1 = "IKSubnet1"
$GWSubName1 = "GatewaySubnet"
$VNetPrefix1 = "10.10.0.0/16"
$SubPrefix1 = "10.10.0.0/24"
$GWSubPrefix1 = "10.10.255.0/27"
$GWName1 = "IKVNet1GW"
$GWIPName1 = "IKVNet1GWIP"
$GWIPconfName1 = "IKGWIPConf1"
$Connection1 = "IKVNet1toIKVNet2"

#Vnet2 variables
$VNetName2 = "IKVNet2"
$SubName2 = "IKSubnet2"
$GWSubName2 = "GatewaySubnet"
$VNetPrefix2 = "10.20.0.0/16"
$SubPrefix2 = "10.20.0.0/24"
$GWSubPrefix2 = "10.20.255.0/27"
$GWName2 = "IKVNet2GW"
$GWIPName2 = "IKVNet2GWIP"
$GWIPconfName2 = "IKGWIPConf2"
$Connection2 = "IKVNet2toIKVNet1"


#Create ResourceGroup
write-host "###################################"
Write-Host "Creating Resource Group"
write-host "###################################"
New-AzResourceGroup -Name $RGName -Location $Location

Function Create-VnetGW
{
    PARAM (
        [String]$SubName,
        [String]$GWSubName,
        [String]$SubPrefix,
        [String]$GWSubPrefix,
        [String]$VNetName,
        [String]$RGName,
        [String]$GWIPName,
        [String]$Location,
        [String]$VNetPrefix,
        [String]$GWIPConfName,
        [String]$GWName
        )
    
    #Create the subnet configurations for VNet
    $sbnet = New-AzVirtualNetworkSubnetConfig -Name $SubName -AddressPrefix $SubPrefix
    $gwsub = New-AzVirtualNetworkSubnetConfig -Name $GWSubName -AddressPrefix $GWSubPrefix

    #Create VNet
    New-AzVirtualNetwork -Name $VNetName -ResourceGroupName $RGName -Location $Location -AddressPrefix $VNetPrefix -Subnet $sbnet,$gwsub

    #Request a public IP address to be allocated to the gateway
    $gwpip = New-AzPublicIpAddress -Name $GWIPName -ResourceGroupName $RGName -Location $Location -AllocationMethod Dynamic

    #Create the gateway configuration
    $vnet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $RGName
    $subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet
    $gwipconf = New-AzVirtualNetworkGatewayIpConfig -Name $GWIPConfName -Subnet $subnet -PublicIpAddress $gwpip

    #Create the gateway for VNet
    New-AzVirtualNetworkGateway -Name $GWName -ResourceGroupName $RGName -Location $Location -IpConfigurations $gwipconf -GatewayType Vpn -VpnType RouteBased -GatewaySku VpnGw1        
}

#Create Bothside VNet2Vnet connection
Function Create-VnetConnection {

    PARAM (
        [String]$GWName1,
        [String]$GWName2,
        [String]$Connection1,
        [String]$Connection2,
        [string]$Location

    )

        #Get VNet Gateway
        $vnet1gw = Get-AzVirtualNetworkGateway -Name $GWName1 -ResourceGroupName $RGName
        $vnet2gw = Get-AzVirtualNetworkGateway -Name $GWName2 -ResourceGroupName $RGName

        #Create Bothside VNet2Vnet connection
        New-AzVirtualNetworkGatewayConnection -Name $Connection1 -ResourceGroupName $RGName `
        -VirtualNetworkGateway1 $vnet1gw -VirtualNetworkGateway2 $vnet2gw -Location $Location `
        -ConnectionType Vnet2Vnet -SharedKey 'EpamIKMod2'

        New-AzVirtualNetworkGatewayConnection -Name $Connection2 -ResourceGroupName $RGName `
        -VirtualNetworkGateway1 $vnet2gw -VirtualNetworkGateway2 $vnet1gw -Location $Location `
        -ConnectionType Vnet2Vnet -SharedKey 'EpamIKMod2'
}

## MAIN
#Create 2 Vnet Gateways
write-host "###################################"
Write-Host "Creating first vnet and gateway"
write-host "###################################"
Create-VnetGW -VNetName $VNetName1 -GWSubName $GWSubName1 -SubName $SubName1 -VNetPrefix $VNetPrefix1 -SubPrefix $SubPrefix1 -GWSubPrefix $GWSubPrefix1 `
    -GWIPName $GWIPName1 -GWIPConfName $GWIPconfName1 -GWName $GWName1 -RGName $RGName -Location $Location


write-host "###################################"
Write-Host "Creating second vnet and gateway"
write-host "###################################"
Create-VnetGW -VNetName $VNetName2 -GWSubName $GWSubName2 -SubName $SubName2 -VNetPrefix $VNetPrefix2 -SubPrefix $SubPrefix2 -GWSubPrefix $GWSubPrefix2 `
    -GWIPName $GWIPName2 -GWIPConfName $GWIPconfName2 -GWName $GWName2 -RGName $RGName -Location $Location

write-host "###################################"
Write-Host "Creating connections between Vnets"
write-host "###################################"
#Create Connections
Create-VnetConnection -GWName1 $GWName1 -GWname2 $GWName2 -Connection1 $Connection1 -Connection2 $Connection2 -Location $Location

write-host "###################################"
Write-Host "Test connections"
write-host "###################################"
#Test connection
Get-AzVirtualNetworkGatewayConnection -Name $Connection1 -ResourceGroupName $RGName
Get-AzVirtualNetworkGatewayConnection -Name $Connection2 -ResourceGroupName $RGName

#Removing test resource group
write-host "###################################"
Write-Host "Request for resource group removal"
write-host "###################################"
write-host "If you wont to remove test resource group please press 'y' or somthing else and Enter!"
write-host "For skipping this step just press Enter"
$ans = Read-Host "Please make your choice: "
if ($ans -ne $false) {
    Write-Host "Resource Group will be removed during in a few minutes..."
    Remove-AzResourceGroup -Name $RGName
}
else {
    Write-Host "Resource Group will be manually removed later..."
}
write-host "############################################"
Write-host "Thank you for your time! Have a nice day..."
Write-host "Test script created by Ihar Kuvaldzin."
write-host "############################################"