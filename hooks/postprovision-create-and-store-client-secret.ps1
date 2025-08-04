# This PowerShell script is executed after the infra resources are provisioned. 
# It creates a client secret for the client app registration in Entra ID and stores it securely in Azure Key Vault. 
# If the app registration already has a client secret, it will not create a new one.
# Currently, we can't create secrets for an app registration with Bicep.

# First, ensure the Azure CLI is logged in and set to the correct subscription
az account set --subscription $env:AZURE_SUBSCRIPTION_ID
if ($LASTEXITCODE -ne 0) {
    throw "Unable to set the Azure subscription. Please make sure that you're logged into the Azure CLI with the same credentials as the Azure Developer CLI."
}


$clientAppId = $env:ENTRA_ID_CLIENT_APP_REGISTRATION_CLIENT_ID
$keyVaultName = $env:AZURE_KEY_VAULT_NAME
$secretName = "client-secret"
$secretDisplayName = "Client Secret"


# Check if the secret already exists in Key Vault and stop if it does
Write-Host "Checking if secret '$secretName' exists in Key Vault '$keyVaultName'"
$existingSecret = az keyvault secret show `
    --vault-name $keyVaultName `
    --name $secretName `
    --query "value" `
    --output tsv 2>$null
    
if ($LASTEXITCODE -eq 0 -and ![string]::IsNullOrEmpty($existingSecret)) {
    Write-Host "Secret already exists. Skipping creation."
    exit 0
}


# Create client secret for the app registration
Write-Host "Creating client secret for app registration '$clientAppId'"
$secretResult = az ad app credential reset `
    --id $clientAppId `
    --display-name $secretDisplayName `
    --query "password" `
    --output tsv

if ($LASTEXITCODE -ne 0) {
    throw "Failed to create client secret for app registration: $clientAppId"
}

Write-Host "Client secret created successfully"


# Store the client secret in Key Vault
Write-Host "Storing client secret in Key Vault '$keyVaultName'"
az keyvault secret set `
    --vault-name $keyVaultName `
    --name $secretName `
    --value $secretResult `
    --output none

if ($LASTEXITCODE -ne 0) {
    throw "Failed to store client secret in Key Vault: $keyVaultName"
}

Write-Host "Client secret stored successfully"
