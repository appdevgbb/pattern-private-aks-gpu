param registryName string
param clusterName string
param managedClusterName string = 'aks-${clusterName}'
param resourceGroupName string = 'rg-${managedClusterName}'
param location string = 'eastus2'

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
  scope: resourceGroup(resourceGroupName)
  params: {
    principalId: infra.outputs.kubeletPrincipalId
    registries: infra.outputs.registries
  }
}
