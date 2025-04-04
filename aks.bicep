param clusterName string
param managedClusterName string = 'aks-${clusterName}'
param vnetName string = 'vnet-${managedClusterName}'
param subnetName string = 'subnet-${managedClusterName}'
param location string

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.1.0.0/24'
        }
      }
    ]
  }
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: '${managedClusterName}-log'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      legacy: 0
    }
  }
}

resource managedCluster 'Microsoft.ContainerService/managedClusters@2024-10-01' = {
  name: managedClusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.30.10'
    dnsPrefix: '${managedClusterName}-dns'
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 2
        vmSize: 'Standard_D4ds_v5'
        osDiskSizeGB: 150
        osDiskType: 'Ephemeral'
        kubeletDiskType: 'OS'
        maxPods: 110
        type: 'VirtualMachineScaleSets'
        maxCount: 5
        minCount: 2
        enableAutoScaling: true
        scaleDownMode: 'Delete'
        powerState: {
          code: 'Running'
        }
        orchestratorVersion: '1.30.10'
        enableNodePublicIP: false
        mode: 'System'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        upgradeSettings: {
          maxSurge: '10%'
        }
        enableFIPS: false
        securityProfile: {
          enableVTPM: false
          enableSecureBoot: false
        }
      }
      {
        name: 'gpunp'
        count: 1
        vmSize: 'Standard_NC40ads_H100_v5'
        osDiskSizeGB: 322
        osDiskType: 'Ephemeral'
        kubeletDiskType: 'OS'
        maxPods: 30
        type: 'VirtualMachineScaleSets'
        availabilityZones: [
          '2'
        ]
        enableAutoScaling: false
        scaleDownMode: 'Delete'
        powerState: {
          code: 'Running'
        }
        orchestratorVersion: '1.30.10'
        enableNodePublicIP: false
        mode: 'User'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        upgradeSettings: {
          maxSurge: '10%'
        }
        enableFIPS: false
        securityProfile: {
          enableVTPM: false
          enableSecureBoot: false
        }
      }
     ]
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    addonProfiles: {
      omsAgent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: workspace.id
          useAADAuth: 'true'
        }
      }
    }
    enableRBAC: true
    supportPlan: 'KubernetesOfficial'
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      networkPolicy: 'cilium'
      networkDataplane: 'cilium'
      loadBalancerSku: 'Standard'
      podCidr: '10.244.0.0/16'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
      outboundType: 'loadBalancer'
      podCidrs: [ '10.244.0.0/16' ]
      serviceCidrs: [ '10.0.0.0/16' ]
    }
    apiServerAccessProfile: {
      enablePrivateCluster: true
      privateDNSZone: 'system'
      enablePrivateClusterPublicFQDN: true
    }
    autoUpgradeProfile: {
      upgradeChannel: 'none'
      nodeOSUpgradeChannel: 'SecurityPatch'
    }
    disableLocalAccounts: false
    securityProfile: {
      imageCleaner: {
        enabled: true
        intervalHours: 168
      }
      workloadIdentity: {
        enabled: true
      }
    }
    oidcIssuerProfile: {
      enabled: true
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${managedClusterName}-pe'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'kube-apiserver-connection'
        properties: {
          privateLinkServiceId: managedCluster.id
          groupIds: [ 'management' ]
        }
      }
    ]
  }
}

output kubeletPrincipalId string = managedCluster.properties.identityProfile.kubeletidentity.objectId
