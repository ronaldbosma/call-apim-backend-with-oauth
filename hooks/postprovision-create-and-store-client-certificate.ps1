# This script generates a client certificate in Azure Key Vault and uploads it to the client app registration in Entra ID.
# It creates a new certificate in Key Vault, downloads it temporarily, and then adds it as a credential to the app registration.
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


# Step 1: Check if certificate exists and exit if it does
$existingCert = az keyvault certificate show `
    --vault-name $keyVaultName `
    --name $certificateName `
    --query "id" `
    --output tsv 2>$null

if ($existingCert) {
    Write-Host "Certificate '$certificateName' already exists in Key Vault '$keyVaultName'. Exiting."
    exit 0
}


# Step 2: Generate new certificate in Key Vault
Write-Host "Creating new certificate '$certificateName' in Key Vault '$keyVaultName'..."
$defaultPolicyPath = [System.IO.Path]::GetTempFileName()
az keyvault certificate get-default-policy | Out-File -Encoding utf8 $defaultPolicyPath

try {
    az keyvault certificate create `
        --vault-name $keyVaultName `
        --name $certificateName `
        --policy @$defaultPolicyPath `
        --output none

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create certificate '$certificateName' in Key Vault '$keyVaultName'."
    }
} finally {
    Remove-Item $defaultPolicyPath -Force
}

# Step 3: Wait for certificate to be fully created
$maxRetries = 30
$retryDelaySeconds = 1
$retryCount = 0
$certReady = $false

while ($retryCount -lt $maxRetries) {
    $certStatus = az keyvault certificate pending show --vault-name $keyVaultName --name $certificateName --query "status" --output tsv 2>$null
    if ($certStatus -eq "completed") {
        $certReady = $true
        break
    }

    Write-Host "Certificate status: '$certStatus'. Waiting for certificate to be ready..."
    Start-Sleep -Seconds $retryDelaySeconds
    $retryCount++
}

if (-not $certReady) {
    throw "Certificate '$certificateName' was not ready after $($maxRetries * $retryDelaySeconds) seconds."
}


# Step 4: Export certificate in .cer format
$cerPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("client-certificate-$([guid]::NewGuid()).cer")
Write-Host "Downloading certificate to '$cerPath'..."
az keyvault certificate download `
    --vault-name $keyVaultName `
    --name $certificateName `
    --file $cerPath `
    --encoding PEM

if ($LASTEXITCODE -ne 0) {
    throw "Failed to download certificate '$certificateName' from Key Vault '$keyVaultName'."
}

try { 
    # Step 5: Upload certificate to App Registration
    Write-Host "Uploading certificate to App Registration '$clientAppId'..."
    az ad app credential reset `
        --id $clientAppId `
        --cert @$cerPath `
        --append `
        --display-name $certificateDisplayName `
        --output none

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to add certificate to app registration '$clientAppId'."
    }

    Write-Host "Successfully added certificate '$certificateName' to app registration '$clientAppId'."
} finally {
    #Remove-Item $cerPath -Force
}