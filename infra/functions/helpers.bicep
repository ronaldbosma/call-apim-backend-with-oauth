//=============================================================================
// Helper functions to construct URLs, Key Vault references, etc.
//=============================================================================

// API Management functions

@export()
func getApiManagementGatewayUrl(apimServiceName string) string => 'https://${apimServiceName}.azure-api.net'

// Key Vault functions

@export()
func getKeyVaultSecretReference(keyVaultName string, secretName string) string => '@Microsoft.KeyVault(SecretUri=${getKeyVaultSecretUri(keyVaultName, secretName)})'

@export()
func getKeyVaultSecretUri(keyVaultName string, secretName string) string => 'https://${keyVaultName}${environment().suffixes.keyvaultDns}/secrets/${secretName}'

// Storage Account functions

@export()
func getBlobStorageEndpoint(storageAccountName string) string => 'https://${storageAccountName}.blob.${environment().suffixes.storage}'

@export()
func getFileStorageEndpoint(storageAccountName string) string => 'https://${storageAccountName}.file.${environment().suffixes.storage}'

@export()
func getQueueStorageEndpoint(storageAccountName string) string => 'https://${storageAccountName}.queue.${environment().suffixes.storage}'

@export()
func getTableStorageEndpoint(storageAccountName string) string => 'https://${storageAccountName}.table.${environment().suffixes.storage}'

// Tags

@export()
func flattenTags(tags { *: string }) string[] => map(items(tags), tag => '${tag.key}: ${tag.value}')
