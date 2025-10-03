//=============================================================================
// Client App Registration with Service Principal
//=============================================================================

targetScope = 'subscription'

//=============================================================================
// Extensions
//=============================================================================

extension microsoftGraphV1

//=============================================================================
// Imports
//=============================================================================

import * as helpers from '../../functions/helpers.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The tags to associate with the resource')
param tags object

@description('The name of the client app registration')
param name string

//=============================================================================
// Resources
//=============================================================================

resource clientAppRegistration 'Microsoft.Graph/applications@v1.0' = {
  uniqueName: name
  displayName: name

  // Add a 'HideApp' tag to hide the app from the end-users in the My Apps portal
  tags: concat(helpers.flattenTags(tags), ['HideApp'])
}

resource clientServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: clientAppRegistration.appId

  // Enforces that users/clients must be assigned an app role to access the application.
  // This is not strictly required for this scenario, but it adds an extra layer of security.
  appRoleAssignmentRequired: true
}

//=============================================================================
// Resources
//=============================================================================

output appId string = clientAppRegistration.appId
