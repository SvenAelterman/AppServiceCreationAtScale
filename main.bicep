targetScope = 'subscription'

param resourceGroupName string = 'rg-appsvcscale-test-eastus-01'
param classCode string = 'test02'
param location string = 'eastus'

@allowed([
  'linux'
  'windows'
])
param OS string = 'linux'
param linuxFxVersion string = 'NODE|14-lts'
@minValue(1)
param studentCount int = 11
@minValue(1)
@maxValue(100)
param maxAppsPerPlan int = 10
param dateCreatedTagValue string = utcNow('yyyy-MM-dd')

param tags object = {}

var defaultTags = {
  'date-created': dateCreatedTagValue
  lifetime: 'medium'
  purpose: 'demo'
  OS: OS
}

var actualTags = union(tags, defaultTags)

// Calculate the number of App Service Plans required
var plansRequired = ((studentCount / maxAppsPerPlan) + ((studentCount % maxAppsPerPlan) > 0 ? 1 : 0))
// Calculate the average required apps per plan
var avgAppsPerPlan = studentCount / plansRequired
// Calculate the number of apps to be deployed in each plan
var actualAppsPerPlan = [for i in range(1, plansRequired): (studentCount / plansRequired + ((plansRequired * avgAppsPerPlan < studentCount) && (studentCount - plansRequired * avgAppsPerPlan >= i) ? 1 : 0))]

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module appServiceAndPlanModule 'AppServicePlan-template.bicep' = [for i in range(1, plansRequired): {
  name: 'appServiceAndPlan-${i}-${classCode}'
  scope: resourceGroup
  params: {
    location: location
    appCount: actualAppsPerPlan[i - 1]
    planIndex: i
    classCode: classCode
    tags: actualTags
    linuxFxVersion: linuxFxVersion
  }
}]

// For verification, ensure that the number of apps matches the number of students
var numberOfAppsCalculated = reduce(actualAppsPerPlan, 0, (cur, prev) => cur + prev)

//output hostNamesToFlat array = flatten([for i in range(0, plansRequired): appServiceAndPlan[i].outputs.hostNames])

output plansRequired int = plansRequired
output avgAppsPerPlan int = avgAppsPerPlan
output actualAppsPerPlan array = actualAppsPerPlan
output numberOfAppsCalculated int = numberOfAppsCalculated
output numberOfAppsMatchesStudentCount bool = (studentCount == numberOfAppsCalculated)

output hostNames array = [for i in range(0, plansRequired): reduce(appServiceAndPlanModule[i].outputs.hostNames, null, (previous, current) => '${previous},${current}')]
//output hostNames array = map(reduce(appServiceAndPlan, [], ), arg => arg.outputs.hostNames)
