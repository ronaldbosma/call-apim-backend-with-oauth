//=============================================================================
// APIs in API Management
//
// The APIs has been split of in a separete module from the infra because we need 
// the client secret and certificate to be stored in Key Vault.
// They are created in a postprovision script after the inra is created.
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the API Management service')
param apiManagementServiceName string

@description('The name of the Key Vault that contains the secrets')
param keyVaultName string

@description('The expected OAuth audience for the JWT token')
param oauthAudience string

@description('The OAuth target resource for which a JWT token is requested by the APIM managed identity')
param oauthTargetResource string

@description('The ID of the client used for connecting to the protected backend.')
param clientId string

//=============================================================================
// Resources
//=============================================================================

module protectedBackendApi 'protected-backend-api/protected-backend-api.bicep' = {
  params: {
    apiManagementServiceName: apiManagementServiceName
    tenantId: subscription().tenantId
    oauthAudience: oauthAudience
  }
}

module unprotectedApi 'unprotected-api/unprotected-api.bicep' = {
  params: {
    apiManagementServiceName: apiManagementServiceName
    tenantId: subscription().tenantId
    oauthTargetResource: oauthTargetResource
    keyVaultName: keyVaultName
    clientId: clientId
  }
}
