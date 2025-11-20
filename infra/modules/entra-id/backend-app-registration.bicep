//=============================================================================
// Backend App Registration with App roles & Service Principal
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

@description('The service management reference. Required for tenants with Entra IDs enabled by Service Tree management and must be a valid Service Tree ID in this case.')
param serviceManagementReference string

//=============================================================================
// Variables
//=============================================================================

type appRoleType = {
  name: string
  description: string
}

var appRoles appRoleType[] = [
  {
    name: 'Sample.Read'
    description: 'Sample read application role'
  }
  {
    name: 'Sample.Write'
    description: 'Sample write application role'
  }
  {
    name: 'Sample.Delete'
    description: 'Sample delete application role'
  }
]

//=============================================================================
// Resources
//=============================================================================

resource backendAppRegistration 'Microsoft.Graph/applications@v1.0' = {
  uniqueName: name
  displayName: name

  identifierUris: [ identifierUri ]

  api: {
    requestedAccessTokenVersion: 2 // Issue OAuth v2.0 access tokens
  }

  appRoles: [for role in appRoles: {
    id: guid(tenantId, name, role.name) // Create an deterministic ID for the app role based on the tenant ID, app name and role name
    description: role.description
    displayName: role.name
    value: role.name
    allowedMemberTypes: [ 'Application' ]
    isEnabled: true
  }]
  
  // Add a 'HideApp' tag to hide the app from the end-users in the My Apps portal
  tags: concat(helpers.flattenTags(tags), ['HideApp'])
  
  // The service management reference is required for tenants with Entra IDs enabled by Service Tree management 
  // and must be a valid Service Tree ID in this case
  serviceManagementReference: serviceManagementReference != '' ? serviceManagementReference : null
}

resource backendServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: backendAppRegistration.appId
  appRoleAssignmentRequired: true // When true, clients must have an app role assigned in order to retrieve an access token
}

//=============================================================================
// Outputs
//=============================================================================

output appId string = backendAppRegistration.appId
