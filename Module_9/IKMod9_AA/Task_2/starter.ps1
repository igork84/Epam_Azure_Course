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

#Some variables
$RGName = 'IK2Mod9RG'
$Location = 'northeurope'
$SA = 'iksabase'
$ContainerName = 'ik-cont-main'
$FilePath = 'https://iksabase.blob.core.windows.net/ik-cont-main/linked/'
$AutoAccTemplateURI = "$FilePath" + "autoacc_template.json"
$DSCURI = "$FilePath" + "IISWebsite.ps1"
$DSCPath = "$env:TEMP\IISWebsite.ps1"

#Creating Pass Secret
write-mess -Text 'Creating Password Secret'
$PassRand = [system.web.security.membership]::GeneratePassword(10,2)
$Password = ConvertTo-SecureString "$PassRand" -AsPlainText -Force

#Create Resource Group
write-mess -Text 'Ctreating Resource Group'
New-AzResourceGroup -Name $RGName -Location $Location

#Create Storage Account
write-mess -Text 'Creating Base Storage Account and BLOB Container'
$storageAccount = New-AzStorageAccount -Name $SA -ResourceGroupName $RGName -SkuName Standard_LRS -Location $Location
$ctx = $storageAccount.Context
New-AzStorageContainer -Name $ContainerName -Context $ctx -Permission Blob

#Upload ARM Template files in created container
write-mess -Text 'Uploading ARM Templates in Azure stprage'
Get-ChildItem -File -Recurse | Set-AzStorageBlobContent -Container $ContainerName -Context $ctx

#Configuring Sastoken
$sastokenurl = New-AzStorageContainerSASToken -Name $ContainerName -Permission rwl -StartTime (Get-Date).AddHours(-1) `
 -ExpiryTime (get-date).AddMonths(1) -Context $ctx

#Automation account deployment and DSC configuration importing
write-mess -Text 'Creating Automation Account'
New-AzResourceGroupDeployment `
    -TemplateUri $AutoAccTemplateURI `
    -ResourceGroupName $RGName `
    -sastokenurl $sastokenurl `
    -Verbose

$automationAccountName = (Get-AzAutomationAccount -ResourceGroupName $RGName).AutomationAccountName

Invoke-WebRequest -Uri $DSCURI -OutFile $DSCPath

write-mess -Text 'Import DSCConfiguration'
Import-AzAutomationDscConfiguration `
    -SourcePath $DSCPath `
    -ResourceGroupName $RGName `
    -AutomationAccountName $automationAccountName `
    -Published `
    -force

Remove-Item $DSCPath

#Receiving automation account unique keys
$registrationKey = ConvertTo-SecureString -AsPlainText -force `
((Get-AzAutomationRegistrationInfo `
    -ResourceGroupName $RGName `
    -AutomationAccountName $automationAccountName).PrimaryKey)

$registrationUrl = ConvertTo-SecureString -AsPlainText -force `
((Get-AzAutomationRegistrationInfo `
    -ResourceGroupName $RGName `
    -AutomationAccountName $automationAccountName).Endpoint)

#VMs deployment & configuring them as nodes
write-mess -Text 'VMs deployment & configuring them as nodes'
New-AzResourceGroupDeployment `
    -TemplateFile 'main_template.json' `
    -ResourceGroupName $RGName `
    -TemplateParameterFile 'main_params.json' `
    -Password $Password `
    -registrationKey $registrationKey `
    -registrationUrl $registrationUrl `
    -Verbose

#Getting Configuration Name
$ConfigurationName = (Get-AzAutomationDscConfiguration `
-ResourceGroupName $RGName `
-AutomationAccountName $automationAccountName).name

#Compilation Job
write-mess -Text 'Start DSC Compilation Job'
$VMs = get-azvm -ResourceGroupName $RGName
$Params1 = @{"NodeName"= $VMs[0].Name}
start-AzAutomationDscCompilationJob `
-ConfigurationName $ConfigurationName  `
-ResourceGroupName $RGName `
-AutomationAccountName $automationAccountName `
-Parameters $Params1 `
-Verbose

$Params2 = @{"NodeName"= $VMs[1].Name}
start-AzAutomationDscCompilationJob `
-ConfigurationName $ConfigurationName  `
-ResourceGroupName $RGName `
-AutomationAccountName $automationAccountName `
-Parameters $Params2 `
-Verbose

#Linking compiled DSC config to node
write-mess -Text 'Linking compiled DSC config to node'
$node = (Get-AzAutomationDscNode `
        -ResourceGroupName $RGName `
        -automationAccountName $automationAccountName).id

$NodeConfigurationName = (Get-AzAutomationDscNodeConfiguration `
        -ResourceGroupName $RGName `
        -AutomationAccountName $automationAccountName).name

for ($i = 0; $i -lt $node.Count; $i++) {
    Set-AzAutomationDscNode `
        -ResourceGroupName $RGName `
        -AutomationAccountName $automationAccountName `
        -NodeConfigurationName $NodeConfigurationName[$i] `
        -Id $node[$i] `
        -Force `
        -Verbose
}