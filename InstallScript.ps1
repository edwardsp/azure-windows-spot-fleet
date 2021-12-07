function Get-TimeStamp {   
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

$logfile = 'C:\install\install-progress.txt'

$kvname = '__INSERT_KEYVAULT_NAME__'

$secret = (az keyvault secret show --vault-name $kvname --name mysecret | ConvertFrom-Json).value

if (-not(Test-Path -Path $logfile -PathType Leaf)) {
    Add-Content -Path $logfile -Value "$(Get-TimeStamp) First run of the install script (secret='$secret')"
    Start-Sleep -Seconds 10
    Restart-Computer -Force
}
else {
    Add-Content -Path $logfile -Value "$(Get-TimeStamp) Running install script after a reboot (secret='$secret')"
}
