#Requires -Modules "Az"
#Requires -PSEdition Core

[CmdletBinding()]
param (
	[Parameter(Mandatory, Position = 1)]
	[string]$ResourceGroupName,
	[Parameter(Mandatory, Position = 2)]
	[string]$ClassCode,
	[Parameter(Mandatory, Position = 3)]
	[ValidateRange(1, 200)]
	[int]$StudentCount,
	[string]$Location = 'eastus'
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

# Create the array variable to hold the usernames, passwords, and URLs
$fileContents = @(
)

$TemplateParameters = @{
	location          = $Location
	studentCount      = $StudentCount
	resourceGroupName = $ResourceGroupName
	classCode         = $ClassCode
}

$DeploymentResults = New-AzDeployment -Name "AppServiceScale-Deployment"  -Location $Location `
	-TemplateFile .\main.bicep -TemplateParameterObject $TemplateParameters

Write-Verbose $DeploymentResults

if ($DeploymentResults.ProvisioningState -eq "Succeeded") {
	Write-Host "🔥 Deployment successful. Outputting CSV... 🙂"

	$AppNames = $DeploymentResults.Outputs.appNames.Value
	Write-Verbose "Found $($AppNames.Count) App Service Plans"

	[int]$StudentCounter = 0

	# Loop through all app names (by app service plan) and retrieve publishing details
	for ($AppServicePlan = 0; $AppServicePlan -lt $AppNames.Count; $AppServicePlan++) {
		$AppServiceNames = $AppNames[$AppServicePlan].ToString() | ConvertFrom-Json
		Write-Verbose "`nSites in App Service Plan ${AppServicePlan}:`n$AppServiceNames`n"
		
		foreach ($AppServiceName in $AppServiceNames) {
			$StudentCounter++

			Write-Verbose "Retrieving publish profile and details for: $AppServiceName"

			# Get the App Service object
			$AppSvc = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName
			# Get the publish profile in XML
			[xml]$PubProfile = Get-AzWebAppPublishingProfile -ResourceGroupName $ResourceGroupName `
				-Name $AppServiceName -Format Ftp -OutputFile $null
			
			# Determine the URL of the site
			$AppHostName = $AppSvc.HostNames[0]
			# HTTPS should actually always work with the default hostname
			$AppTlsEnabled = ($AppSvc.HostNameSslStates | Where-Object { $_.Name -eq $AppHostName }).SslState -eq "Enabled"
			$Url = "http$($AppTlsEnabled ? 's' : '')://$AppHostName"

			# Extract the relevant values from the XML object
			$UserName = $PubProfile.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userName").value
			$Password = $PubProfile.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userPWD").value
			$FtpUrl = $PubProfile.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@publishUrl").value
				
			$fileContents += [PublishInfo]@{
				Student  = $StudentCounter
				UserName = $UserName
				Password = $Password
				FtpUrl   = $FtpUrl
				HttpUrl  = $Url
			}
		}
	}

	# Write the output file
	$FileName = "$ClassCode.csv"
	$fileContents | Export-Csv $fileName -NoTypeInformation

	Write-Host "CSV file $FileName written."
}
else {
	Write-Host $DeploymentResults
	Write-Error "❌ Deployment failed. See the output above for details. 👎"
}
