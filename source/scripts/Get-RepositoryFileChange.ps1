[CmdletBinding()]
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
    $ErrorActionPreference = 'Stop'
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