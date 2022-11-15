[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [Alias('ContainerRegistry')]
    [string]$ACRName,

    [Parameter(Mandatory)]
    [string[]]$FilePath,

    [Parameter(Mandatory)]
    [ValidateSet('Major','Minor','Patch')]
    [string]$VersionIncrement,

    [string]$SubscriptionId,

    [string]$PublishPath = 'bicep/modules'
)
process {
    $ErrorActionPreference = 'Stop'
    if ($SubscriptionId) {
        [void](Set-AzContext -SubscriptionId $SubscriptionId)
    }
    $containerRegistry = Get-AzContainerRegistry $ACRName
    foreach ($file in $filePath.split(' ')) {
        $bicepFilePath = '{0}/{1}' -f (pwd).path, $file
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