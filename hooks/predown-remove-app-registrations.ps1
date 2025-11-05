# The Azure Developer CLI doesn't support deleting Entra ID resources yet, so we have to do it in a hook.
# Related GitHub issue: https://github.com/Azure/azure-dev/issues/4724
#
# We're using a predown hook because the environment variables are (sometimes) empty in a postdown hook.
# The Entra ID resources have a custom tag "azd-env-id: <environment-id>", so we can find and delete them.

param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    
    [Parameter(Mandatory = $false)]
    [string]$AzureEnvironmentId = $env:AZURE_ENV_ID
)

# Validate required parameters
if ([string]::IsNullOrEmpty($SubscriptionId)) {
    throw "SubscriptionId parameter is required. Please provide it as a parameter or set the AZURE_SUBSCRIPTION_ID environment variable."
}

if ([string]::IsNullOrEmpty($AzureEnvironmentId)) {
    throw "AzureEnvironmentId parameter is required. Please provide it as a parameter or set the AZURE_ENV_ID environment variable."
}


# First, ensure the Azure CLI is logged in and set to the correct subscription
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    throw "Unable to set the Azure subscription. Please make sure that you're logged into the Azure CLI with the same credentials as the Azure Developer CLI."
}


# Find all app registrations with the matching azd-env-id tag
$targetTag = "azd-env-id: $AzureEnvironmentId"
Write-Host "Looking for app registrations with tag '$targetTag'"

$apps = az ad app list | ConvertFrom-Json | Where-Object { $_.tags -contains $targetTag }

if ($apps) {
    Write-Host "Found $($apps.Count) app registration(s) to delete"
    
    foreach ($app in $apps) {
        # Get the service principal of the application
        $sp = az ad sp list --all | ConvertFrom-Json | Where-Object { $_.appId -eq $app.appId }
        
        if ($sp) {
            Write-Host "Deleting service principal $($sp.id) of application with unique name $($app.uniqueName)"
            # Delete the service principal (moves the service principal to the deleted items)
            az ad sp delete --id $sp.id
            # Permanently delete the service principal. If we don't do this, we can't create a new service principal with the same name.
            az rest --method DELETE --url "https://graph.microsoft.com/beta/directory/deleteditems/$($sp.id)"
        }
        else {
            Write-Host "Unable to delete service principal for application with unique name $($app.uniqueName). Service principal not found."
        }

        Write-Host "Deleting application $($app.id) with unique name $($app.uniqueName)"
        # Delete the application (moves the application to the deleted items)
        az ad app delete --id $app.id
        # Permanently delete the application. If we don't do this, we can't create a new application with the same name.
        az rest --method DELETE --url "https://graph.microsoft.com/beta/directory/deleteditems/$($app.id)"
    }
} else {
    Write-Host "No app registrations found with tag: '$targetTag'"
}
