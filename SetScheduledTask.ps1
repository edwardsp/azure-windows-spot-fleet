
mkdir C:\install
Copy-Item -Path InstallScript.ps1 -Destination C:\install\InstallScript.ps1

$trigger = New-ScheduledTaskTrigger -AtStartup
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument '-ExecutionPolicy Unrestricted -File InstallScript.ps1' -WorkingDirectory "C:\install"
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName 'install' -Trigger $trigger -Action $action -Principal $principal

Start-ScheduledTask -TaskName 'install'
