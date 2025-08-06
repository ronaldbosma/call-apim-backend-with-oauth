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

### Execute scenarios

To execute the scenarios, first:

1. Open the [tests.http](https://github.com/ronaldbosma/call-apim-backend-with-oauth/blob/main/tests/tests.http) file in e.g. Visual Studio Code.

1. Replace `<your-api-management-service-name>` with the name of your API Management service.

#### Call protected API without authentication

In this scenario, the unprotected API calls the protected API without any authentication. 
This should fail because the protected API requires an access token. 

![Sequence Diagram - Without Authentication](https://raw.githubusercontent.com/ronaldbosma/call-apim-backend-with-oauth/refs/heads/main/images/diagrams-without-authentication.png)

Execute the first request `Operation that will call the protected API without any authentication (should fail)` in the `tests.http` file. 
A 401 Unauthorized response should be returned.

#### Call protected API using Credential Manager

In this scenario, the unprotected API calls the protected API using the Credential Manager to retrieve an access token.

![Sequence Diagram - Credential Manager](https://raw.githubusercontent.com/ronaldbosma/call-apim-backend-with-oauth/refs/heads/main/images/diagrams-credential-manager.png)

Execute the second request `Operation that will call the protected API using the Credential Manager` in the `tests.http` file. 
A 200 OK response should be returned with details about the bearer token used to call the protected API.

If you execute this request multiple times, you will see that the data in the response, like `IssuedAt`, does not change because the Credential Manager caches the access token.

#### Call protected API using send-request policy with a secret

In this scenario, the unprotected API first uses the [send-request](https://learn.microsoft.com/en-us/azure/api-management/send-request-policy) policy to call Entra ID to retrieve an access token using the client credentials flow with a client secret.
Then, it calls the protected API using the access token.

![Sequence Diagram - Send Request with Secret](https://raw.githubusercontent.com/ronaldbosma/call-apim-backend-with-oauth/refs/heads/main/images/diagrams-send-request-with-secret.png)

Execute the third request `Operation that will call the protected API using the send-request policy with a secret` in the `tests.http` file. 
A 200 OK response should be returned with details about the bearer token used to call the protected API.

As with the Credential Manager scenario, if you execute this request multiple times, you will see that the data in the response, like `IssuedAt`, does not change because the access token is cached.

#### Call protected API using send-request policy with a certificate

In this scenario, the unprotected API first generates a JWT assertion and signs it with a certificate.
Then, it uses the [send-request](https://learn.microsoft.com/en-us/azure/api-management/send-request-policy) policy to call Entra ID to retrieve an access token using the client credentials flow with a client assertion.
Finally, it calls the protected API using the access token.

![Sequence Diagram - Send Request with Certificate](https://raw.githubusercontent.com/ronaldbosma/call-apim-backend-with-oauth/refs/heads/main/images/diagrams-send-request-with-certificate.png)

Execute the fourth request `Operation that will call the protected API using the send-request policy with a certificate (client_assertion)` in the `tests.http` file.
A 200 OK response should be returned with details about the bearer token used to call the protected API.

If you execute this request multiple times, you will see that the data in the response, like `IssuedAt`, does not change because the access token is cached.

The value of the `azpacr` claim is `2` because a client certificate is used for authentication. In the previous scenarios, the value of the `azpacr` claim was `1` because a client secret was used for authentication.