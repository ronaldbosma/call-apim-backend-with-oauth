# This PowerShell script is executed after the infra resources are provisioned. 
# It deploys the APIs (src/apis/apis.bicep) to Azure API Management.
# The APIs has been split of in a separate module from the infra because we need 
# the client secret and certificate to be stored in Key Vault before we can deploy the APIs.
# They are created in a postprovision script after the infra resources are created.

# First, ensure the Azure CLI is logged in and set to the correct subscription
az account set --subscription $env:AZURE_SUBSCRIPTION_ID
if ($LASTEXITCODE -ne 0) {
    throw "Unable to set the Azure subscription. Please make sure that you're logged into the Azure CLI with the same credentials as the Azure Developer CLI."
}

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Deploy the APIs to API Management
Write-Host "Deploying APIs to API Management..."
az deployment group create `
  --name "$($env:AZURE_ENV_NAME)-apis-$(Get-Date -UFormat %s)" `
  --resource-group $env:AZURE_RESOURCE_GROUP `
  --template-file "$scriptDirectory/../src/apis/apis.bicep" `
  --parameters `
      apiManagementServiceName=$env:AZURE_API_MANAGEMENT_NAME `
      keyVaultName=$env:AZURE_KEY_VAULT_NAME `
      oauthAudience=$env:ENTRA_ID_APIM_APP_REGISTRATION_APP_ID `
      oauthTargetResource=$env:ENTRA_ID_APIM_APP_REGISTRATION_IDENTIFIER_URI `
      clientId=$env:ENTRA_ID_CLIENT_APP_REGISTRATION_CLIENT_ID `
  --verbose

if ($LASTEXITCODE -ne 0) {
    throw "Failed to deploy APIs to API Management"
}

Write-Host "APIs deployed successfully to API Management" -ForegroundColor Green