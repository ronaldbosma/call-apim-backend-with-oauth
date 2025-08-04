# This script generates a client certificate in Azure Key Vault and uploads it to the client app registration in Entra ID.
# It uses the Azure CLI's integrated certificate creation functionality to create the certificate directly in Key Vault
# and add it as a credential to the app registration in a single operation.
# If the certificate already exists in Key Vault, the script will exit without creating a new one.

# First, ensure the Azure CLI is logged in and set to the correct subscription
az account set --subscription $env:AZURE_SUBSCRIPTION_ID
if ($LASTEXITCODE -ne 0) {
    throw "Unable to set the Azure subscription. Please make sure that you're logged into the Azure CLI with the same credentials as the Azure Developer CLI."
}


$clientAppId = $env:ENTRA_ID_CLIENT_APP_REGISTRATION_CLIENT_ID
$keyVaultName = $env:AZURE_KEY_VAULT_NAME
$certificateName = "client-certificate"
$certificateDisplayName = "Client Certificate"


# Check if certificate exists and exit if it does
$existingCert = az keyvault certificate show `
    --vault-name $keyVaultName `
    --name $certificateName `
    --query "id" `
    --output tsv 2>$null

if ($existingCert) {
    Write-Host "Certificate '$certificateName' already exists in Key Vault '$keyVaultName'. Skipping creation."
    exit 0
}


# Create certificate in Key Vault and add to App Registration in one operation
Write-Host "Creating certificate '$certificateName' in Key Vault '$keyVaultName' and adding to App Registration '$clientAppId'..."
az ad app credential reset `
    --id $clientAppId `
    --create-cert `
    --keyvault $keyVaultName `
    --cert $certificateName `
    --display-name $certificateDisplayName `
    --append `
    --output none

if ($LASTEXITCODE -ne 0) {
    throw "Failed to create certificate '$certificateName' in Key Vault '$keyVaultName' and add to app registration '$clientAppId'."
}

Write-Host "Successfully created certificate '$certificateName' in Key Vault and added to app registration '$clientAppId'."