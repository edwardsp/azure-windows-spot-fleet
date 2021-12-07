
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

mkdir C:\install

$kvname = $args[0]
(Get-Content -Path InstallScript.ps1).replace('__INSERT_KEYVAULT_NAME__', $kvname) | Set-Content -Path C:\install\InstallScript.ps1

$trigger = New-ScheduledTaskTrigger -AtStartup
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument '-ExecutionPolicy Unrestricted -File InstallScript.ps1' -WorkingDirectory "C:\install"
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName 'install' -Trigger $trigger -Action $action -Principal $principal

Start-ScheduledTask -TaskName 'install'
