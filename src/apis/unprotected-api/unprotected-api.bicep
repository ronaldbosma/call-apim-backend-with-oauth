//=============================================================================
// Unprotected API in API Management
//
// The operations of this API demonstrate different ways to call a backend API
// that is protected by OAuth. The protected API is used as the backend.
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import * as helpers from '../../../infra/functions/helpers.bicep'

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

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apiManagementServiceName
}

//=============================================================================
// Resources
//=============================================================================

// Certificates

resource clientCertificate 'Microsoft.ApiManagement/service/certificates@2024-06-01-preview' = {
  name: 'client-certificate'
  parent: apiManagementService
  properties: {
    keyVault: {
      secretIdentifier: helpers.getKeyVaultSecretUri(keyVaultName, 'client-certificate')
    }
  }
}


// Named Values

resource apimGatewayUrlNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  name: 'apim-gateway-url'
  parent: apiManagementService
  properties: {
    displayName: 'apim-gateway-url'
    value: helpers.getApiManagementGatewayUrl(apiManagementServiceName)
  }
}

resource oauthScopeNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  name: 'oauth-scope'
  parent: apiManagementService
  properties: {
    displayName: 'oauth-scope'
    value: '${oauthTargetResource}/.default'
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
      secretIdentifier: helpers.getKeyVaultSecretUri(keyVaultName, 'client-secret')
    }
    secret: true    
  }
}

// The client certificate thumbprint is used to retrieve the certificate from the 'context.Deployment.Certificates' dictionary.
// So, we store the thumbprint in a named value.
resource clientCertificateThumbprintNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  name: 'client-certificate-thumbprint'
  parent: apiManagementService
  properties: {
    displayName: 'client-certificate-thumbprint'
    value: clientCertificate.properties.thumbprint
  }
}


// Credential Manager

// Create a Credential Provider that will be used to retrieve the access token for the protected API.
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
        clientSecret: '...SECRET...'
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

  // Operation that will call the protected API using the Credential Manager
  resource callProtectedApiUsingCredentialManager 'operations' = {
    name: 'call-protected-api-using-credential-manager'
    properties: {
      displayName: 'Call Protected API using Credential Manager'
      method: 'GET'
      urlTemplate: '/call-protected-api-using-credential-manager'
    }
  
    resource policies 'policies' = {
      name: 'policy'
      properties: {
        format: 'rawxml'
        value: loadTextContent('call-protected-api-using-credential-manager.xml')
      }
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

  // Operation that will call the protected API using the send-request policy with a certificate (client_assertion)
  resource callProtectedApiUsingSendRequestWithCertificate 'operations' = {
    name: 'call-protected-api-using-send-request-with-certificate'
    properties: {
      displayName: 'Call Protected API using Send Request with Certificate'
      method: 'GET'
      urlTemplate: '/call-protected-api-using-send-request-with-certificate'
    }
  
    resource policies 'policies' = {
      name: 'policy'
      properties: {
        format: 'rawxml'
        value: loadTextContent('call-protected-api-using-send-request-with-certificate.xml')
      }
    }
  }

  dependsOn: [
    apimGatewayUrlNamedValue
    oauthScopeNamedValue
    credentialProvider
  ]
}
