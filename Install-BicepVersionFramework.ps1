[CmdletBinding()]
<#
.SYNOPSIS
Installs the Bicep Versioning components, including Commitlint, Husky, Azure Pipeline & other source components

.DESCRIPTION

.PARAMETER Path
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
param (
    [Parameter(Mandatory)]
    [ValidateScript({Test-Path $_})]
    [System.IO.FileInfo]$GitPath
)
process {
    $ErrorActionPreference = 'Stop'
    Copy-Item -Path $PSScriptRoot\source\* -Destination $GitPath -Recurse -Force
    bash -c "npm install --save-dev @commitlint/{config-conventional,cli}"
    Set-Location -Path $GitPath
    Write-Output "module.exports = {extends: ['@commitlint/config-conventional']}" > commitlint.config.js
    bash -c "npm install husky --save-dev"
    bash -c "npx husky install"
    bash -c "npx husky add .husky/commit-msg  'npx --no -- commitlint --edit ${1}'"
}