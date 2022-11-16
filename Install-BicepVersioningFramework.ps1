[CmdletBinding()]
<#
.SYNOPSIS
Installs the Bicep Versioning components, Azure Pipeline, PowerShell scripts and Bicep modules.

.DESCRIPTION
Installs the Bicep Versioning components.

.PARAMETER GitPath
The path to the Git repository.

.EXAMPLE
Install-BicepVersioningFramework -GitPath "C:\Git\MyRepo"

.NOTES
Author: Neopsyon
#>
param (
    [Parameter(Mandatory)]
    [ValidateScript({Test-Path $_})]
    [System.IO.FileInfo]$GitPath
)
process {
    $ErrorActionPreference = 'Stop'
    Copy-Item -Path $PSScriptRoot\source\* -Destination $GitPath -Exclude  $PSScriptRoot\source\.git\ -Recurse -Force
}