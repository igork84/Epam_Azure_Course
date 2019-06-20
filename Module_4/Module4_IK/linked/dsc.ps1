Configuration IKWebsite {
   
    Import-DscResource -module  "PSDesiredStateConfiguration"
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration'

    Node $env:COMPUTERNAME {

        # Take files from Share
        WindowsFeature WebServerRole {
            Name   = "Web-Server"
            Ensure = "Present"
        }
        WindowsFeature WebManagementConsole
        {
            Name = "Web-Mgmt-Console"
            Ensure = "Present"
        }
        WindowsFeature WebManagementService
        {
            Name = "Web-Mgmt-Service"
            Ensure = "Present"
        }
        WindowsFeature ASPNet45
        {
            Name = "Web-Asp-Net45"
            Ensure = "Present"
        }       
        Script DeployWebPackage
		{
			GetScript = {@{Result = "DeployWebPackage"}}
			TestScript = {$false}
			SetScript ={
                
                New-WebBinding -Name "Default Web Site" -IP "*" -Port 8080 -Protocol http 
                New-NetFirewallRule -DisplayName "Allow TCP 8080" -Direction Inbound -Action Allow  -Protocol TCP -LocalPort 8080
                Get-ChildItem -path "C:\inetpub\wwwroot\" -File -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue
								
			}
			DependsOn  = "[WindowsFeature]WebServerRole"
        }
        xRemoteFile 'DownloadFile'
        {
            URI = "https://iksabase.blob.core.windows.net/ik-cont-main/linked/index.html"
            DestinationPath = "C:\inetpub\wwwroot\index.html"
        }
    }
}
