param location string = resourceGroup().location

@description('String used as a base for naming resources.')
@maxLength(8)
param vmssName string

@description('Number of VM instances.')
@minValue(0)
@maxValue(1000)
param instanceCount int = 1

@description('Admin username on all VMs.')
param adminUsername string

@description('Admin password on all VMs.')
@secure()
param adminPassword string

var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet', 'spotfleet')
//var sku = 'Standard_HB120rs_v2'
var sku = 'Standard_E32s_v3'

var resourceGroupId = resourceGroup().id
var identityName = 'id-${uniqueString(resourceGroup().id)}'
var kvName = 'kv-${uniqueString(resourceGroup().id)}'

var setScheduledTask = replace('''
mkdir C:\install
copy C:\AzureData\CustomData.bin C:\install\InstallScript.ps1
$trigger = New-ScheduledTaskTrigger -AtStartup
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument '-ExecutionPolicy Unrestricted -File InstallScript.ps1' -WorkingDirectory "C:\install"
$principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName 'install' -Trigger $trigger -Action $action -Principal $principal
Start-ScheduledTask -TaskName 'install'
''', '\n', ';')

var powershellScript = replace('''
if (!(Get-Command -Name az)) {
  $AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
  [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
  $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
}

function Get-TimeStamp {   
  return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

az login -i

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

''', '__INSERT_KEYVAULT_NAME__', kvName)

resource spotfleet 'Microsoft.Compute/virtualMachineScaleSets@2021-07-01' = {
  name: vmssName
  location: location
  zones: null
  sku: {
    name: sku
    capacity: instanceCount
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${resourceGroupId}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${identityName}': {}
    }
  }
  properties: {
    overprovision: true
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      priority: 'Spot'
      billingProfile: {
        maxPrice: -1
      }
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2016-Datacenter'
          version: 'latest'
        }
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername: adminUsername
        adminPassword: adminPassword
        customData: base64(powershellScript)
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: {
                      id: subnetRef
                    }
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          {
            name: 'customScript'
            properties: {
              publisher: 'Microsoft.Compute'
              typeHandlerVersion: '1.8'
              autoUpgradeMinorVersion: true
              protectedSettings: {
                commandToExecute: 'powershell -ExecutionPolicy Unrestricted -Command "${setScheduledTask}"'
              }
              type: 'CustomScriptExtension'
            }
          }
        ]
      }
    }
  }
}
