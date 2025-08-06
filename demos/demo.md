# Call API Management backend with OAuth - Demo

This demo shows how to call a backend API in Azure API Management using OAuth.

The template deployes an Azure API Management service with two APIs: one unprotected and one protected with OAuth. It also deploys an app registration in Entra ID for the backend (protected API) and one for the client app registration (used by unprotected API). A secret and certificate are generated on the client app registration and stored in Key Vault to be used by the unprotected API. See the following diagram for an overview:

![Overview](https://raw.githubusercontent.com/ronaldbosma/call-apim-backend-with-oauth/refs/heads/main/images/diagrams-overview.png)

## 1. What resources get deployed

The following resources are deployed in a resource group in your Azure subscription:

![Deployed Resources](https://raw.githubusercontent.com/ronaldbosma/call-apim-backend-with-oauth/refs/heads/main/images/deployed-resources.png)

The following app registrations are created in your Entra ID tenant:

![Deployed App Registrations](https://raw.githubusercontent.com/ronaldbosma/call-apim-backend-with-oauth/refs/heads/main/images/deployed-app-registrations.png)

The deployed resources follow the naming convention: `<resource-type>-<environment-name>-<region>-<instance>`.


## 2. What you can demo after deployment