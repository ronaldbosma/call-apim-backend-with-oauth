//=============================================================================
// API Management App Registration with App roles & Service Principal
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

@description('The ID of the tenant')
param tenantId string

@description('The tags to associate with the resource')
param tags object

@description('The name of the API Management app registration in Entra ID')
param name string

@description('The identifier URI for the API Management app registration')
param identifierUri string

//=============================================================================
// Resources
//=============================================================================

resource apimAppRegistration 'Microsoft.Graph/applications@v1.0' = {
  tags: helpers.flattenTags(tags)
  
  uniqueName: name
  displayName: name

  identifierUris: [ identifierUri ]

  api: {
    requestedAccessTokenVersion: 2 // Issue OAuth v2.0 access tokens
  }

  appRoles: [
    {
      id: guid(tenantId, 'Sample.Read')
      description: 'Sample read application role'
      displayName: 'Sample.Read'
      value: 'Sample.Read'
      allowedMemberTypes: [ 'Application' ]
      isEnabled: true
    }
  ]

  owners: {
    relationships: [
      deployer().objectId
    ]
  }
}

resource apimServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: apimAppRegistration.appId
  appRoleAssignmentRequired: true // When true, clients must have an app role assigned in order to retrieve an access token
}

//=============================================================================
// Outputs
//=============================================================================

output appId string = apimAppRegistration.appId
