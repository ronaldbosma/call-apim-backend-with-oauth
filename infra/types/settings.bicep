// API Management

@description('The settings for the API Management service')
@export()
type apiManagementSettingsType = {
  @description('The name of the API Management service')
  serviceName: string

  @description('The name of the owner of the API Management service')
  publisherName: string

  @description('The email address of the owner of the API Management service')
  publisherEmail: string
}


// Application Insights

@description('The settings for the App Insights instance')
@export()
type appInsightsSettingsType = {
  @description('The name of the App Insights instance')
  appInsightsName: string

  @description('The name of the Log Analytics workspace that will be used by the App Insights instance')
  logAnalyticsWorkspaceName: string

  @description('Retention in days of the logging')
  retentionInDays: int
}


// Backend App Registration

@description('The settings for the backend app registration')
@export()
type backendSettingsType = {

  @description('The name of the backend app registration in Entra ID')
  appRegistrationName: string

  @description('The identifier URI for the backend app registration')
  appRegistrationIdentifierUri: string
}
