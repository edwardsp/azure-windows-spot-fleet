function Get-TimeStamp {   
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

$logfile = 'C:\install\install-progress.txt'

if (-not(Test-Path -Path $logfile -PathType Leaf)) {
    Add-Content -Path 'C:\install\install-progress.txt' -Value "$(Get-TimeStamp) First run of the install script"
    Restart-Computer
}
else {
    Add-Content -Path 'C:\install\install-progress.txt' -Value "$(Get-TimeStamp) Running install script after a reboot"
}
