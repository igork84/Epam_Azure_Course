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
        #Creating TestFile
        File TestFile
        {
            Ensure = 'Present'
            Type = 'File'
            DestinationPath = 'F:\TestDir\testfile.txt'
            Contents = 'This is test file for Lab7 by Ihar Kuvaldzin'
            DependsOn = "[File]MakeDirectory"
        }
    }
}