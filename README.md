# AppServiceCreationAtScale
This sample script creates a number of App Service instances across App Service Plans.

## Function
This script uses the provided ARM templates to create the App Service Plans and App Services. You can customize the templates as you need to change the location, platform, framework, etc.

At the end of the run, the script creates a CSV file with the usernames, passwords, and FTP publish URLs of the new App Services.

Because it uses ARM templates, deployment is incremental.

## Parameters

### rgName
The name of the resource group where App Service Plan(s) and App Service(s) will be created.

### classCode
Name for the App Service Plan and App Services. Default name of the output file also.

### studentCount
The number of App Services to be created. For each 30 app services, an app service plan is created.


