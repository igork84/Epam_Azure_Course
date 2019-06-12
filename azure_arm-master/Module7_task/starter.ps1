Param(
    [Parameter(Mandatory = $True, HelpMessage = "Give me resourse group name")]
    [string]$ResGroupName,
    [Parameter(Mandatory = $True, HelpMessage = "Give me resourse group location")]
    [string]$RGLocation,
    [Parameter(Mandatory = $True, HelpMessage = "VM's login")]
    [string]$VMLogin,
    [Parameter(Mandatory = $True, HelpMessage = "VM's password")]
    [securestring]$VMPassword
)


$TemplateURI = "https://raw.githubusercontent.com/KstKrv/azure_arm/master/Module7_task/main_template.json"
$TemplateParametersURI = "https://raw.githubusercontent.com/KstKrv/azure_arm/master/Module7_task/main_params.json"
$ParametersFilePath = "$env:TEMP\main_params.json"

#Logging in
#Login-AzAccount
Select-AzureRmSubscription -SubscriptionId "7235b6ab-38ff-4c22-bca3-3b625f1f916b"


#Generating SAS token URI for DSC script that will format and mount datadisk
$accountKeys = Get-AzureRmStorageAccountKey -ResourceGroupName "MyOwnRG" -Name "kstkrvstorage"
$storageContext = New-AzureStorageContext -StorageAccountName 'kstkrvstorage' -StorageAccountKey $accountKeys[0].Value
$sastokenurl = ConvertTo-SecureString -AsPlainText (New-AzureStorageBlobSASToken `
    -Container "windows-powershell-dsc" `
    -Blob dsc_datadisk.ps1.zip `
    -Permission rwl `
    -StartTime (Get-Date).AddHours(-1) `
    -ExpiryTime (get-date).AddMonths(1) `
    -Context $storageContext `
    -FullUri) -Force

#Starting new deployment
Invoke-WebRequest -Uri $templateParametersURI -OutFile $ParametersFilePath

New-AzureRmResourceGroup -Name $ResGroupName -Location $RGLocation

New-AzureRmResourceGroupDeployment `
    -TemplateUri $TemplateURI `
    -ResourceGroupName $ResGroupName `
    -SecretName $VMLogin `
    -SecretValue $VMPassword `
    -TemplateParameterFile $ParametersFilePath `
    -sastokenurl $sastokenurl 

Remove-Item $ParametersFilePath


#Backing up created VM

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

Backup-AzureRmRecoveryServicesBackupItem -Item $item