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
$RGName = "IKMod4RG"
$Location = "NorthEurope"
$SA = "iksabase"
$ContainerName = "ik-cont-main"

#Create Resource Group
write-mess -Text 'Ctreating Resource Group'
New-AzResourceGroup -Name $RGName -Location $Location

#Create Storage Account
write-mess -Text 'Creating Storage Account and BLOB Container
for uploading ARM Templates files...'
$storageAccount = New-AzStorageAccount -Name $SA -ResourceGroupName $RGName -SkuName Standard_LRS -Location $Location
$ctx = $storageAccount.Context
New-AzStorageContainer -Name $ContainerName -Context $ctx -Permission Blob

#Upload ARM Template files in created container
Get-ChildItem -File -Recurse -Exclude "*.ps1" | Set-AzStorageBlobContent -Container $ContainerName -Context $ctx

#Creating Pass Secret
write-mess -Text 'Creating Password Secret'
$PassRand = [system.web.security.membership]::GeneratePassword(10,2)
$Pass = ConvertTo-SecureString "$PassRand" -AsPlainText -Force

#Creating Sas Token
write-mess -Text 'Creating Sas Token'
$sastokenurl = New-AzStorageBlobSASToken -Container $ContainerName -Blob ".\linked\dsc.ps1.zip" -Permission rwl -StartTime (Get-Date).AddHours(-1) `
-ExpiryTime (get-date).AddMonths(1) -FullUri -Context $ctx

#Deploying ARM Templates
write-mess -Text 'Deploying ARM Templates'
New-AzResourceGroupDeployment -TemplateFile "main_template.json" `
-ResourceGroupName $RGName -sastokenurl $sastokenurl -TemplateParameterFile "main_params.json" -secretValue $Pass -Verbose