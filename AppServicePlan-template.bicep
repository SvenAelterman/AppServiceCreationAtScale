param aspName string
param dateCreatedTagValue string = utcNow('yyyy-MM-dd')
param location string = 'eastus2'

@allowed([
  'linux'
  'Windows'
])
param OS string = 'linux'

resource aspName_resource 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: aspName
  location: location
  tags: {
    'date-created': dateCreatedTagValue
    lifetime: 'medium'
    purpose: 'demo'
    OS: OS
  }
  sku: {
    tier: 'Standard'
    name: 'S1'
  }
  kind: (OS == 'linux') ? OS : 'app'
  properties: {
    workerSize: '0'
    workerSizeId: '0'
    numberOfWorkers: '1'
    reserved: true
  }
}
