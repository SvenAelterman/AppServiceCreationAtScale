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

class PublishInfo {
	[int]$Student
	[string]$UserName
	[string]$Password
	[string]$Url
}

$fileContents = @(
)

[Microsoft.Azure.Management.WebSites.Models.AppServicePlan]$plan = $null

for ($studentCounter = 1; $studentCounter -le $studentCount; $studentCounter++) {
	Write-Verbose "Processing student $studentCounter of $studentCount"
	[bool]$createPlan = ((($studentCounter - 1) % 30) -eq 0)

	#TODO: format numbers

	if ($createPlan) {
		# A better way might be to calculate how many ASPs are necessary, creating them, and then equally distributing students among them
		Write-Verbose "Creating new App Service Plan"
		$aspName = "$classCode-$studentCounter"

		# Create a new App Service Plan for every 30 students
		# New-AzResourceGroupDeployment -ResourceGroupName $rgName `
		# 	-Name "AppServicePlan-$aspName-Deployment" `
		# 	-aspName $aspName `
		# 	-TemplateFile .\AppServicePlan-template.json

		# Capture info about the plan to use when creating Apps
		$plan = Get-AzAppServicePlan -ResourceGroupName $rgName -Name $aspName
		
		Write-Host "Created App Service Plan $aspName"
	}

	$appName = "$classCode-$studentCounter"

	# Create a new App Service for each student
	# New-AzResourceGroupDeployment -ResourceGroupName $rgName `
	# 	-Name "AppService-$appName-Deployment" `
	# 	-appName $appName `
	# 	-appServicePlanId $plan.Id `
	# 	-location $plan.Location `
	# 	-TemplateFile .\AppService-template.json

	# Get the publish profile, in XML, and extract the username and password
	[xml]$pubProfile = Get-AzWebAppPublishingProfile -ResourceGroupName $rgName `
		-Name $appName -Format Ftp -OutputFile $null

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
$fileName = "$classCode.csv"
$fileContents | Export-Csv $fileName -NoTypeInformation
