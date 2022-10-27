param appName string
param appServicePlanId string
param linuxFxVersion string = 'NODE|14-lts'
param location string = 'East US 2'
param dateCreatedTagValue string = utcNow('yyyy-MM-dd')

@allowed([
  'Linux'
  'Windows'
])
param OS string = 'Linux'

resource appName_resource 'Microsoft.Web/sites@2022-03-01' = {
  name: appName
  location: location
  tags: {
    'date-created': dateCreatedTagValue
    lifetime: 'medium'
    purpose: 'demo'
  }
  properties: {
    siteConfig: {
      appSettings: []
      linuxFxVersion: (OS == 'Linux') ? linuxFxVersion : ''
      alwaysOn: true
      ftpsState: 'FtpsOnly'
    }
    serverFarmId: appServicePlanId
    clientAffinityEnabled: false
  }
}

resource linuxConfig 'Microsoft.Web/sites/config@2022-03-01' = if (OS == 'Linux') {
  name: 'web'
  parent: appName_resource
  properties: {
    javaContainer: 'TOMCAT'
    javaContainerVersion: '10.0'
    javaVersion: '11.0.14'
    appCommandLine: 'pm2 serve /home/site/wwwroot --no-daemon'
  }
}

//resource winConfig 'Microsoft.Web/sites/config@2022-03-01' = if (OS != 'Linux') {
//  name: 'web'
//  parent: appName_resource
//  properties: {
//    netFrameworkVersion: 'v4.0'
//  }
//}
