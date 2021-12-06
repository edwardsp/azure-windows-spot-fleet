function Get-TimeStamp {   
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

Add-Content -Path 'C:\install\install-progress.txt' -Value "$(Get-TimeStamp) Running install script"