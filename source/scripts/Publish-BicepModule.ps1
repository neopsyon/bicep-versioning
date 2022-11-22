[CmdletBinding()]
<#
.SYNOPSIS
Publishes a Bicep module to the Azure Container Registry by following Semantic Versioning, by

.DESCRIPTION
Publishes a Bicep module to the Azure Container Registry.

.PARAMETER ACRName
The name of the Azure Container Registry where the Bicep module will be published.

.PARAMETER ACRResourceGroup
The name of the Azure Resource Group where the Azure Container Registry is located.

.PARAMETER SubscriptionId
The Azure Subscription Id where the Azure Container Registry is located.

.PARAMETER FilePath
The ore or more paths to the Bicep module file(s).

.PARAMETER VersionIncrement
The version increment to apply to the Bicep module by following Semantic Versioning.
If the module does not exist in the Azure Container Registry, the version will be set to 1.0.0

.PARAMETER PublishPath
The base path where the Bicep module will be published within the Azure Container Registry repositories.

.EXAMPLE
Publish-BicepModule -ACRName "myacr" -ACRResourceGroup "myrg" -SubscriptionId "00000000-0000-0000-0000-000000000000" -FilePath "C:\Git\MyRepo\source\module.bicep" -VersionIncrement "patch"

.EXAMPLE
Publish-BicepModule -ACRName "myacr" -ACRResourceGroup "myrg" -SubscriptionId "00000000-0000-0000-0000-000000000000" -FilePath "C:\Git\MyRepo\source\module1.bicep","C:\Git\MyRepo\source\module2.bicep" -VersionIncrement "minor" -PublishPath "modules/bicep"

.NOTES
Author: Neopsyon
#>
param (
    [Parameter(Mandatory)]
    [Alias('ContainerRegistry')]
    [string]$ACRName,

    [Parameter(Mandatory)]
    [Alias('ResourceGroup')]
    [string]$ACRResourceGroupName,

    [string]$SubscriptionId,

    [Parameter(Mandatory)]
    [string[]]$FilePath,

    [Parameter(Mandatory)]
    [ValidateSet('Major','Minor','Patch')]
    [string]$VersionIncrement,

    [string]$PublishPath = 'bicep/modules'
)
process {
    $ErrorActionPreference = 'Stop'
    if ($SubscriptionId) {
        [void](Set-AzContext -SubscriptionId $SubscriptionId)
    }
    $containerRegistry = Get-AzContainerRegistry -Name $ACRName -ResourceGroupName $ACRResourceGroupName
    if ([string]::IsNullOrWhiteSpace($containerRegistry)) {
        throw 'Container registry not found.'
    }
    foreach ($file in $filePath.split(' ')) {
        $bicepFilePath = '{0}/{1}' -f (Get-Location).path, $file
        if ($false -eq (Test-Path $bicepFilePath)) {
            throw ('Cannot find bicep file {0}' -f $bicepFilePath)
        }
        $repositoryName = ('{0}/{1}' -f $PublishPath, $file.Split('/')[-1].Replace('.bicep', '')).ToLower()
        $fetchManifestUri = ($containerRegistry.LoginServer.Split('.')[0])
        $fetchManifest = Get-AzContainerRegistryManifest -RegistryName $fetchManifestUri -RepositoryName $repositoryName -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($fetchManifest)) {
            [version]$manifestNewVersion = '1.0.0'
        }
        else {
            [version]$manifestLatestVersion = ([array]$fetchManifest.ManifestsAttributes.Tags)[0].Trim('v')
            switch ($VersionIncrement) {
                'MAJOR' {
                    $manifestNewVersion = [version]::new($manifestLatestVersion.Major + 1, $manifestLatestVersion.Minor, $manifestLatestVersion.Build)
                }
                'MINOR' {
                    $manifestNewVersion = [version]::new($manifestLatestVersion.Major, $manifestLatestVersion.Minor + 1, $manifestLatestVersion.Build)
                    
                }
                'PATCH' {
                    $manifestNewVersion = [version]::new($manifestLatestVersion.Major, $manifestLatestVersion.Minor, $manifestLatestVersion.Build + 1)
                }
            }
        }
        $publishBicepSplat = @{
            FilePath = '.{0}' -f $file
            Target = ('br:{0}/{1}:v{2}' -f $containerRegistry.LoginServer, $repositoryName , $manifestNewVersion.ToString()).ToLower()
            WarningAction = 'SilentlyContinue'
        }
        Publish-AzBicepModule @publishBicepSplat
        Write-Host ('Published bicep information: {0}' -f $publishBicepSplat.Target)
    }
}