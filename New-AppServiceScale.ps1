#Requires -Modules "Az"
#Requires -PSEdition Core

[CmdletBinding()]
param (
	[Parameter(Mandatory, Position = 1)]
	[string]$rgName,
	[Parameter(Mandatory, Position = 2)]
	[string]$classCode,
	[Parameter(Mandatory, Position = 3)]
	[ValidateRange(1, 200)]
	[int]$studentCount
)

Set-StrictMode -Version Latest

# Define a custom class to represent the output contents
class PublishInfo {
	[int]$Student
	[string]$UserName
	[string]$Password
	[string]$FtpUrl
	[string]$HttpUrl
}

# Define the format for the counter
[int]$NumDigits = $studentCount.ToString().Length

# Create the array variable to hold the usernames, passwords, and URLs
$fileContents = @(
)

[Microsoft.Azure.Management.WebSites.Models.AppServicePlan]$plan = $null

for ($studentCounter = 1; $studentCounter -le $studentCount; $studentCounter++) {
	Write-Verbose "Processing student $studentCounter of $studentCount"
	[bool]$createPlan = ((($studentCounter - 1) % 30) -eq 0)

	$CommonNamePart = "$classCode-{0:d$NumDigits}" -f $studentCounter

	if ($createPlan) {
		# A better way might be to calculate how many ASPs are necessary, creating them, and then equally distributing students among them
		Write-Verbose "Creating new App Service Plan"
		$aspName = "plan-$CommonNamePart"

		# Create a new App Service Plan for every 30 students
		New-AzResourceGroupDeployment -ResourceGroupName $rgName `
			-Name "$aspName-Deployment" `
			-aspName $aspName `
			-TemplateFile .\AppServicePlan-template.bicep | Out-Null

		# Capture info about the plan to use when creating Apps
		$plan = Get-AzAppServicePlan -ResourceGroupName $rgName -Name $aspName
		
		Write-Host "Created App Service Plan $aspName"
	}

	$appName = "app-$CommonNamePart"

	# Create a new App Service for each student
	New-AzResourceGroupDeployment -ResourceGroupName $rgName `
		-Name "$appName-Deployment" `
		-appName $appName `
		-appServicePlanId $plan.Id `
		-location $plan.Location `
		-TemplateFile .\AppService-template.bicep | Out-Null

	Write-Host "`tCreated App Service $appName"

	# Get the publish profile, in XML
	[xml]$pubProfile = Get-AzWebAppPublishingProfile -ResourceGroupName $rgName `
		-Name $appName -Format Ftp -OutputFile $null
	$appSvc = Get-AzWebApp -ResourceGroupName $rgName -Name $appName
	# TODO: Finish
	$appHostName = $appSvc.HostNames[0]

	# TODO: HTTPS should actually always work
	$appTlsEnabled = ($appSvc.HostNameSslStates | Where-Object { $_.Name -eq $appHostName }).SslState -eq "Enabled"

	$url = "http$($appTlsEnabled ? 's' : '')://$appHostName"

	# Extract the relevant values from the XML object
	$userName = $pubProfile.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userName").value
	$password = $pubProfile.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userPWD").value
	$ftpUrl = $pubProfile.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@publishUrl").value

	# Add line to the output file
	$fileContents += [PublishInfo]@{
		Student  = $studentCounter
		UserName = $userName
		Password = $password
		FtpUrl   = $ftpUrl
		HttpUrl  = $url
	}
}

# Write the output file
$fileName = "$classCode.csv"
$fileContents | Export-Csv $fileName -NoTypeInformation
