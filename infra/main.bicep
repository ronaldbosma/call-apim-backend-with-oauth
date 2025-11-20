//=============================================================================
// Call API Management backend with OAuth
// Source: https://github.com/ronaldbosma/call-apim-backend-with-oauth
//=============================================================================

targetScope = 'subscription'

//=============================================================================
// Imports
//=============================================================================

import { getResourceName, generateInstanceId } from './functions/naming-conventions.bicep'
import { apiManagementSettingsType, appInsightsSettingsType, backendSettingsType } from './types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@minLength(1)
@description('Location to use for all resources')
param location string

@minLength(1)
@maxLength(32)
@description('The name of the environment to deploy to')
param environmentName string

@description('The service management reference. Required for tenants with Entra IDs enabled by Service Tree management and must be a valid Service Tree ID in this case.')
param serviceManagementReference string = ''

//=============================================================================
// Variables
//=============================================================================

// Generate an instance ID to ensure unique resource names
var instanceId string = generateInstanceId(environmentName, location)

var resourceGroupName string = getResourceName('resourceGroup', environmentName, location, instanceId)

var apiManagementSettings apiManagementSettingsType = {
  serviceName: getResourceName('apiManagement', environmentName, location, instanceId)
  // Because the Consumption tier does not support internal cache, we use the Basic V2 tier
  sku: 'BasicV2'
}

var appInsightsSettings appInsightsSettingsType = {
  appInsightsName: getResourceName('applicationInsights', environmentName, location, instanceId)
  logAnalyticsWorkspaceName: getResourceName('logAnalyticsWorkspace', environmentName, location, instanceId)
  retentionInDays: 30
}

var backendAppRegistrationSettings backendSettingsType = {
  appRegistrationName: getResourceName('appRegistration', environmentName, location, 'backend-${instanceId}')
  appRegistrationIdentifierUri: 'api://${getResourceName('appRegistration', environmentName, location, 'backend-${instanceId}')}'
}

var clientAppRegistrationName string = getResourceName('appRegistration', environmentName, location, 'client-${instanceId}')

var keyVaultName string = getResourceName('keyVault', environmentName, location, instanceId)

// Generate a unique ID for the azd environment so we can identity the Entra ID resources created for this environment
// The environment name is not unique enough as multiple environments can have the same name in different subscriptions, regions, etc.
var azdEnvironmentId string = getResourceName('azdEnvironment', environmentName, location, instanceId)

var tags { *: string } = {
  'azd-env-name': environmentName
  'azd-env-id': azdEnvironmentId
  'azd-template': 'ronaldbosma/call-apim-backend-with-oauth'

  // The SecurityControl tag is added to Trainer Demo Deploy projects so resources can run in MTT managed subscriptions without being blocked by default security policies.
  // DO NOT USE this tag in production or customer subscriptions.
  SecurityControl: 'Ignore'
}

//=============================================================================
// Resources
//=============================================================================

module backendAppRegistration 'modules/entra-id/backend-app-registration.bicep' = {
  params: {
    tenantId: subscription().tenantId
    tags: tags
    name: backendAppRegistrationSettings.appRegistrationName
    identifierUri: backendAppRegistrationSettings.appRegistrationIdentifierUri
    serviceManagementReference: serviceManagementReference
  }
}

module clientAppRegistration 'modules/entra-id/client-app-registration.bicep' = {
  params: {
    tags: tags
    name: clientAppRegistrationName
    serviceManagementReference: serviceManagementReference
  }
  dependsOn: [
    backendAppRegistration
  ]
}

// module assignAppRolesToClient 'modules/entra-id/assign-app-roles.bicep' = {
//   params: {
//     backendAppRegistrationName: backendAppRegistrationSettings.appRegistrationName
//     clientAppRegistrationName: clientAppRegistrationName
//   }
//   dependsOn: [
//     backendAppRegistration
//     clientAppRegistration
//     // Assignment of the app roles fails if we do this immediately after creating the app registrations.
//     // By adding a dependency on the API Management module, we ensure that enough time has passed for the app role assignments to succeed.
//     apiManagement 
//   ]
// }

// resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-07-01' = {
//   name: resourceGroupName
//   location: location
//   tags: tags
// }

// module keyVault 'modules/services/key-vault.bicep' = {
//   scope: resourceGroup
//   params: {
//     location: location
//     tags: tags
//     keyVaultName: keyVaultName
//   }
// }

// module appInsights 'modules/services/app-insights.bicep' = {
//   scope: resourceGroup
//   params: {
//     location: location
//     tags: tags
//     appInsightsSettings: appInsightsSettings
//   }
// }

// module apiManagement 'modules/services/api-management.bicep' = {
//   scope: resourceGroup
//   params: {
//     location: location
//     tags: tags
//     apiManagementSettings: apiManagementSettings
//     appInsightsName: appInsightsSettings.appInsightsName
//     keyVaultName: keyVaultName
//   }
//   dependsOn: [
//     appInsights
//     keyVault
//   ]
// }

// module assignRolesToDeployer 'modules/shared/assign-roles-to-principal.bicep' = {
//   scope: resourceGroup
//   params: {
//     principalId: deployer().objectId
//     isAdmin: true
//     keyVaultName: keyVaultName
//   }
//   dependsOn: [
//     keyVault
//   ]
// }

//=============================================================================
// Outputs
//=============================================================================


// Return the azd environment id
output AZURE_ENV_ID string = azdEnvironmentId

// Return names of the Entra ID resources
output ENTRA_ID_BACKEND_APP_REGISTRATION_NAME string = backendAppRegistrationSettings.appRegistrationName
output ENTRA_ID_BACKEND_APP_REGISTRATION_APP_ID string = backendAppRegistration.outputs.appId
output ENTRA_ID_BACKEND_APP_REGISTRATION_IDENTIFIER_URI string = backendAppRegistrationSettings.appRegistrationIdentifierUri
output ENTRA_ID_CLIENT_APP_REGISTRATION_NAME string = clientAppRegistrationName
output ENTRA_ID_CLIENT_APP_REGISTRATION_CLIENT_ID string = clientAppRegistration.outputs.appId

// Return the names of the resources
output AZURE_API_MANAGEMENT_NAME string = apiManagementSettings.serviceName
output AZURE_APPLICATION_INSIGHTS_NAME string = appInsightsSettings.appInsightsName
output AZURE_KEY_VAULT_NAME string = keyVaultName
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = appInsightsSettings.logAnalyticsWorkspaceName
output AZURE_RESOURCE_GROUP string = resourceGroupName

// Return resource endpoints
// output AZURE_API_MANAGEMENT_GATEWAY_URL string = apiManagement.outputs.gatewayUrl
// output AZURE_KEY_VAULT_URI string = keyVault.outputs.vaultUri

// Return the service management reference
output AZURE_SERVICE_MANAGEMENT_REFERENCE string? = serviceManagementReference
