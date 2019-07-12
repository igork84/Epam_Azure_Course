
Connect-AzAccount
#Get-AzSubscription
Select-AzSubscription -SubscriptionName 'Aliaksei_Babuk@epam.com'
##cd C:\Work_folder\Books\Books\Azure\EPAM_cource_2\HW_8
### List of Variables
### For ARM
$RGforTest = "Test_Azure_course_HW8"
$LocationForTest = "West Europe"
$StorageAccountName = 'hw8storageblob'
$StorageContainerName = 'tempconthw8'
$MainTamplaitPath = '.\main.json'
$TemplateParameterFile = '.\parameters.json'
$AppId = "3d3d83fb-3bfe-4492-9e6f-f0efe7ec74ce"
$KeyVaultName = 'TestAzureEpam'
#For Docker
$EmailforDocker = 'aliaksei_babuk@epam.com'
# For Kubernetes



### Create a resource group
$Create = New-AzResourceGroup -Name $RGforTest -Location $LocationForTest

if ($Create.ProvisioningState -eq 'Succeeded'){
    Write-Host "The Resource Group $RGforTest was created" -ForegroundColor Green

    ### Creating SA and copy files to it
    $StorageAccount = New-AzStorageAccount -ResourceGroupName $RGforTest -AccountName $StorageAccountName -Location $LocationForTest -SkuName 'Standard_GRS' -Kind 'BlobStorage' -AccessTier 'Hot'
    New-AzStorageContainer  -Name $StorageContainerName  -Permission blob -Context $StorageAccount.Context
    Get-ChildItem -File -Recurse | Set-AzStorageBlobContent   -Container $StorageContainerName -Context $StorageAccount.Context -Force

    ### Get password
    
    $Pass = (Get-AzKeyVaultSecret -vault $KeyVaultName -name $AppId).secretvalue

    ### deploy resources
    Write-Host "Starting deployment operation" -ForegroundColor Green

    Test-AzResourceGroupDeployment -TemplateFile $MainTamplaitPath -ResourceGroupName $RGforTest  -TemplateParameterFile $TemplateParameterFile  -secretValue $Pass -Verbose
    $Build = New-AzResourceGroupDeployment -TemplateFile $MainTamplaitPath -ResourceGroupName $RGforTest -TemplateParameterFile $TemplateParameterFile -secretValue $Pass -Verbose 
    
}

### Part 2
$Build.ProvisioningState
if ($Build.ProvisioningState -eq 'Succeeded'){
    $AksName = $Build.Outputs.aksName.Value
    $AcrName = $Build.Outputs.acrName.Value

    ### get Kubernetes creds
    az aks get-credentials --resource-group $RGforTest --name $AksName

    ### grant additional rights for deployment 
    $Scope = '/subscriptions/7fbb9f57-c81f-4114-a4ce-421706f73c58/resourceGroups/Test_Azure_course_HW8/providers/Microsoft.ContainerRegistry/registries/' + $AcrName 
    az role assignment create --assignee $AppId --scope $Scope --role acrpull
    $AppId = '5bcc2513-8da6-44b4-9e4b-72a9886d0d52'
    $Scope = '/subscriptions/7fbb9f57-c81f-4114-a4ce-421706f73c58/resourceGroups/Test_Azure_course_HW8/providers/Microsoft.Network/virtualNetworks/Test_Azure_course_HW8-vnet/subnets/default'
    az role assignment create --assignee $AppId --scope $Scope --role 'Contributor'       

    ### set in Kubernetes custom container registry creds

    $DockerSresverPath = $AcrName + '.azurecr.io'
    kubectl create secret docker-registry acr-auth --docker-server $DockerSresverPath --docker-username $AppId --docker-password $Pass --docker-email $EmailforDocker
            
    ### creatin docker image an push in to custom container registry

    az acr login --name $AcrName

    docker build --tag=friendlyhelloalex .\Dockerfiles

    $TagForImage = $DockerSresverPath + '/samples/friendlyhelloalex'
    docker tag friendlyhelloalex $TagForImage
    docker push $TagForImage

    ### Kubernetes deploy step
    
    kubectl apply -f .\Kubernetes\Deployment.yaml 
    kubectl apply -f .\Kubernetes\Service.yaml
        
    #### Test kubectl deploy
    Write-Host "Starting Kubernetes deployment check operation. Please stand bye" -ForegroundColor Green
    Start-Sleep 120
    
    kubectl get pods
    kubectl describe  service friendlyhelloalex
    kubectl get service friendlyhelloalex
}