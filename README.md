# Academic Use App Service Creation at Scale

This sample script creates many App Service instances across App Service Plans.

It can create a large number of Azure App Services (web apps) with the same configuration, which is a common use case for introductory web development courses.

After the resource creation is complete, it will create a CSV file containing one row per App Service. Each row will have the necessary information to access and publish the site.

## Operation

This script uses the provided Bicep templates to create the App Service Plans and App Services. You can customize the templates and parameters if you need to change the location, platform, framework, etc. Because it uses Bicep templates, deployment is incremental.

## Required Parameters

The required parameters are listed in the order in which they should be specified if not providing an explicit name. See the [Example](#example) below.

### ResourceGroupName

The name of the resource group where App Service Plan(s) and App Service(s) will be created. If it does not already exist, it will be created.

### ClassCode

Name for the App Service Plan(s), App Service(s), and output file.

Prefixes and counters will be added automatically to App Service Plan(s) and App Service(s) names.

Example: if you provide `CS101-FA21` as the ClassCode value and `50` as the StudentCount, the names of the App Services resources will be:

* app-CS101-FA21-1-01
* app-CS101-FA21-1-02
* ...
* app-CS101-FA21-1-25
* asp-CS101-FA21-2-01
* asp-CS101-FA21-2-02
* ...
* asp-CS101-FA21-2-25

> The number of characters used for the counters will be based on the total number of App Service Plans and App Services to be created.

### StudentCount

The number of App Services to be created.

## Example

```PowerShell
.\New-AppServiceScale.ps1 'rg-AppServiceClass-eastus-01' 'CS101-FA21' 50
```

The command above will create `50` App Services across 2 App Service Plans (25 App Services in each plan) in the resource group `rg-AppServiceClass-eastus-01` in the East US.

## Optional Parameters (PowerShell)

### Location = eastus

The target region of the deployment.

## Optional Parameters (Bicep)

These optional parameters can provide further customization of the deployment. At this time, the PowerShell script doesn't accept parameters for these optional Bicep parameters.

> Additional optional parameters are available in the AppServicePlan.bicep and AppService.bicep files. Using those parameters will require modifying the main.bicep or AppServicePlan.bicep files to pass values.

### OS = 'linux'

Valid values are `linux` or `windows`.

### linuxFxVersion = 'NODE|18-lts'

This is only applicable if the OS is Linux.

### maxAppsPerPlan = 30

The absolute maximum number of App Services per App Service Plan is 100. Because all App Services share the compute resources (CPU, I/O, RAM, and storage) of their App Service Plan, the maximum might not be achievable.

### dateCreatedTagValue = uctNow('yyyy-MM-dd')

Useful if you need to redeploy the App Services but you want to retain the previous `date-created` tag's value.

### tags = {}

Tags to add to each App Service Plan and App Service.

> **NOTE:** The deployment will add the following default tags automatically:
>
> * date-created = *dateCreatedTagValue parameter value*
> * lifetime = medium
> * purpose = demo
> * OS = *OS parameter value*
