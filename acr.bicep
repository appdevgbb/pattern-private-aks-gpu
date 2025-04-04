param principalId string
param registryId string

resource acrPull 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(registryId, principalId, 'acrpull')
  scope: registryId
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
    )
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
