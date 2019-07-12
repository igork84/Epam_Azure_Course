Configuration DataDisk
{
    Import-DscResource -module  "PSDesiredStateConfiguration"
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration'
    Import-DSCResource -ModuleName 'xStorage'

    Node localhost
    {
        #Creating Disk
        xWaitforDisk Disk2
        {
            DiskId = 2
            RetryIntervalSec = 60
            RetryCount = 60
        }
        #Creating Volume
        xDisk FVolume 
        {
            DiskId = 2
            DriveLetter = 'F'
            FSLabel = 'Data'
        }
        #Creating TestDirectory
        File MakeDirectory
        {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = 'F:\TestDir'
        }
        #Downloading TestFile
        xRemoteFile 'DownloadFileC'
        {
            URI = "https://iksabase.blob.core.windows.net/ik-cont-main/linked/index.html"
            DestinationPath = "F:\TestDir\index.html"
        }
    }
}