Param(
    [Parameter(Mandatory = $True, HelpMessage = "Give me resourse group name")]
    [string]$ResGroupName
)

$TemplateUri = "https://raw.githubusercontent.com/KstKrv/azure_arm/master/Module6_task/main_template.json"
$TemplateParameterUri = "https://raw.githubusercontent.com/KstKrv/azure_arm/master/Module6_task/main_params.json"

#Logging in
Login-AzAccount
Select-AzureRmSubscription -SubscriptionId "7235b6ab-38ff-4c22-bca3-3b625f1f916b"

New-AzureRmResourceGroup -Name $ResGroupName -Location westeurope
New-AzureRmResourceGroupDeployment -TemplateUri $TemplateUri -ResourceGroupName $ResGroupName -TemplateParameterUri $TemplateParameterUri