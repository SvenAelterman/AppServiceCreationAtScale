param location string
param classCode string

@minValue(1)
param appCount int = 1
@minValue(1)
param planIndex int = 1
param linuxFxVersion string = 'NODE|18-lts'

param tags object = {}

@allowed([
  'linux'
  'windows'
])
param OS string = 'linux'

var planIndexFormatted = padLeft(planIndex, length(string(planIndex)), '0')
var aspName = 'asp-${classCode}-${planIndexFormatted}'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: aspName
  location: location
  tags: tags
  sku: {
    tier: 'Standard'
    name: 'S1'
  }
  kind: (OS == 'linux') ? OS : 'app'
  properties: {
    reserved: true
  }
}

module appServiceModule 'AppService.bicep' = [for i in range(1, appCount): {
  name: 'appService-${aspName}-${i}'
  params: {
    appName: 'app-${classCode}-${planIndex}-${padLeft(i, length(string(appCount)), '0')}'
    appServicePlanId: appServicePlan.id
    location: location
    linuxFxVersion: linuxFxVersion
    tags: tags
  }
}]

output planIndex int = planIndex
output appNames array = [for i in range(0, appCount): appServiceModule[i].outputs.appName]
output appServicePlanName string = appServicePlan.name
