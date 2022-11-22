[CmdletBinding()]
<#
.SYNOPSIS
Queries Azure DevOps to get the latest commit message, checks if the commit message contains a version increment syntax, if yes, it will query all files within the filter path that changed in the last commit, and returns the file path along with proceed parameter for the next pipeline step.
If the commit message does not contain a version increment matching fix: , feat: , or feat! , the function will not pass proceed parameter to the next pipeline step and pipeline will stop.

.DESCRIPTION
Queries Azure DevOps to get the latest commit message, and based on the mssage decides if it will check for changes files in last commit and proceed, or stop the piepline.

.PARAMETER DevOpsOrganization
The name of the Azure DevOps organization where the Bicep Framework repository is located.

.PARAMETER AuthToken
The Azure DevOps personal access token used for API calls, to get the latest commit message & changes.

.PARAMETER Project
The name of the Azure DevOps project where the Bicep Framework repository is located.

.PARAMETER RepositoryId
The name of the Azure DevOps repository where the Bicep Framework repository is located.

.PARAMETER FileFilterPath
The path to the file(s) to filter within the API call, while retrieving the latest commit message & changes.
Only the files within the local repository that match the filter will be processed.

.EXAMPLE
Get-RepositoryFileChange -DevOpsOrganization "myorg" -AuthToken xxxxxxxxxxx -Project "myproject" -RepositoryId "myrepo" -FileFilterPath "templates/bicep/modules"

.NOTES
Author: Neopsyon
#>
param (
    [Parameter(Mandatory)]
    [Alias('Organization')]
    [string]$DevOpsOrganization,

    [Parameter(Mandatory)]
    [Alias('Token', 'Pat')]
    [string]$AuthToken,

    [Parameter(Mandatory)]
    [string]$Project,
    
    [Parameter(Mandatory)]
    [string]$RepositoryId,
    
    [string]$FileFilterPath
)
begin {
    $encryptedPat = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($AuthToken)"))
    $token = @{Authorization = 'Basic ' + $encryptedPat }
    $latestCommitUri = 'https://dev.azure.com/{0}/{1}/_apis/git/repositories/{2}/commits?searchCriteria.$top=1&api-version=6.0' -f $DevOpsOrganization, $Project, $RepositoryId
}
process {
    $getLatestCommit = Invoke-RestMethod -Uri $latestCommitUri -Headers $token
    if (($getLatestCommit.value.changeCounts.Add -gt 0) -or ($getLatestCommit.value.changeCounts.Edit -gt 0)) {
        $latestCommitMessage = $getLatestCommit.value.comment
        switch -Regex ($latestCommitMessage) {
            'fix:*' {
                $versionIncrement = 'PATCH'
            }
            'feat:*' {
                $versionIncrement = 'MINOR'
            }
            'feat!*' {
                $versionIncrement = 'MAJOR'
            }
            Default {
                $versionIncrement = $null
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($versionIncrement)) {
            $commitChangesUri = 'https://dev.azure.com/{0}/{1}/_apis/git/repositories/{2}/commits/{3}/changes?api-version=6.0' -f $DevOpsOrganization, $Project, $RepositoryId, $getLatestCommit.value.commitId
            $getLatestCommitChanges = Invoke-RestMethod -Uri $commitChangesUri -Headers $token
            if ($getLatestCommitChanges.changeCounts.Edit -gt 0) {
                $changeCollection = [System.Collections.ArrayList]::new()
                foreach ($change in $getLatestCommitChanges.changes) {
                    if ($change.item.PSobject.Properties.name -notcontains 'isFolder') {
                        if ($FileFilterPath) {
                            if ($change.item.path -like "$FileFilterPath*") {
                                [void]($changeCollection.Add($change.item.path))
                            }
                        }
                        else {
                            if ([bool]($change.item.PSobject.Properties.name -notcontains 'isFolder')) {
                                [void]($changeCollection.Add($change.item.path))
                            }
                        }
                    }
                }
                if (-not [string]::IsNullOrWhiteSpace($changeCollection)) {
                    Write-Host "##vso[task.setvariable variable=repositoryFileChange;]$changeCollection"
                    Write-Host "##vso[task.setvariable variable=versionIncrement;]$versionIncrement"
                    Write-Host "##vso[task.setvariable variable=proceed;]true"
                    return($changeCollection | Sort-Object)
                }
                else {
                    Write-Host "##vso[task.setvariable variable=proceed;]false"
                }
            }
        }
    }
    else {
        Write-Host "##vso[task.setvariable variable=proceed;]false"
    }
}