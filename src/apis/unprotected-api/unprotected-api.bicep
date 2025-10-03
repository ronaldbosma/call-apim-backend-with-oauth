//=============================================================================
// Unprotected API in API Management
//
// The operations of this API demonstrate different ways to call a backend API
// that is protected by OAuth. The Protected Backend API is used as the backend.
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

@description('The ID of the client used for connecting to the Protected Backend API.')
param clientId string

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apiManagementServiceName
}

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: keyVaultName
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

module credentialManager 'credential-manager.bicep' = {
  params: {
    apiManagementServiceName: apiManagementServiceName
    oauthTargetResource: oauthTargetResource
    clientId: clientId
    clientSecret: keyVault.getSecret('client-secret')
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

    dependsOn: [
      apimGatewayUrlNamedValue
    ]
  }

  // Operation that will call the Protected Backend API without any authentication
  resource callProtectedApiWithoutAuthentication 'operations' = {
    name: 'without-authentication'
    properties: {
      displayName: 'Without Authentication'
      method: 'GET'
      urlTemplate: '/without-authentication'
    }
  }

  // Operation that will call the Protected Backend API using the Credential Manager
  resource callProtectedApiUsingCredentialManager 'operations' = {
    name: 'credential-manager'
    properties: {
      displayName: 'Use Credential Manager'
      method: 'GET'
      urlTemplate: '/credential-manager'
    }
  
    resource policies 'policies' = {
      name: 'policy'
      properties: {
        format: 'rawxml'
        value: loadTextContent('credential-manager.xml')
      }

      dependsOn: [
        credentialManager
      ]
    }
  }

  // Operation that will call the Protected Backend API using the send-request policy with a secret
  resource callProtectedApiUsingSendRequestWithSecret 'operations' = {
    name: 'send-request-with-secret'
    properties: {
      displayName: 'Use Send Request with Secret'
      method: 'GET'
      urlTemplate: '/send-request-with-secret'
    }
  
    resource policies 'policies' = {
      name: 'policy'
      properties: {
        format: 'rawxml'
        value: loadTextContent('send-request-with-secret.xml')
      }

      dependsOn: [
        clientIdNamedValue
        clientSecretNamedValue
        oauthScopeNamedValue
      ]
    }
  }

  // Operation that will call the Protected Backend API using the send-request policy with a certificate (client_assertion)
  resource callProtectedApiUsingSendRequestWithCertificate 'operations' = {
    name: 'send-request-with-certificate'
    properties: {
      displayName: 'Use Send Request with Certificate'
      method: 'GET'
      urlTemplate: '/send-request-with-certificate'
    }
  
    resource policies 'policies' = {
      name: 'policy'
      properties: {
        format: 'rawxml'
        value: loadTextContent('send-request-with-certificate.xml')
      }

      dependsOn: [
        clientIdNamedValue
        clientCertificateThumbprintNamedValue
        oauthScopeNamedValue
      ]
    }
  }
}
