1. Сначала надо запустить скрипт deploy_and_backup.ps1. Он развернёт ресурсы и запустит процесс выполнения бэкапа. (~1.5 часа)

2. После того, как бэкап будет готов запускаем скрипт recovery.ps1. Он выполняет восстановление дисков и конфигов из бэкапа. (~1 час)
 
3. Когда vhd появятся в сторадж аккаунте, запускаем скрипт Convert_and_deploy.ps1, подаём ему на вход ресурсную группу, в которой лежат vhd и имя новой ресурсной группы, после чего скрипт развернёт в новой ресурсной группе ВМ из восстановленных дисков.