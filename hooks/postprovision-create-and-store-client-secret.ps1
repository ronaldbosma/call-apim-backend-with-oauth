# This script generates a client secret for the client app registration in Entra ID and stores it securely in Azure Key Vault.
# If the client app registration already has a client secret with the same display name, it will not create a new one.

# First, ensure the Azure CLI is logged in and set to the correct subscription
az account set --subscription $env:AZURE_SUBSCRIPTION_ID
if ($LASTEXITCODE -ne 0) {
    throw "Unable to set the Azure subscription. Please make sure that you're logged into the Azure CLI with the same credentials as the Azure Developer CLI."
}


$clientAppId = $env:ENTRA_ID_CLIENT_APP_REGISTRATION_CLIENT_ID
$keyVaultName = $env:AZURE_KEY_VAULT_NAME
$secretName = $env:ENTRA_ID_CLIENT_APP_REGISTRATION_CLIENT_SECRET_NAME
$secretDisplayName = "Client Secret"
$secretExpirationMonths = 3


# Check if the app registration already has a client secret and stop if it does
$credentials = az ad app credential list --id $clientAppId | ConvertFrom-Json
$existingSecret = $credentials | Where-Object { $_.displayName -eq $secretDisplayName }
if ($existingSecret.Count -gt 0) {
    Write-Host "App registration '$clientAppId' already has a client secret with display name '$secretDisplayName'. Skipping creation."
    exit 0
}


# Create client secret for the app registration
$endDate = (Get-Date).AddMonths($secretExpirationMonths).ToString("yyyy-MM-ddTHH:mm:ssZ")
$secretResult = az ad app credential reset --id $clientAppId --display-name $secretDisplayName --end-date $endDate --query "password" --output tsv
if ($LASTEXITCODE -ne 0) {
    throw "Failed to create client secret for app registration: $clientAppId"
}

Write-Host "Client secret created successfully for app registration: $clientAppId (valid for $secretExpirationMonths months)"


# Store the client secret in Key Vault
az keyvault secret set --vault-name $keyVaultName --name $secretName --value $secretResult --output none
if ($LASTEXITCODE -ne 0) {
    throw "Failed to store client secret in Key Vault: $keyVaultName"
}

Write-Host "Client secret stored successfully in Key Vault as: $secretName"

