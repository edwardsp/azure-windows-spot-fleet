resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: 'vnet'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'infra'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'spotfleet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

