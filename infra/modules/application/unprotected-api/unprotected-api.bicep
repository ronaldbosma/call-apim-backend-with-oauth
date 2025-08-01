//=============================================================================
// Unprotected API in API Management
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import * as helpers from '../../../functions/helpers.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the API Management service')
param apiManagementServiceName string

@description('The OAuth target resource for which a JWT token is requested by the APIM managed identity')
param oauthTargetResource string

@description('The name of the Key Vault that contains the secrets')
param keyVaultName string

@description('The ID of the client used for connecting to the protected API.')
param clientId string

@description('The name of the client secret in Key Vault used for connecting to the protected API')
param clientSecretName string

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apiManagementServiceName
}

//=============================================================================
// Resources
//=============================================================================

// Named Values

resource apimGatewayUrlNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  name: 'apim-gateway-url'
  parent: apiManagementService
  properties: {
    displayName: 'apim-gateway-url'
    value: helpers.getApiManagementGatewayUrl(apiManagementServiceName)
  }
}

resource oauthTargetResourceNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  name: 'oauth-target-resource'
  parent: apiManagementService
  properties: {
    displayName: 'oauth-target-resource'
    value: oauthTargetResource
  }
}

resource clientIdNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  name: 'client-id'
  parent: apiManagementService
  properties: {
    displayName: 'client-id'
    value: clientId
  }
}

resource clientSecretNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  name: 'client-secret'
  parent: apiManagementService
  properties: {
    displayName: 'client-secret'
    keyVault: {
      secretIdentifier: helpers.getKeyVaultSecretUri(keyVaultName, clientSecretName)
    }
    secret: true    
  }
}

// API

resource unprotectedApi 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  name: 'unprotected-api'
  parent: apiManagementService
  properties: {
    displayName: 'Unprotected API'
    path: 'unprotected'
    protocols: [ 
      'https' 
    ]
    subscriptionRequired: false // API is unprotected
  }
  
  // API scoped policy
  resource policies 'policies' = {
    name: 'policy'
    properties: {
      format: 'rawxml'
      value: loadTextContent('unprotected-api.xml')
    }
  }

  // Operation that will call the protected API without any authentication
  resource callProtectedApiWithoutAuthentication 'operations' = {
    name: 'call-protected-api-without-authentication'
    properties: {
      displayName: 'Call Protected API without Authentication'
      method: 'GET'
      urlTemplate: '/call-protected-api-without-authentication'
    }
  }

  // Operation that will call the protected API using the send-request policy with a secret
  resource callProtectedApiUsingSendRequestWithSecret 'operations' = {
    name: 'call-protected-api-using-send-request-with-secret'
    properties: {
      displayName: 'Call Protected API using Send Request with Secret'
      method: 'GET'
      urlTemplate: '/call-protected-api-using-send-request-with-secret'
    }
  
    resource policies 'policies' = {
      name: 'policy'
      properties: {
        format: 'rawxml'
        value: loadTextContent('call-protected-api-using-send-request-with-secret.xml')
      }
    }
  }

  dependsOn: [
    apimGatewayUrlNamedValue
    oauthTargetResourceNamedValue
  ]
}
