// API Management

@description('The SKU of the API Management service')
type apimSkuType = 'Consumption' | 'Developer' | 'Basic' | 'Standard' | 'Premium' | 'StandardV2' | 'BasicV2'

@description('The settings for the API Management service')
@export()
type apiManagementSettingsType = {
  @description('The name of the API Management service')
  serviceName: string

  @description('The SKU of the API Management service')
  sku: apimSkuType
}


// Application Insights

@description('Retention options for Application Insights')
type appInsightsRetentionInDaysType = 30 | 60 | 90 | 120 | 180 | 270 | 365 | 550 | 730

@description('The settings for the App Insights instance')
@export()
type appInsightsSettingsType = {
  @description('The name of the App Insights instance')
  appInsightsName: string

  @description('The name of the Log Analytics workspace that will be used by the App Insights instance')
  logAnalyticsWorkspaceName: string

  @description('Retention in days of the logging')
  retentionInDays: appInsightsRetentionInDaysType
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
