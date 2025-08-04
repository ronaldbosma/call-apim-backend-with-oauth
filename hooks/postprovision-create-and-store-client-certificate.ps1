# This PowerShell script is executed after the infra resources are provisioned. 
# It creates a self-signed client certificate for the client app registration in Entra ID and stores it securely in Azure Key Vault. 
# If the client certificate already exists in Key Vault, it will not create a new one.
# Currently, we can't create certificates for an app registration with Bicep.

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
Write-Host "Checking if certificate '$certificateName' exists in Key Vault '$keyVaultName'"
$existingCert = az keyvault certificate show `
    --vault-name $keyVaultName `
    --name $certificateName `
    --query "id" `
    --output tsv 2>$null

if ($existingCert) {
    Write-Host "Certificate already exists. Skipping creation."
    exit 0
}


# Create certificate in Key Vault and add to App Registration in one operation
Write-Host "Creating certificate '$certificateName' in Key Vault and adding to app registration '$clientAppId'"
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

Write-Host "Certificate created and added successfully"