Param(
    [Parameter(Mandatory = $True, HelpMessage = "Give me resourse group name")]
    [string]$ResGroupName,
    [Parameter(Mandatory = $True, HelpMessage = "Give me resourse group location")]
    [string]$RGLocation,
    [Parameter(Mandatory = $True, HelpMessage = "Enter username for VMs")]
    [string]$Username,
    [Parameter(Mandatory = $True, HelpMessage = "Enter a password for VMs")]
    [securestring]$Password
)

# Some variables
$AutoAccTemplateURI = "https://raw.githubusercontent.com/KstKrv/azure_arm/master/Module9_task2/autoacc_template.json"
$TemplateURI = "https://raw.githubusercontent.com/KstKrv/azure_arm/master/Module9_task2/VM_template.json"
$TemplateParametersURI = "https://raw.githubusercontent.com/KstKrv/azure_arm/master/Module9_task2/VM_params.json"
$DSCURI = "https://raw.githubusercontent.com/KstKrv/azure_arm/master/Module9_task2/TestConfig.ps1"
$DSCPath = "$env:TEMP\TestConfig.ps1"
$ParametersFilePath = "$env:TEMP\main_params.json"

New-AzureRmResourceGroup -Name $ResGroupName -Location $RGLocation

# Automation account deployment and DSC configuration importing
New-AzureRmResourceGroupDeployment `
    -TemplateUri $AutoAccTemplateURI `
    -ResourceGroupName $ResGroupName `
    -Verbose

$automationAccountName = (Get-AzureRmAutomationAccount -ResourceGroupName $ResGroupName).AutomationAccountName

Invoke-WebRequest -Uri $DSCURI -OutFile $DSCPath

Import-AzureRmAutomationDscConfiguration `
    -SourcePath $DSCPath `
    -ResourceGroupName $ResGroupName `
    -AutomationAccountName $automationAccountName `
    -Published `
    -force

Remove-Item $DSCPath

$ConfigurationName = (Get-AzureRmAutomationDscConfiguration `
    -ResourceGroupName $ResGroupName `
    -AutomationAccountName $automationAccountName).name

start-AzureRmAutomationDscCompilationJob `
    -ConfigurationName $ConfigurationName  `
    -ResourceGroupName $ResGroupName `
    -AutomationAccountName $automationAccountName

# Receiving automation account unique keys
$registrationKey = ConvertTo-SecureString -AsPlainText -force `
((Get-AzureRmAutomationRegistrationInfo `
            -ResourceGroupName $ResGroupName `
            -AutomationAccountName $automationAccountName).PrimaryKey)

$registrationUrl = ConvertTo-SecureString -AsPlainText -force `
((Get-AzureRmAutomationRegistrationInfo `
            -ResourceGroupName $ResGroupName `
            -AutomationAccountName $automationAccountName).Endpoint)


# VMs deployment & configuring them as nodes
Invoke-WebRequest -Uri $templateParametersURI -OutFile $ParametersFilePath

New-AzureRmResourceGroupDeployment `
    -TemplateUri $TemplateURI `
    -ResourceGroupName $ResGroupName `
    -TemplateParameterFile $ParametersFilePath `
    -counter 2 `
    -Username $Username `
    -Password $Password `
    -registrationKey $registrationKey `
    -registrationUrl $registrationUrl `
    -Verbose

Remove-Item $ParametersFilePath

# Linking compiled DSC config to node
$node = (Get-AzureRmAutomationDscNode `
        -ResourceGroupName $ResGroupName `
        -automationAccountName $automationAccountName).id

$NodeConfigurationName = (Get-AzureRmAutomationDscNodeConfiguration `
        -ResourceGroupName $ResGroupName `
        -AutomationAccountName $automationAccountName).name

for ($i = 0; $i -lt $node.Count; $i++) {
    Set-AzureRmAutomationDscNode `
        -ResourceGroupName $ResGroupName `
        -AutomationAccountName $automationAccountName `
        -NodeConfigurationName $NodeConfigurationName[$i] `
        -Id $node[$i] `
        -Force
}