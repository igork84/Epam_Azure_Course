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
$RGName = "IKMod8RG"
$Location = "NorthEurope"
$SA = "iksabase"
$ContainerName = "ik-cont-main"
$KVName = 'KeyVaultIK'
$AppId = 'd3298af1-285b-4589-9d23-f8696e1e0bc0'
$Email = 'ihar_kuvaldzin@epam.com'

#Create Resource Group
write-mess -Text 'Ctreating Resource Group'
New-AzResourceGroup -Name $RGName -Location $Location

#Create Storage Account
write-mess -Text 'Creating Storage Account and BLOB Container'
$storageAccount = New-AzStorageAccount -Name $SA -ResourceGroupName $RGName -SkuName Standard_LRS -Location $Location
$ctx = $storageAccount.Context
New-AzStorageContainer -Name $ContainerName -Context $ctx -Permission Blob

#Upload ARM Template files in created container
write-mess -Text 'Uploading ARM Templates in Azure stprage'
Get-ChildItem -File -Recurse -Exclude "*.ps1" | Set-AzStorageBlobContent -Container $ContainerName -Context $ctx

#Getting AppID Secret
$AppIdSecret = (Get-AzKeyVaultSecret -Vault $KVName -Name $AppId).SecretValue

write-mess -Text 'Deploying ARM Templates'
$Deploy = New-AzResourceGroupDeployment `
-TemplateFile "main_template.json" `
-ResourceGroupName $RGName `
-TemplateParameterFile "main_params.json" `
-AppID $AppId `
-AppIDSecret $AppIdSecret `
-Verbose

#Building
write-mess -Text 'Building process'
$KBSName = $Deploy.Outputs.kbsName.Value
$ACRName = $Deploy.Outputs.acrName.Value

#Getting Kubernetes Credentials and granting rights
az aks get-credentials --resource-group $RGName --name $KBSName

#grant rights to scoups for deployment 
$Scope1 = '/subscriptions/6d272dbf-3653-4dbf-a97a-4a31ba45602f/resourceGroups/IKMod8RG/providers/Microsoft.ContainerRegistry/registries/' + $AcrName 
az role assignment create --assignee $AppId --scope $Scope1 --role acrpull

$Scope2 = '/subscriptions/6d272dbf-3653-4dbf-a97a-4a31ba45602f/resourceGroups/MC_IKMod8RG_KBSsleqc6zvv6ykm_northeurope/providers/Microsoft.Network/virtualNetworks/aks-vnet-41444006'
az role assignment create --assignee $AppId --scope $Scope2 --role 'Contributor' 

$DockerRegistry = $AcrName + '.azurecr.io'
kubectl create secret docker-registry acr-auth --docker-server $DockerRegistry --docker-username $AppId --docker-password $AppIdSecret --docker-email $Email
        
#Creating docker image an push in to custom container registry
az acr login --name $AcrName

docker build --tag=hellofileiharkuvaldzin .\Dockerfiles

$Tag = $DockerRegistry + '/samples/hellofileiharkuvaldzin'
docker tag hellofileiharkuvaldzin $Tag
docker push $Tag

#Kubernetes deploy step

kubectl apply -f .\Kubernetes\Deployment.yaml 
kubectl apply -f .\Kubernetes\Service.yaml
    
# Test kubectl deploy
write-mess -Text "Testing Kubernetes deploying"
Start-Sleep 150
write-mess -Text 'Getting pods'
kubectl get pods
write-mess -Text 'Getting service info'
kubectl describe service hellofileiharkuvaldzin
write-mess -Text 'Getting service'
kubectl get service hellofileiharkuvaldzin

#Removing test resource group
write-mess -Text "Request for resource group removal`n
If you wont to remove test resource group please press 'y' or somthing else and Enter!`n
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