Param(
    [Parameter(Mandatory = $True, HelpMessage = "Give me resourse group name")]
    [string]$ResGroupName,
    [Parameter(Mandatory = $True, HelpMessage = "Give me resourse group location")]
    [string]$RGLocation,
    [Parameter(Mandatory = $True, HelpMessage = "Enter username for VMs")]
    [string]$Username,
    [Parameter(Mandatory = $True, HelpMessage = "Enter a password for VMs")]
    [securestring]$Password,
    [Parameter(Mandatory = $True, HelpMessage = "How many VMs to deploy")]
    [int]$Counter
)

# Some useful variables
$TemplateURI = "https://raw.githubusercontent.com/KstKrv/azure_arm/master/Module9_task1/main_template.json"
$TemplateParametersURI = "https://raw.githubusercontent.com/KstKrv/azure_arm/master/Module9_task1/main_params.json"
$AppRegName = "AutomationAcc"
$ParametersFilePath = "$env:TEMP\main_params.json"

Select-AzureRmSubscription -SubscriptionId "7235b6ab-38ff-4c22-bca3-3b625f1f916b"

# Creating new AD App registration & it's credentials

$appID = (Get-AzureRmADApplication -DisplayName $AppRegName).ApplicationId
$AppIdSecret = (Get-AzureKeyVaultSecret -vault kstkrvkeyvault -name $AppId).secretvalue

# Generating SAStoken URI for workflow cript
$accountKeys = Get-AzureRmStorageAccountKey -ResourceGroupName "MyOwnRG" -Name "kstkrvstorage"
$storageContext = New-AzureStorageContext -StorageAccountName 'kstkrvstorage' -StorageAccountKey $accountKeys[0].Value
$scriptUri = ConvertTo-SecureString -force -AsPlainText (New-AzureStorageBlobSASToken `
    -Container "workflows" `
    -Blob "Workflow_Stop-AzureVM.ps1" `
    -Permission "rwl" `
    -StartTime (Get-Date).AddHours(-1) `
    -ExpiryTime (get-date).AddMonths(1) `
    -Context $storageContext `
    -FullUri) 

# Generating Job ID for automation account
$JobID = [System.Guid]::NewGuid().toString()

# Starting deployment
Invoke-WebRequest -Uri $templateParametersURI -OutFile $ParametersFilePath

New-AzureRmResourceGroup -Name $ResGroupName -Location $RGLocation

New-AzureRmResourceGroupDeployment `
    -TemplateUri $TemplateURI `
    -ResourceGroupName $ResGroupName `
    -TemplateParameterFile $ParametersFilePath `
    -counter $counter `
    -Username $Username `
    -Password $Password `
    -JobID $jobID `
    -scriptUri $scriptUri `
    -appID $appID `
    -appidsecret $AppIdSecret `
    -Verbose

Remove-Item $ParametersFilePath

# The end)
