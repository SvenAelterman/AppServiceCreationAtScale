[CmdletBinding()]
param (
	[Parameter(Mandatory, Position = 1)]
	[string]$rgName,
	[Parameter(Mandatory, Position = 2)]
	[string]$classCode,
	[Parameter(Mandatory, Position = 3)]
	[ValidateRange(1,200)]
	[int]$studentCount
)

Set-StrictMode -Version Latest

# Define a custom class to represent the output contents
class PublishInfo {
	[int]$Student
	[string]$UserName
	[string]$Password
	[string]$Url
}

# Create the array variable to hold the usernames, passwords, and URLs
$fileContents = @(
)

[Microsoft.Azure.Management.WebSites.Models.AppServicePlan]$plan = $null

for ($studentCounter = 1; $studentCounter -le $studentCount; $studentCounter++) {
	Write-Verbose "Processing student $studentCounter of $studentCount"
	[bool]$createPlan = ((($studentCounter - 1) % 30) -eq 0)

	#TODO: format numbers based on number of students, e.g., 01, 02, ... or 001, 002, etc.

	if ($createPlan) {
		# A better way might be to calculate how many ASPs are necessary, creating them, and then equally distributing students among them
		Write-Verbose "Creating new App Service Plan"
		$aspName = "$classCode-$studentCounter"

		# Create a new App Service Plan for every 30 students
		New-AzResourceGroupDeployment -ResourceGroupName $rgName `
			-Name "AppServicePlan-$aspName-Deployment" `
			-aspName $aspName `
			-TemplateFile .\AppServicePlan-template.json

		# Capture info about the plan to use when creating Apps
		$plan = Get-AzAppServicePlan -ResourceGroupName $rgName -Name $aspName
		
		Write-Host "Created App Service Plan $aspName"
	}

	$appName = $aspName

	# Create a new App Service for each student
	New-AzResourceGroupDeployment -ResourceGroupName $rgName `
		-Name "AppService-$appName-Deployment" `
		-appName $appName `
		-appServicePlanId $plan.Id `
		-location $plan.Location `
		-TemplateFile .\AppService-template.json

	# Get the publish profile, in XML
	[xml]$pubProfile = Get-AzWebAppPublishingProfile -ResourceGroupName $rgName `
		-Name $appName -Format Ftp -OutputFile $null

	# Extract the relevant values from the XML object
	$userName = $pubProfile.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userName").value
	$password = $pubProfile.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userPWD").value
	$ftpUrl = $pubProfile.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@publishUrl").value

	# Add line to the output file
	$fileContents += [PublishInfo]@{
		Student = $studentCounter
		UserName = $userName
		Password = $password
		Url = $ftpUrl
	}
}

# Write the output file
$fileName = "$classCode.csv"
$fileContents | Export-Csv $fileName -NoTypeInformation
