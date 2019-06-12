Param(
    [Parameter(Mandatory = $True)]
    [string]$ResGroupName,
    [Parameter(Mandatory = $True)]
    [string]$Location
)

#Login-AzAccount
Select-AzureRmSubscription -Subscription "7235b6ab-38ff-4c22-bca3-3b625f1f916b"

New-AzureRmResourceGroup -Name $ResGroupName -Location $Location

New-AzureRmResourceGroupDeployment -ResourceGroupName $ResGroupName -TemplateUri "https://raw.githubusercontent.com/KstKrv/azure_arm/master/Module5_task/main_template.json" -TemplateParameterUri "https://raw.githubusercontent.com/KstKrv/azure_arm/master/Module5_task/main_params.json"