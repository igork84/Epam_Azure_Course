Param(
    [Parameter(Mandatory = $True, HelpMessage = "Give me resourse group name")]
    [string]$ResGroupName,
    [Parameter(Mandatory = $True, HelpMessage = "Give me resourse group location")]
    [string]$RGLocation
)

$TemplateURI = "https://raw.githubusercontent.com/KstKrv/azure_arm/master/Module8_task/main_template.json"
$TemplateParametersURI = "https://raw.githubusercontent.com/KstKrv/azure_arm/master/Module8_task/main_params.json"
$ParametersFilePath = "$env:TEMP\main_params.json"

$AppId = "cfe92184-9176-4066-b574-7182497b6b2b"
$AppIdSecret = (Get-AzureKeyVaultSecret -vault kstkrvkeyvault -name $AppId).secretvalue

Select-AzureRmSubscription -SubscriptionId "7235b6ab-38ff-4c22-bca3-3b625f1f916b"

Invoke-WebRequest -Uri $templateParametersURI -OutFile $ParametersFilePath

New-AzureRmResourceGroup -Name $ResGroupName -Location $RGLocation

New-AzureRmResourceGroupDeployment `
    -TemplateUri $TemplateURI `
    -ResourceGroupName $ResGroupName `
    -AppId $AppId `
    -AppIdSecret $AppIdSecret `
    -TemplateParameterFile $ParametersFilePath `
    -Verbose

Remove-Item $ParametersFilePath
