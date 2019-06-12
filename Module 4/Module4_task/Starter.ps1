#by Ihar Kuvaldzin

#Function for writing messages
Function write-mess {
    PARAM (
        [PARAMETER(Mandatory=$True)]
        [STRING]$Text
    )
    write-host "###################################"
    Write-Host "$Text"
    write-host "###################################"
}

#Connect to Azure subscription
Connect-AzAccount

#Select subscription
Select-AzSubscription -Subscription "Ihar Kuvaldzin"

write-mess -Text 'Selected Subscription is:' 
Get-AzSubscription

#Variables
$RGName = "IKMod4RG"
$Location = "NorthEurope"
$SA = "iksabase"
$ContainerName = "ik-cont-main"
#$keyVaultName = "IKKeyVault"
#$userPrincipalName = "dzmitry_mazurenka@epam.com"

#Create Resource Group
write-mess -Text 'Creating Resource Group'
New-AzResourceGroup -Name $RGName -Location $Location

#Create Storage Account
write-mess -Text 'Creating Storage Account and BLOB Container
for uploading ARM Templates files...'
$storageAccount = New-AzStorageAccount -Name $SA -ResourceGroupName $RGName -SkuName Standard_LRS -Location $Location
$ctx = $storageAccount.Context
New-AzStorageContainer -Name $ContainerName -Context $ctx -Permission off

#Upload ARM Template files in created container
Get-ChildItem -File -Recurse -Exclude "*.ps1" | Set-AzStorageBlobContent -Container $ContainerName -Context $ctx

#Generating SAS Token
write-mess -Text 'Generating SAS Token:'
Set-AzCurrentStorageAccount -ResourceGroupName $RGName -Name $SA
#$templateuri = New-AzStorageBlobSASToken -Container $ContainerName -Blob main.json -Permission r -ExpiryTime (Get-Date).AddHours(2.0) -FullUri
$token = New-AzStorageContainerSASToken -Name $ContainerName -Permission r -ExpiryTime (Get-Date).AddMinutes(30.0)

#Deploy key vaults and secrets
# write-mess -Text "Deploy key vaults and secrets"
# New-AzKeyVault -VaultName $keyVaultName -resourceGroupName $resourceGroupName -Location $location -EnabledForTemplateDeployment
# $secretvalue = ConvertTo-SecureString 'hVFkk965BuUv' -AsPlainText -Force
# $secret = Set-AzKeyVaultSecret -VaultName $keyVaultName -Name 'AccessPassword' -SecretValue $secretvalue
# Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -UserPrincipalName $userPrincipalName -PermissionsToSecrets set,delete,get,list -

#Deployment ARM Templates
write-mess -Text "Deploying ARM Templates"
New-AzResourceGroupDeployment -ResourceGroupName $RGName -TemplateFile ".\main.json" -TemplateParameterFile ".\parameters.json" -containerSasToken $token

#Removing test Resource group
write-mess -Text "Request for resource group removal`n
If you wont to remove test resource group
please press 'y' or somthing else and Enter!`n
For skipping this step just press Enter"
$ans = Read-Host "Please make your choice"
if ($ans -ne '') {
    Write-Host "Resource Group will be removed during in a few minutes..."
    Remove-AzResourceGroup -Name $RGName -Force
}
else {
    Write-Host "Resource Group will be manually removed later..."
}
write-mess "Thank you for your time! Have a nice day...`n
This script was created by Ihar Kuvaldzin."