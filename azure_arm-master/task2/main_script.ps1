Param(
    [Parameter(Mandatory=$True)]
    [string]$ResGroupName
)

# Powershell block

Login-AzAccount
Select-AzureRmSubscription -SubscriptionId "7235b6ab-38ff-4c22-bca3-3b625f1f916b"
New-AzureRmResourceGroup -Name $ResGroupName -Location westeurope
New-AzureRmResourceGroupDeployment -TemplateUri "https://raw.githubusercontent.com/KstKrv/azure_arm/master/task2/initial_template.json" -ResourceGroupName $ResGroupName


# Azure CLI block

#az login
#az account set --subscription 7235b6ab-38ff-4c22-bca3-3b625f1f916b
#az group create -l westeurope --name $ResGroupName
#az group deployment create --template-uri "https://raw.githubusercontent.com/KstKrv/azure_arm/master/task2/main_template.json" --resource-group $ResGroupName