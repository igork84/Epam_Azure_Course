Configuration IKfile
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
            DependsOn = "[xWaitforDisk]Disk2"
        }
        #Creating TestDirectory
        File MakeDirectory
        {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = 'F:\TestDir'
            DependsOn = "[xDisk]FVolume"
        }
        #Creating TestDirectory
        File File
        {
            Ensure = 'Present'
            Type = 'File'
            DestinationPath = 'F:\TestDir\test.txt'
            DependsOn = "[File]MakeDirectory"
            Contents = 'This is file for Module Lab 7 by Ihar Kuvaldzin'
        }
    }
}
