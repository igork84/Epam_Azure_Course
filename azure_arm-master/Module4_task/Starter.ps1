Param(
    [Parameter(Mandatory = $True, HelpMessage = "Give me resourse group name")]
    [string]$ResGroupName,
    [Parameter(Mandatory = $True, HelpMessage = "Give me a path to parameters file")]
    [string]$ParametersFilePath
)

#Logging in
Login-AzAccount
Select-AzureRmSubscription -SubscriptionId "7235b6ab-38ff-4c22-bca3-3b625f1f916b"

#Recieving SAS-token
$accountKeys = Get-AzureRmStorageAccountKey -ResourceGroupName "MyOwnRG" -Name "kstkrvstorage"
$storageContext = New-AzureStorageContext -StorageAccountName 'kstkrvstorage' -StorageAccountKey $accountKeys[0].Value
$sastokenurl = New-AzureStorageBlobSASToken -Container "windows-powershell-dsc" -Blob dsc.ps1.zip -Permission rwl -StartTime (Get-Date).AddHours(-1) -ExpiryTime (get-date).AddMonths(1) -FullUri -Context $storageContext

New-AzureRmResourceGroup -Name $ResGroupName -Location westeurope
New-AzureRmResourceGroupDeployment -TemplateUri "https://raw.githubusercontent.com/KstKrv/azure_arm/master/Module4_task/main_template.json" -ResourceGroupName $ResGroupName -sastokenurl $sastokenurl -TemplateParameterFile $ParametersFilePath