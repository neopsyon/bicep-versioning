param appServicePlanName string
param appServiceName string
param appServiceStack string
param netFrameworkVersion string
param location string = resourceGroup().location
param sku string
param skucode string
param workerSize string
param workerSizeId string
param numberOfWorkers string

module appServicePlan 'br/myModules:appserviceplan:v1' = {
  name: 'appServicePlan'
  params: {
    name: appServicePlanName
    location: location
    sku: sku
    skucode: skucode
    workerSize: workerSize
    workerSizeId: workerSizeId
    numberOfWorkers: numberOfWorkers
  }
}

module appService 'br/myModules:appservice:v1' = {
  name: 'appService'
  params: {
    appServiceName: appServiceName
    location: location
    serverFarmId: appServicePlan.outputs.appServicePlanResourceId
    appServiceStack: appServiceStack
    netFrameworkVersion: netFrameworkVersion
  }
}
