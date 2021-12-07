var kvName = 'kv-${uniqueString(resourceGroup().id)}'
var location = resourceGroup().location
var identityName = 'id-${uniqueString(resourceGroup().id)}'
var keyVaultSecretsUserRoleDefinitionId = '4633458b-17de-408a-b874-0445c86b69e6'

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: location
}

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: kvName
  location: location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: userIdentity.properties.tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  parent: kv
  name: 'mysecret'
  properties: {
    value: 'top secret contents'
  }
}

resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(keyVaultSecretsUserRoleDefinitionId,userIdentity.id,kv.id)
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleDefinitionId)
    principalId: userIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
