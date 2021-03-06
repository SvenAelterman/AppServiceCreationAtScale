# Academic Use App Service Creation at Scale
This sample script creates a number of App Service instances across App Service Plans.

## Function
This script uses the provided ARM templates to create the App Service Plans and App Services. You can customize the templates if you need to change the location, platform, framework, etc. Because it uses ARM templates, deployment is incremental.

At the end of the run, the script creates a CSV file with the usernames, passwords, and FTP publish URLs of the new App Services.

## Parameters

### rgName
The name of the resource group where App Service Plan(s) and App Service(s) will be created. It must already exist.

### classCode
Name for the App Service Plan(s), App Service(s), and output file also.

App Service Plan(s) and App Service(s) will have counters automatically added.

Example: if you provide `CS101-FA21` as the classCode value, your resources will look like this:

> app-CS101-FA21-001
> 
> app-CS101-FA21-002
> 
> ...
> 
> app-CS101-FA21-101
> 
> asp-CS101-FA21-001
> 
> asp-CS101-FA21-031
> 
> ...
> 
> asp-CS101-FA21-091

* The number of characters used for the counter will be based on the total number of App Services to be created.

### studentCount
The number of App Services to be created. For each 30 app services, an app service plan is created.

## Example

```PowerShell
.\New-AppServiceScale.ps1 'rg-AppServiceClass-eastus2-01' CS101-FA21 50
```

The command above will create 50 App Services across 2 App Service Plans (30 App Services in the first, 20 in the second) in an existing resource group `rg-AppServiceClass-eastus2-01`.
