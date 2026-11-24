//=============================================================================
// Assign App Roles to the Client App Registration
//=============================================================================

targetScope = 'subscription'

//=============================================================================
// Extensions
//=============================================================================

extension microsoftGraphV1

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the backend app registration')
param backendAppRegistrationName string

@description('The name of the client app registration')
param clientAppRegistrationName string

//=============================================================================
// Existing Resources
//=============================================================================

@retryOn(['NotFound']) // Retry on failure because the app registration might not be immediately available after creation
resource backendAppRegistration 'Microsoft.Graph/applications@v1.0' existing = {
  uniqueName: backendAppRegistrationName
}

@retryOn(['NotFound']) // Retry on failure because the service principal might not be immediately available after creation
resource backendServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' existing = {
  appId: backendAppRegistration.appId
}

@retryOn(['NotFound']) // Retry on failure because the app registration might not be immediately available after creation
resource clientAppRegistration 'Microsoft.Graph/applications@v1.0' existing = {
  uniqueName: clientAppRegistrationName
}

@retryOn(['NotFound']) // Retry on failure because the service principal might not be immediately available after creation
resource clientServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' existing = {
  appId: clientAppRegistration.appId
}

//=============================================================================
// Functions
//=============================================================================

func getAppRoleIdByValue(appRoles resourceInput<'Microsoft.Graph/applications@v1.0'>.appRoles, value string) string =>
  first(filter(appRoles, (role) => role.value == value))!.id

//=============================================================================
// Variables
//=============================================================================

var rolesToAssign string[] = [
  'Sample.Read'
  'Sample.Write'
]

//=============================================================================
// Resources
//=============================================================================

@retryOn(['BadRequest']) // Retry on failure because a service principal might not be immediately available after creation
resource assignAppRole 'Microsoft.Graph/appRoleAssignedTo@v1.0' = [
  for role in rolesToAssign: {
    resourceId: backendServicePrincipal.id
    appRoleId: getAppRoleIdByValue(backendAppRegistration.appRoles, role)
    principalId: clientServicePrincipal.id
  }
]
