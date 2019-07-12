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
$RGName = "IKMod7RG"
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
# write-mess -Text 'Creating Sas Token'
# $sastokenurl = New-AzStorageContainerSASToken -Name $ContainerName -Permission rwl -StartTime (Get-Date).AddHours(-1) `
#  -ExpiryTime (get-date).AddMonths(1) -Context $ctx

#Tecting ARM Templates
write-mess -Text 'Tecting ARM Templates'
Test-AzResourceGroupDeployment -TemplateFile "main_template.json" `
-ResourceGroupName $RGName -TemplateParameterFile "main_params.json" -secretValue $Pass -Verbose

#Deploying ARM Templates
write-mess -Text 'Deploying ARM Templates'
New-AzResourceGroupDeployment -TemplateFile "main_template.json" `
-ResourceGroupName $RGName -TemplateParameterFile "main_params.json" -secretValue $Pass -Verbose

#Backing up created VM
write-mess -Text 'Backup Proccess'
$vault = Get-AzRecoveryServicesVault
Set-AzRecoveryServicesVaultContext -Vault $vault
$policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "MyCustomPolicy" 
Enable-AzRecoveryServicesBackupProtection -ResourceGroupName $RGName -Name (get-azvm).name -Policy $policy
$backupcontainer = Get-AzRecoveryServicesBackupContainer `
    -ContainerType "AzureVM" `
    -FriendlyName (get-azvm).name

$item = Get-AzRecoveryServicesBackupItem `
    -Container $backupcontainer `
    -WorkloadType "AzureVM"

Backup-AzRecoveryServicesBackupItem -Item $item -Verbose

write-mess -Text 'Backup Proccess Workflow'
$BackupJob = Get-AzRecoveryServicesBackupJob
do {
    Write-Host "Backup VM status in progress! Please wait..."
    Start-Sleep -s 150
    $BackupJob = Get-AzRecoveryServicesBackupJob
    }
while ($BackupJob[0].status -eq 'InProgress')
if(($BackupJob[0].Status -eq 'Completed') -and ($BackupJob[0].Operation -eq 'Backup')) {
    Write-Host "VM is Backed UP! Please start recovery process
    by executing recovery_convert_deploy.ps1 script!" -ForegroundColor Green
    }