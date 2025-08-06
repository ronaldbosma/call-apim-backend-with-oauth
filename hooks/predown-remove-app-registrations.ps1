<#
  This PowerShell script is executed before the resources are removed. 
  It removes the app registrations created during the deployment process, because `azd` doesn't support deleting Entra ID resources yet. 
  See the related GitHub issue: https://github.com/Azure/azure-dev/issues/4724.
  We're using a predown hook because the environment variables are (sometimes) empty in a postdown hook.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    
    [Parameter(Mandatory = $false)]
    [string]$BackendAppRegistrationName = $env:ENTRA_ID_BACKEND_APP_REGISTRATION_NAME,
    
    [Parameter(Mandatory = $false)]
    [string]$ClientAppRegistrationName = $env:ENTRA_ID_CLIENT_APP_REGISTRATION_NAME
)

# Validate required parameters
if ([string]::IsNullOrEmpty($SubscriptionId)) {
    throw "SubscriptionId parameter is required. Please provide it as a parameter or set the AZURE_SUBSCRIPTION_ID environment variable."
}


# First, ensure the Azure CLI is logged in and set to the correct subscription
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    throw "Unable to set the Azure subscription. Please make sure that you're logged into the Azure CLI with the same credentials as the Azure Developer CLI."
}


function Remove-ApplicationAndServicePrincipal($uniqueName){
    if ([string]::IsNullOrWhiteSpace($uniqueName)) {
        Write-Host "No unique name provided. Skipping deletion of application and service principal."
        return
    }

    # Get the application with the unique name
    $app = az ad app list | ConvertFrom-Json | Where-Object { $_.uniqueName -eq $uniqueName }

    if ($app) {
        # Get the service principal of the application
        $sp = az ad sp list --all | ConvertFrom-Json | Where-Object { $_.appId -eq $app.appId }
        
        if ($sp) {
            Write-Host "Deleting service principal $($sp.id) of application with unique name $uniqueName"
            # Delete the service principal (moves the service principal to the deleted items)
            az ad sp delete --id $sp.id
            # Permanently delete the service principal. If we don't do this, we can't create a new service principal with the same name.
            az rest --method DELETE --url "https://graph.microsoft.com/beta/directory/deleteditems/$($sp.id)"
        }
        else {
            Write-Host "Unable to delete service princpal for application with unique name $uniqueName. Service principal not found."
        }

        Write-Host "Deleting application $($app.id) with unique name $uniqueName"
        # Delete the application (moves the application to the deleted items)
        az ad app delete --id $app.id
        # Permanently delete the application. If we don't do this, we can't create a new application with the same name.
        az rest --method DELETE --url "https://graph.microsoft.com/beta/directory/deleteditems/$($app.id)"

    } else {
        Write-Host "Unable to delete application with unique name $uniqueName. Application not found."
    }
}


Remove-ApplicationAndServicePrincipal $BackendAppRegistrationName
Remove-ApplicationAndServicePrincipal $ClientAppRegistrationName