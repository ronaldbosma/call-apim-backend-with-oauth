//=============================================================================
// Credential Manager
//
// This configuration is placed in a separate module so that we can pass in
// the client secret using: keyVault.getSecret('client-secret')
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the API Management service')
param apiManagementServiceName string

@description('The OAuth target resource for which a JWT token is requested by the APIM managed identity')
param oauthTargetResource string

@description('The ID of the client used for connecting to the Protected Backend API.')
param clientId string

@description('The secret of the client used for connecting to the Protected Backend API.')
@secure()
param clientSecret string

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apiManagementServiceName
}

//=============================================================================
// Resources
//=============================================================================

// Create a Credential Provider that will be used to retrieve the access token for the Protected Backend API.
resource credentialProvider 'Microsoft.ApiManagement/service/authorizationProviders@2024-06-01-preview' = {
  parent: apiManagementService
  name: 'credential-provider'
  properties: {
    displayName: 'Credential Provider'
    identityProvider: 'aad'
    oauth2: {
      grantTypes: {
        clientCredentials: {
          resourceUri: oauthTargetResource
          tenantId: subscription().tenantId
        }
      }
    }
  }

  // Add a connection to the Credential Provider for our client
  resource clientConnection 'authorizations' = {
    name: 'client-connection'
    properties: {
      authorizationType: 'OAuth2'
      oauth2grantType: 'ClientCredentials'
      parameters: {
        clientId: clientId
        clientSecret: clientSecret
      }
    }

    // Give the system-assigned managed identity of API Management permission to use the connection
    resource accessPolicies 'accessPolicies' = {
      name: 'client-connection-access-policy-apim-managed-identity'
      properties: {
        objectId: apiManagementService.identity.principalId
        tenantId: apiManagementService.identity.tenantId
      }
    }
  }
}
