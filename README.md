# Bicep Versioning Framework
*The Versioning Framework for the Bicep modules*

![Heading](.img/heading.jpg)  

## Disclaimer  
 
- The content of this repository is used for educational purposes ONLY, and it does not contain any confidential or pirated information.  
- The programmatic content in this repository might not work in your environment immediately due to some dependencies.  
- The idea and content in the repository are produced by the community.  

## User motivation
> I as a DevOps engineer want to:
- Install the Bicep Versioning Framework inside my repository easily by running a script.
- Be able to version Bicep modules by using the commit message header & filing a few pipeline parameters.
- Add new modules easily and quickly.
- Customize the bicepconfig.json to utilize shorter paths toward my modules in the Azure Container Registry.

## Bicep in the Nutshell
- Wrapper around ARM
- Supports Templates & Modules
- These bring improved scalability, governance, security shift, reusability & more 

## What do we aim for?
- **Immutability**
- **Automated Versioning**
- **User-friendly framework**
- **Consistency & Governance**
- **The Commitlint for conventional commit messages**

## Step 1: Installation
- The idea is to install the Bicep versioning framework inside the repository where you want to host your IaC, preferably the repository should be empty.  
- The installation script will copy the framework structure to your repository, including the Azure pipeline, PowerShell scripts & sample Bicep template & module structure.  

1. **Install the Bicep Versioning Framework within the repository**
```powershell
& ./Install-BicepVersioningFramework.ps1 -GitPath yourRepositoryPath
```
2. **Install the [commitlint](https://github.com/conventional-changelog/commitlint)  for your platform, the example for macOS**  
```bash
# Navigate to your repository and execute from bash / zsh on macOS
npm install --save-dev @commitlint/{config-conventional,cli}
echo "module.exports = {extends: ['@commitlint/config-conventional']}" > commitlint.config.js
npm install husky --save-dev
npx husky install
npx husky add .husky/commit-msg  'npx --no -- commitlint --edit ${1}'
```  

## Step 2: Configure the framework for your needs
- Fill in the four parameters for the pipeline to work, you can change **azure-pipelines.yaml** to achieve this, and you can further extend the framework with the use of variable groups to pass the below parameter conditionally per environment.  
    - **connectedServiceName** - Name of the Azure DevOps Service Connection
    - **subscriptionId** - Subscription ID where your Azure Container Registry resides
    - **acrName** - Unique name of your ACR without ACR suffix, the example: **neopsyon**
    - **acrResourceGroupName** - Resource Group name where your Azure Container Registry resides
- The **watched** directory for bicep modules defaults to **templates/bicep/modules**
- Change this directory by configuring the **trigger** & the pipeline variable: **fileFilterPath** 
- Add a desirable directory structure under the **watched** directory, there is a sample of **Microsoft.Web** as a starter, and two bicep modules within.  
- Add & edit bicep modules while following the **Commitlint** syntax, see more down.  
- Edit **bicepconfig.json** to reflect the proper target of your repository, to leverage modules from ACR.
- Once you have performed the above steps, it's time to push changes to your repository & authorize the pipeline.  

## How does it work?
- After installation of the framework, the user has the pre-set framework inside the repository.  
- The framework is configured to watch the files inside the **templates/bicep/modules** by default.  
- The user is supposed to make a change to one of the files and use the conventional commit message to tell the framework how the version should be incremented
```bash
git add templates/bicep/modules/Microsoft.Web/appService.bicep  
git commit -m 'fix: lets increment the patch version'  
```
- Once the file in the **watched** directory is changed, the pipeline will kick off.  
- **The pipeline will perform the following steps**
    - Fetch the latest commit from the repository along with its metadata
    - Check if the commit message starts with **feat!:**, **feat:** or **fix:**
    - If so, it will map the start of the commit message to the version increment  

        - > **feat!:** corresponds to **MAJOR**
        - > **feat:** corresponds to **MINOR**
        - > **fix:** corresponds to **PATCH**

    - It will fetch the latest version for all changed modules within the **commit** / **watched** directory.
    - It will use the **decided version increment** to update all files that changed.
        - In case that module is being published for the first time, it will receive version **1.0.0**


## How is Commitlint leveraged
After the installation, the **Commitlint** will force the user to use conventional commit messages.
Based on the commit message, the framework will know how to increment the version increment of the changed Bicep files.  

**Example commits** 
> Example 1: git commit -m 'ci: This is a CI commit message' # CI will happen, modules are not versioned  
> Example 2: git commit -m 'fix: This message will increment a patch version for all changed module files'  
> Example 3: git commit -m 'feat: This message will increment a minor version for all changed module files'  
> Example 4: git commit -m 'feat!: This message will increment a major version for all changed module files'  


![Flow](.img/flow.jpg)  