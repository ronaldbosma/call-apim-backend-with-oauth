<#
  This PowerShell script is executed after the infra resources are provisioned. 
  The APIs are defined in a separate module (src/apis/apis.bicep) from the infrastructure 
  because the client secret and certificate must exist in Key Vault before deployment of the APIs.
  This script deploys the APIs to Azure API Management after the hooks that generate 
  the client secret and certificate have completed.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    
    [Parameter(Mandatory = $false)]
    [string]$EnvironmentName = $env:AZURE_ENV_NAME,
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup = $env:AZURE_RESOURCE_GROUP,
    
    [Parameter(Mandatory = $false)]
    [string]$ApiManagementServiceName = $env:AZURE_API_MANAGEMENT_NAME,
    
    [Parameter(Mandatory = $false)]
    [string]$KeyVaultName = $env:AZURE_KEY_VAULT_NAME,
    
    [Parameter(Mandatory = $false)]
    [string]$OAuthAudience = $env:ENTRA_ID_BACKEND_APP_REGISTRATION_APP_ID,
    
    [Parameter(Mandatory = $false)]
    [string]$OAuthTargetResource = $env:ENTRA_ID_BACKEND_APP_REGISTRATION_IDENTIFIER_URI,
    
    [Parameter(Mandatory = $false)]
    [string]$ClientId = $env:ENTRA_ID_CLIENT_APP_REGISTRATION_CLIENT_ID
)

# Validate required parameters
if ([string]::IsNullOrEmpty($SubscriptionId)) {
    throw "SubscriptionId parameter is required. Please provide it as a parameter or set the AZURE_SUBSCRIPTION_ID environment variable."
}

if ([string]::IsNullOrEmpty($EnvironmentName)) {
    throw "EnvironmentName parameter is required. Please provide it as a parameter or set the AZURE_ENV_NAME environment variable."
}

if ([string]::IsNullOrEmpty($ResourceGroup)) {
    throw "ResourceGroup parameter is required. Please provide it as a parameter or set the AZURE_RESOURCE_GROUP environment variable."
}

if ([string]::IsNullOrEmpty($ApiManagementServiceName)) {
    throw "ApiManagementServiceName parameter is required. Please provide it as a parameter or set the AZURE_API_MANAGEMENT_NAME environment variable."
}

if ([string]::IsNullOrEmpty($KeyVaultName)) {
    throw "KeyVaultName parameter is required. Please provide it as a parameter or set the AZURE_KEY_VAULT_NAME environment variable."
}

if ([string]::IsNullOrEmpty($OAuthAudience)) {
    throw "OAuthAudience parameter is required. Please provide it as a parameter or set the ENTRA_ID_BACKEND_APP_REGISTRATION_APP_ID environment variable."
}

if ([string]::IsNullOrEmpty($OAuthTargetResource)) {
    throw "OAuthTargetResource parameter is required. Please provide it as a parameter or set the ENTRA_ID_BACKEND_APP_REGISTRATION_IDENTIFIER_URI environment variable."
}

if ([string]::IsNullOrEmpty($ClientId)) {
    throw "ClientId parameter is required. Please provide it as a parameter or set the ENTRA_ID_CLIENT_APP_REGISTRATION_CLIENT_ID environment variable."
}


$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition


# First, ensure the Azure CLI is logged in and set to the correct subscription
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    throw "Unable to set the Azure subscription. Please make sure that you're logged into the Azure CLI with the same credentials as the Azure Developer CLI."
}


# Deploy the APIs to API Management
Write-Host "Deploying APIs to API Management..."
az deployment group create `
  --name "$EnvironmentName-apis-$(Get-Date -UFormat %s)" `
  --resource-group $ResourceGroup `
  --template-file "$scriptDirectory/../src/apis/apis.bicep" `
  --parameters `
      apiManagementServiceName=$ApiManagementServiceName `
      keyVaultName=$KeyVaultName `
      oauthAudience=$OAuthAudience `
      oauthTargetResource=$OAuthTargetResource `
      clientId=$ClientId `
  --verbose

if ($LASTEXITCODE -ne 0) {
    throw "Failed to deploy APIs to API Management"
}

Write-Host "APIs deployed successfully to API Management" -ForegroundColor Green