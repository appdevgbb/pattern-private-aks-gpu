param registryName string
param clusterName string
param managedClusterName string = clusterName
param resourceGroupName string = 'rg-${managedClusterName}'
param location string = 'eastus2'
param gpuVMSKU string = 'Standard_NC40ads_H100_v5'

module infra 'aks.bicep' = {
  name: 'provisionInfra'
  scope: resourceGroup(resourceGroupName)
  params: {
    clusterName: managedClusterName
    location: location
    registryName: registryName
    gpuSKU: gpuVMSKU
  }
}
