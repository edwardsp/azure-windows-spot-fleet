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
var scriptLocation = 'https://raw.githubusercontent.com/edwardsp/azure-windows-spot-fleet/main'

resource spotfleet 'Microsoft.Compute/virtualMachineScaleSets@2021-07-01' = {
  name: vmssName
  location: location
  sku: {
    name: 'Standard_HB120rs_v2'
    capacity: instanceCount
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    overprovision: false
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
              settings: {
                fileUris: [
                  '${scriptLocation}/SetScheduledTask.ps1'
                  '${scriptLocation}/InstallScript.ps1'
                ]
              }
              typeHandlerVersion: '1.8'
              autoUpgradeMinorVersion: true
              protectedSettings: {
                commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File SetScheduledTask.ps1'
              }
              type: 'CustomScriptExtension'
            }
          }
        ]
      }
    }
  }
}
