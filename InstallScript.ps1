function Get-TimeStamp {   
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

Write-Output "$(Get-TimeStamp) Running install script" | Out-file C:\install-process.txt -append
