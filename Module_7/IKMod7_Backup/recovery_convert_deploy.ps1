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
$OldRGName = "IKMod7RG"
$BackupRG = (Get-AzResourceGroup -Name "*Backup*").ResourceGroupName

#Recovery Process
write-mess -Text 'Start Recovery Process'
$vault = Get-AzRecoveryServicesVault
Set-AzRecoveryServicesVaultContext -Vault $vault

$vmname = (get-azvm | where-object {$_.ResourceGroupName -eq $OldRGName}).name

$backupcontainer = Get-AzRecoveryServicesBackupContainer `
    -ContainerType "AzureVM" `
    -FriendlyName $vmname

$item = Get-AzRecoveryServicesBackupItem `
    -Container $backupcontainer `
    -WorkloadType "AzureVM"
    
$RP = Get-AzRecoveryServicesBackupRecoveryPoint -Item $Item 

$StorageAccountName = Get-AzStorageAccount -ResourceGroupName $OldRGName | Where-Object {$_.StorageAccountName -like "ikmod7rg*"}

Restore-AzRecoveryServicesBackupItem `
-RecoveryPoint $RP `
-StorageAccountName $StorageAccountName.StorageAccountName `
-StorageAccountResourceGroupName $BackupRG `
-Verbose

# Getting disks names
$context = (Get-AzStorageAccount -ResourceGroupName $OldRGName)[1].Context
$container = (Get-AzStorageContainer -Context $context).Name

$OsDiskUri = (Get-AzStorageBlob -Container $Container -Context $Context -Blob *.vhd | Where-Object {$_.name -like "*osdisk*"}).ICloudBlob.Uri.AbsoluteUri
$DataDiskUri = (Get-AzStorageBlob -Container $Container -Context $Context -Blob *.vhd | Where-Object {$_.name -like "*datadisk*"}).ICloudBlob.Uri.AbsoluteUri

# Starting a deploy
write-mess -Text 'Start New VM Deployment Process'

Test-AzResourceGroupDeployment `
    -ResourceGroupName $BackupRG `
    -TemplateFile 'main_2template.json' `
    -TemplateParameterFile 'main_2params.json' `
    -OsDiskUri $OsDiskUri `
    -DataDiksUri $DataDiskUri `
    -Verbose

New-AzResourceGroupDeployment `
    -ResourceGroupName $BackupRG `
    -TemplateFile 'main_2template.json' `
    -TemplateParameterFile 'main_2params.json' `
    -OsDiskUri $OsDiskUri `
    -DataDiksUri $DataDiskUri `
    -Verbose

# Remove-Item $ParametersFilePath