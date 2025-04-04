param registryName string
param managedClusterName string = 'aks-${managedClusterName}'
param resourceGroupName string = 'rg-${managedClusterName}'
param location string = 'eastus2'

module infra 'aks.bicep' = {
  name: 'provisionInfra'
  scope: resourceGroup(resourceGroupName)
  params: {
    managedClusterName: managedClusterName
    location: location
  }
}

module attachAcr 'acr.bicep' = {
  name: 'grantAcrAccess'
  scope: resourceGroup(resourceGroupName)
  params: {
    principalId: infra.outputs.kubeletPrincipalId
    registryName: registryName
    location: location
  }
}
