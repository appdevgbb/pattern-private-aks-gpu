param registryName string
param clusterName string
param managedClusterName string = 'aks-${clusterName}'
param resourceGroupName string = 'rg-${managedClusterName}'
param location string = 'eastus2'
param subscriptionId string

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: registryName
  scope: resourceGroup(resourceGroupName)
}

module infra 'aks.bicep' = {
  name: 'provisionInfra'
  scope: resourceGroup(resourceGroupName)
  params: {
    clusterName: managedClusterName
    location: location
    registryName: registryName
  }
}

module attachAcr 'acr.bicep' = {
  name: 'grantAcrAccess'
  scope: subscription()
  params: {
    principalId: infra.outputs.kubeletPrincipalId
    registryId: acr.id
  }
}
