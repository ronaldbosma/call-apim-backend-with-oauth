<#
  This PowerShell script is executed after the infra resources are provisioned. 
  Currently, we can't create certificates for an app registration with Bicep.
  This script creates a self-signed client certificate for the client app registration in Entra ID and stores it securely in Azure Key Vault. 
  If the client certificate already exists in Key Vault, it won't create a new one.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    
    [Parameter(Mandatory = $false)]
    [string]$ClientAppId = $env:ENTRA_ID_CLIENT_APP_REGISTRATION_CLIENT_ID,
    
    [Parameter(Mandatory = $false)]
    [string]$KeyVaultName = $env:AZURE_KEY_VAULT_NAME,
    
    [Parameter(Mandatory = $false)]
    [string]$CertificateName = "client-certificate",
    
    [Parameter(Mandatory = $false)]
    [string]$CertificateDisplayName = "Client Certificate"
)

# Validate required parameters
if ([string]::IsNullOrEmpty($SubscriptionId)) {
    throw "SubscriptionId parameter is required. Please provide it as a parameter or set the AZURE_SUBSCRIPTION_ID environment variable."
}

if ([string]::IsNullOrEmpty($ClientAppId)) {
    throw "ClientAppId parameter is required. Please provide it as a parameter or set the ENTRA_ID_CLIENT_APP_REGISTRATION_CLIENT_ID environment variable."
}

if ([string]::IsNullOrEmpty($KeyVaultName)) {
    throw "KeyVaultName parameter is required. Please provide it as a parameter or set the AZURE_KEY_VAULT_NAME environment variable."
}


# First, ensure the Azure CLI is logged in and set to the correct subscription
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    throw "Unable to set the Azure subscription. Please make sure that you're logged into the Azure CLI with the same credentials as the Azure Developer CLI."
}


# Check if certificate exists and exit if it does
Write-Host "Checking if certificate '$CertificateName' exists in Key Vault '$KeyVaultName'"
$existingCert = az keyvault certificate show `
    --vault-name $KeyVaultName `
    --name $CertificateName `
    --query "id" `
    --output tsv 2>$null

if ($existingCert) {
    Write-Host "Certificate already exists. Skipping creation."
    exit 0
}


# Create certificate in Key Vault and add to App Registration
Write-Host "Creating certificate '$CertificateName' in Key Vault and adding to app registration '$ClientAppId'"
az ad app credential reset `
    --id $ClientAppId `
    --create-cert `
    --keyvault $KeyVaultName `
    --cert $CertificateName `
    --display-name $CertificateDisplayName `
    --append `
    --output none

if ($LASTEXITCODE -ne 0) {
    throw "Failed to create certificate '$CertificateName' in Key Vault '$KeyVaultName' and add to app registration '$ClientAppId'."
}

Write-Host "Certificate created and added successfully"


# Verify certificate exists in app registration
# We retry a few times as there can be a delay before the certificate is visible in the app registration
# If we don't do this, another hook might overwrite the credentials before they are actually registered
Write-Host "Verifying certificate is registered in Entra ID..."
$maxAttempts = 6
$delay = 1

for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
    $credentials = az ad app credential list --id $ClientAppId --cert 2>$null | ConvertFrom-Json
    
    if ($LASTEXITCODE -eq 0 -and $credentials) {
        $matchingCert = $credentials | Where-Object { $_.displayName -eq $CertificateDisplayName }
        if ($matchingCert) {
            Write-Host "Certificate verified in app registration"
            exit 0
        }
    }
    
    if ($attempt -lt $maxAttempts) {
        Write-Host "Certificate not found yet, waiting $delay seconds... (attempt $attempt/$maxAttempts)"
        Start-Sleep -Seconds $delay
        $delay = $delay * 2
    }
}

Write-Warning "Certificate was created but could not be verified in app registration after $maxAttempts attempts"