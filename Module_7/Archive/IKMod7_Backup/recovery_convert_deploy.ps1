param(
    
    [Parameter(Mandatory = $true, HelpMessage = "Give me a oldresource group name")]
    [string]$OldResGroupName,
    [Parameter(Mandatory = $true, HelpMessage = "New resource group name")]
    [string]$NewResGroupName
)

$TemplateUri = "https://raw.githubusercontent.com/KstKrv/azure_arm/master/Module7_task/main_2template.json"
$ParamsUri = "https://raw.githubusercontent.com/KstKrv/azure_arm/master/Module7_task/main_2params.json"
$ParametersFilePath = "$env:TEMP\main_params.json"
$RGLocation = (Get-AzureRmResourceGroup -Name $OldResGroupName).location

#Login-AzAccount
Select-AzureRMSubscription -SubscriptionId "7235b6ab-38ff-4c22-bca3-3b625f1f916b" 

#Recovery Procces
$vault = Get-AzureRmRecoveryServicesVault

Set-AzureRmRecoveryServicesVaultContext -Vault $vault
$vmname = (get-azurermvm | where-object {$_.ResourceGroupName -eq $resgroupname}).name

$namedContainer = Get-AzureRmRecoveryServicesBackupContainer `
    -ContainerType "AzureVM" `
    -Status "Registered" `
    -FriendlyName $vmname

$item = Get-AzureRmRecoveryServicesBackupItem `
    -Container $namedContainer `
    -WorkloadType "AzureVM"

$rp = Get-AzureRmRecoveryServicesBackupRecoveryPoint -Item $Item 

$StorageAccountName = (Get-AzureRMstorageaccount -ResourceGroupName  $ResGroupName).StorageAccountName
Restore-AzureRmRecoveryServicesBackupItem `
    -RecoveryPoint $RP[0] `
    -StorageAccountName $StorageAccountName `
    -StorageAccountResourceGroupName $ResGroupName

# Getting disks names
$context = (Get-AzureRmStorageAccount -ResourceGroupName $OldResGroupName)[0].Context
$container = (Get-AzureStorageContainer -Context $context).Name

$OsDiskUri = (Get-AzureStorageBlob -Container $container -Context $context -Blob *.vhd | Where-Object {$_.name -like "*osdisk*"}).ICloudBlob.Uri.AbsoluteUri
$DataDiskUri = (Get-AzureStorageBlob -Container $container -Context $context -Blob *.vhd | Where-Object {$_.name -like "*datadisk*"}).ICloudBlob.Uri.AbsoluteUri

# Starting a deploy
New-AzureRmResourceGroup -Name $NewResGroupName -Location $RGLocation

Invoke-WebRequest -Uri $ParamsUri -OutFile $ParametersFilePath

New-AzureRmResourceGroupDeployment `
    -ResourceGroupName $NewResGroupName `
    -TemplateUri $TemplateURI `
    -TemplateParameterFile $ParametersFilePath `
    -OsDiskUri $OsDiskUri `
    -DataDiksUri $DataDiskUri `
    -Verbose

Remove-Item $ParametersFilePath