param appServiceName string
param location string = resourceGroup().location
param serverFarmId string
param alwaysOn bool = false
param ftpsState string = 'FtpsOnly'
param appServiceStack string
param phpVersion string = 'OFF'
param netFrameworkVersion string

resource appServiceResource 'Microsoft.Web/sites@2018-11-01' = {
  name: appServiceName
  location: location
  tags: {
  }
  properties: {
    name: appServiceName
    siteConfig: {
      appSettings: []
      metadata: [
        {
          name: 'CURRENT_STACK'
          value: appServiceStack
        }
      ]
      phpVersion: phpVersion
      netFrameworkVersion: netFrameworkVersion
      alwaysOn: alwaysOn
      ftpsState: ftpsState
    }
    serverFarmId: serverFarmId
    clientAffinityEnabled: true
    virtualNetworkSubnetId: null
    httpsOnly: true
  }
  dependsOn: []
}

output appServiceResourceId string = appServiceResource.id
