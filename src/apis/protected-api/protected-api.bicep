//=============================================================================
// Protected API in API Management
//
// Represents a backend that is protected by OAuth.
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the API Management service')
param apiManagementServiceName string

@description('The ID of the tenant')
param tenantId string

@description('The expected OAuth audience for the JWT token')
param oauthAudience string

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

resource tenantIdNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  name: 'tenant-id'
  parent: apiManagementService
  properties: {
    displayName: 'tenant-id'
    value: tenantId
  }
}

resource oauthAudienceNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  name: 'oauth-audience'
  parent: apiManagementService
  properties: {
    displayName: 'oauth-audience'
    value: oauthAudience
  }
}

// API

resource protectedApi 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  name: 'protected-api'
  parent: apiManagementService
  properties: {
    displayName: 'Protected API'
    path: 'protected'
    protocols: [ 
      'https' 
    ]
    subscriptionRequired: false // API is protected with OAuth
  }
  
  resource policies 'policies' = {
    name: 'policy'
    properties: {
      format: 'rawxml'
      value: loadTextContent('protected-api.xml')
    }

    dependsOn: [
      tenantIdNamedValue
      oauthAudienceNamedValue
    ]
  }

  resource getOperation 'operations' = {
    name: 'get'
    properties: {
      displayName: 'Get'
      method: 'GET'
      urlTemplate: '/'
    }
  }
}
