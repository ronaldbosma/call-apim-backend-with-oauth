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
  tags: helpers.flattenTags(tags)
  
  uniqueName: name
  displayName: name

  owners: {
    relationships: [
      deployer().objectId
    ]
  }
}

resource clientServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: clientAppRegistration.appId
}

//=============================================================================
// Resources
//=============================================================================

output appId string = clientAppRegistration.appId
