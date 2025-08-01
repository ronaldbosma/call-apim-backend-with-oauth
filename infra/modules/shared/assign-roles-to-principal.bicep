//=============================================================================
// Assign roles to principal on resources like Key Vault
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

@description('The name of the Key Vault on which to assign roles')
param keyVaultName string

//=============================================================================
// Variables
//=============================================================================

var keyVaultRole = isAdmin 
  ? '00482a5a-887f-4fb3-b363-3b7fe8e74483'    // Key Vault Administrator
  : '4633458b-17de-408a-b874-0445c86b69e6'    // Key Vault Secrets User


//=============================================================================
// Existing Resources
//=============================================================================

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: keyVaultName
}

//=============================================================================
// Resources
//=============================================================================

// Assign role on Key Vault to the principal

resource assignRolesOnKeyVaultToPrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, keyVault.id, subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultRole))
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultRole)
    principalId: principalId
    principalType: principalType
  }
}
