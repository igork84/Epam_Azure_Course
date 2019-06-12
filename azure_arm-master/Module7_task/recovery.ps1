param(
[Parameter(Mandatory = $true, helpmessage = "Give me resourse group name")]
[string]$ResGroupName
)

$vault = Get-AzureRmRecoveryServicesVault

Set-AzureRmRecoveryServicesVaultContext -Vault $vault
$vmname = (get-azurermvm | where-object {$_.ResourceGroupName -eq $resgroupname}).name

$namedContainer = Get-AzureRmRecoveryServicesBackupContainer `
    -ContainerType "AzureVM" `
    -Status "Registered" `
    -FriendlyName $vmname

$item = Get-AzureRmRecoveryServicesBackupItem `
    -Container $namedContainer `
    -WorkloadType "AzureVM"

$rp = Get-AzureRmRecoveryServicesBackupRecoveryPoint -Item $Item 

$StorageAccountName = (Get-AzureRMstorageaccount -ResourceGroupName  $ResGroupName).StorageAccountName
Restore-AzureRmRecoveryServicesBackupItem `
    -RecoveryPoint $RP[0] `
    -StorageAccountName $StorageAccountName `
    -StorageAccountResourceGroupName $ResGroupName