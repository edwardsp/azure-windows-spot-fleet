param location string = resourceGroup().location

@description('String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure. A hash is prepended to this string for some resources, and resource-specific information is appended.')
@maxLength(61)
param vmssName string

@description('Number of VM instances.')
@minValue(0)
@maxValue(1000)
param instanceCount int = 2

@description('Admin username on all VMs.')
param adminUsername string

@description('Admin password on all VMs.')
@secure()
param adminPassword string

var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet', 'spotfleet')
var scriptLocation = 'https://raw.githubusercontent.com/edwardsp/azure-spot-fleet-example/master/InstallScript.ps1'

resource spotfleet 'Microsoft.Compute/virtualMachineScaleSets/extensions@2021-07-01' = {
  name: vmssName
  location: location
  sku: {
    name: 'Standard_HB120rs_v2'
    capacity: instanceCount
  }
  properties: {
    overprovision: 'true'
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
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
                  scriptLocation
                ]
              }
              typeHandlerVersion: '1.8'
              autoUpgradeMinorVersion: true
              protectedSettings: {
                commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File InstallScript.ps1'
              }
              type: 'CustomScriptExtension'
            }
          }
        ]
      }
    }
  }
}
