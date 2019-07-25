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
$RGName = "IK1Mod9RG"
$Location = "NorthEurope"
$SA = "iksabase"
$ContainerName = "ik-cont-main"
$KVName = 'KeyVaultIK'
$AppId = 'd3298af1-285b-4589-9d23-f8696e1e0bc0'

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
Get-ChildItem -File -Recurse | Set-AzStorageBlobContent -Container $ContainerName -Context $ctx

#Creating Pass Secret
write-mess -Text 'Creating Password Secret'
$PassRand = [system.web.security.membership]::GeneratePassword(10,2)
$Pass = ConvertTo-SecureString "$PassRand" -AsPlainText -Force

#Getting AppID Secret
write-mess -Text 'Getting AppID Secret'
$AppIdSecret = (Get-AzKeyVaultSecret -Vault $KVName -Name $AppId).SecretValue

#Generating SAStoken URI for workflow script
write-mess -Text 'Generating SAStoken URI for workflow script'
$accountKeys = Get-AzStorageAccountKey -ResourceGroupName $RGName -Name $SA
$storageContext = New-AzStorageContext -StorageAccountName $SA -StorageAccountKey $accountKeys[0].Value
$scriptUri = ConvertTo-SecureString -force -AsPlainText (New-AzStorageBlobSASToken `
    -Container $ContainerName `
    -Blob "Workflow_Stop-AzureVM.ps1" `
    -Permission "rwl" `
    -StartTime (Get-Date).AddHours(-1) `
    -ExpiryTime (get-date).AddMonths(1) `
    -Context $storageContext `
    -FullUri) 

#Generating Job ID for automation account
$JobID = [System.Guid]::NewGuid().toString()

#Starting deployment
write-mess -Text 'Starting deployment'
New-AzResourceGroupDeployment `
    -TemplateFile "main_template.json" `
    -ResourceGroupName $RGName `
    -TemplateParameterFile "main_params.json" `
    -Password $Pass `
    -JobID $jobID `
    -scriptUri $scriptUri `
    -appID $appID `
    -appidsecret $AppIdSecret `
    -Verbose


#End of part one