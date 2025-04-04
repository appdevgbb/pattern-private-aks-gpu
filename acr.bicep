param principalId string
param registryResource resource

resource acrPull 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(registryResource.id, principalId, 'acrpull')
  scope: registryResource
    properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
    )
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
