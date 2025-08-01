//=============================================================================
// Protect API Management with OAuth
// Source: https://github.com/ronaldbosma/protect-apim-with-oauth
//=============================================================================

targetScope = 'subscription'

//=============================================================================
// Imports
//=============================================================================

import { getResourceName, getInstanceId } from './functions/naming-conventions.bicep'
import * as settings from './types/settings.bicep'

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

@maxLength(5) // The maximum length of the storage account name and key vault name is 24 characters. To prevent errors the instance name should be short.
@description('The instance that will be added to the deployed resources names to make them unique. Will be generated if not provided.')
param instance string = ''

//=============================================================================
// Variables
//=============================================================================

// Determine the instance id based on the provided instance or by generating a new one
var instanceId = getInstanceId(environmentName, location, instance)

var resourceGroupName = getResourceName('resourceGroup', environmentName, location, instanceId)

var apiManagementSettings = {
  serviceName: getResourceName('apiManagement', environmentName, location, instanceId)
  publisherName: 'admin@example.org'
  publisherEmail: 'admin@example.org'
  appRegistrationName: getResourceName('appRegistration', environmentName, location, 'apim-${instanceId}')
  appRegistrationIdentifierUri: 'api://${getResourceName('apiManagement', environmentName, location, instanceId)}'
}

var appInsightsSettings = {
  appInsightsName: getResourceName('applicationInsights', environmentName, location, instanceId)
  logAnalyticsWorkspaceName: getResourceName('logAnalyticsWorkspace', environmentName, location, instanceId)
  retentionInDays: 30
}

var validClientAppRegistrationName = getResourceName('appRegistration', environmentName, location, 'validclient-${instanceId}')
var invalidClientAppRegistrationName = getResourceName('appRegistration', environmentName, location, 'invalidclient-${instanceId}')

var tags = {
  'azd-env-name': environmentName
  'azd-template': 'ronaldbosma/protect-apim-with-oauth'
}

//=============================================================================
// Resources
//=============================================================================

module apimAppRegistration 'modules/entra-id/apim-app-registration.bicep' = {
  name: 'apimAppRegistration'
  params: {
    tenantId: subscription().tenantId
    tags: tags
    name: apiManagementSettings.appRegistrationName
    identifierUri: apiManagementSettings.appRegistrationIdentifierUri
  }
}

// This client is 'valid' because it will have app roles assigned to it.
module validClientAppRegistration 'modules/entra-id/client-app-registration.bicep' = {
  name: 'validClientAppRegistration'
  params: {
    tags: tags
    name: validClientAppRegistrationName
  }
  dependsOn: [
    apimAppRegistration
  ]
}

module assignAppRolesToValidClient 'modules/entra-id/assign-app-roles.bicep' = {
  name: 'assignAppRolesToValidClient'
  params: {
    apimAppRegistrationName: apiManagementSettings.appRegistrationName
    clientAppRegistrationName: validClientAppRegistrationName
  }
  dependsOn: [
    apimAppRegistration
    validClientAppRegistration
    // Assignment of the app roles fails if we do this immediately after creating the app registrations.
    // By adding a dependency on the API Management module, we ensure that enough time has passed for the app role assignments to succeed.
    apiManagement 
  ]
}

// This client is 'invalid' because it will not have app roles assigned to it.
module invalidClientAppRegistration 'modules/entra-id/client-app-registration.bicep' = {
  name: 'invalidClientAppRegistration'
  params: {
    tags: tags
    name: invalidClientAppRegistrationName
  }
  dependsOn: [
    apimAppRegistration
  ]
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module appInsights 'modules/services/app-insights.bicep' = {
  name: 'appInsights'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    appInsightsSettings: appInsightsSettings
  }
}

module apiManagement 'modules/services/api-management.bicep' = {
  name: 'apiManagement'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    apiManagementSettings: apiManagementSettings
    appInsightsName: appInsightsSettings.appInsightsName
  }
  dependsOn: [
    appInsights
  ]
}

//=============================================================================
// Application Resources
//=============================================================================

module protectedApi 'modules/application/protected-api.bicep' = {
  name: 'protectedApi'
  scope: resourceGroup
  params: {
    apiManagementServiceName: apiManagementSettings.serviceName
    tenantId: subscription().tenantId
    oauthAudience: apimAppRegistration.outputs.appId
  }
  dependsOn: [
    apiManagement
  ]
}

//=============================================================================
// Outputs
//=============================================================================

// Return names of the Entra ID resources
output ENTRA_ID_APIM_APP_REGISTRATION_NAME string = apiManagementSettings.appRegistrationName
output ENTRA_ID_APIM_APP_REGISTRATION_IDENTIFIER_URI string = apiManagementSettings.appRegistrationIdentifierUri
output ENTRA_ID_VALID_CLIENT_APP_REGISTRATION_NAME string = validClientAppRegistrationName
output ENTRA_ID_VALID_CLIENT_APP_REGISTRATION_CLIENT_ID string = validClientAppRegistration.outputs.appId
output ENTRA_ID_INVALID_CLIENT_APP_REGISTRATION_NAME string = invalidClientAppRegistrationName
output ENTRA_ID_INVALID_CLIENT_APP_REGISTRATION_CLIENT_ID string = invalidClientAppRegistration.outputs.appId

// Return the names of the resources
output AZURE_API_MANAGEMENT_NAME string = apiManagementSettings.serviceName
output AZURE_APPLICATION_INSIGHTS_NAME string = appInsightsSettings.appInsightsName
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = appInsightsSettings.logAnalyticsWorkspaceName
output AZURE_RESOURCE_GROUP string = resourceGroupName
