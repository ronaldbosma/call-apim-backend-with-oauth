//=============================================================================
// Assign roles to principal on resources like App Insights and Key Vault
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The id of the principal that will be assigned the roles')
param principalId string

@description('The type of the principal that will be assigned the roles')
param principalType string?

@description('The flag to determine if the principal is an admin or not')
param isAdmin bool = false

@description('The name of the App Insights instance on which to assign roles')
param appInsightsName string

@description('The name of the Key Vault on which to assign roles')
param keyVaultName string

//=============================================================================
// Variables
//=============================================================================

var keyVaultRoleName string = isAdmin ? 'Key Vault Administrator' : 'Key Vault Secrets User'

var monitoringMetricsPublisherRoleName string = 'Monitoring Metrics Publisher'

//=============================================================================
// Existing Resources
//=============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyVaultName
}

//=============================================================================
// Resources
//=============================================================================

// Assign role Application Insights to the principal

resource assignAppInsightRolesToPrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, appInsights.id, roleDefinitions(monitoringMetricsPublisherRoleName).id)
  scope: appInsights
  properties: {
    #disable-next-line use-resource-id-functions
    roleDefinitionId: roleDefinitions(monitoringMetricsPublisherRoleName).id
    principalId: principalId
    principalType: principalType
  }
}

// Assign role on Key Vault to the principal

resource assignRolesOnKeyVaultToPrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, keyVault.id, roleDefinitions(keyVaultRoleName).id)
  scope: keyVault
  properties: {
    #disable-next-line use-resource-id-functions
    roleDefinitionId: roleDefinitions(keyVaultRoleName).id
    principalId: principalId
    principalType: principalType
  }
}
