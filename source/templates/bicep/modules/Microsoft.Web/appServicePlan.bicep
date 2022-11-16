param name string
param location string = resourceGroup().location
param sku string
param skucode string
param workerSize string
param workerSizeId string
param numberOfWorkers string

resource appServicePlanResource 'Microsoft.Web/serverfarms@2018-11-01' = {
  name: name
  location: location
  kind: ''
  tags: {
  }
  properties: {
    name: name
    workerSize: workerSize
    workerSizeId: workerSizeId
    numberOfWorkers: numberOfWorkers
    reserved: false
    zoneRedundant: false
  }
  sku: {
    tier: sku
    name: skucode
  }
}

output appServicePlanResourceId string = appServicePlanResource.id
