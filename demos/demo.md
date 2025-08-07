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

### Setup

Before you start testing the scenarios, you need to prepare the test file:

1. Open the [tests.http](https://github.com/ronaldbosma/call-apim-backend-with-oauth/blob/main/tests/tests.http) file in Visual Studio Code.

1. Replace `<your-api-management-service-name>` with the name of your API Management service.


### Review the API policies

Let's start by understanding what makes one API protected and the other unprotected.

**Protected API policy**

The protected API uses the `validate-azure-ad-token` policy to enforce OAuth authentication. This policy:
- Validates that the JWT token was issued by the correct Entra ID tenant
- Checks that the token's audience matches the backend app registration 
- Requires the `Sample.Read` role in the token's claims

You can find this policy in [protected-api.xml](https://github.com/ronaldbosma/call-apim-backend-with-oauth/blob/main/src/apis/protected-api/protected-api.xml).

**Unprotected API structure**

The unprotected API doesn't require authentication and acts as a proxy to demonstrate different ways of calling the protected API. 
Each operation in this API forwards requests to the protected API using a different authentication approach.


### Demonstrate the problem

**Call protected API without authentication**

Execute the first request `Operation that will call the protected API without any authentication (should fail)` in the `tests.http` file.

![Sequence Diagram - Without Authentication](https://raw.githubusercontent.com/ronaldbosma/call-apim-backend-with-oauth/refs/heads/main/images/diagrams-without-authentication.png)

You'll receive a 401 Unauthorized response. This shows that the protected API can't be called without proper OAuth authentication.


### Solution 1: Credential Manager

**Execute the Credential Manager scenario**

Execute the second request `Operation that will call the protected API using the Credential Manager` in the `tests.http` file.

![Sequence Diagram - Credential Manager](https://raw.githubusercontent.com/ronaldbosma/call-apim-backend-with-oauth/refs/heads/main/images/diagrams-credential-manager.png)

You'll receive a 200 OK response with details about the bearer token used to call the protected API.

**Review the Credential Manager configuration**

The Credential Manager is Azure's managed solution for handling OAuth tokens. 
You can find the configuration in [credential-manager.bicep](https://github.com/ronaldbosma/call-apim-backend-with-oauth/blob/main/src/apis/unprotected-api/credential-manager.bicep).

When viewing the Bicep file, you'll see the configuration uses three components:
- **Authorization Provider**: Defines the OAuth endpoint and authentication method
- **Authorization** Links the provider to specific credentials
- **Access Policy**: Controls which APIs can use the authorization

In the Azure portal, navigate to your API Management service and look for the Credential Manager section. You'll see a credential provider that handles token acquisition and caching automatically.

**Review the policy implementation**

The policy uses the `get-authorization-context` element to retrieve an access token from the Credential Manager. 
You can see this simple implementation in [credential-manager.xml](https://github.com/ronaldbosma/call-apim-backend-with-oauth/blob/main/src/apis/unprotected-api/credential-manager.xml).

The Credential Manager handles all the complexity of token acquisition, caching and refresh automatically.


### Solution 2: send-request policy with client secret

**Execute the client secret scenario**

Execute the third request `Operation that will call the protected API using the send-request policy with a secret` in the `tests.http` file.

![Sequence Diagram - Send Request with Secret](https://raw.githubusercontent.com/ronaldbosma/call-apim-backend-with-oauth/refs/heads/main/images/diagrams-send-request-with-secret.png)

You'll receive a 200 OK response with details about the bearer token.

**Review the policy implementation**

Open [send-request-with-secret.xml](https://github.com/ronaldbosma/call-apim-backend-with-oauth/blob/main/src/apis/unprotected-api/send-request-with-secret.xml) to see how this works:

1. **Cache lookup**: The policy first checks if an access token already exists in the cache
1. **Token acquisition**: If no cached token exists, it uses `send-request` to call the Entra ID token endpoint with the client credentials flow
1. **Error handling**: If token retrieval fails, the error is traced and a 500 response is returned (this explicit error tracing doesn't happen by default)
1. **Caching**: Successful tokens are cached for 90% of their lifetime to prevent expiration issues
1. **Authorization header**: The token is added to the Authorization header before calling the protected API

The client secret is retrieved from Azure Key Vault using API Management's named values feature.


### Solution 3: send-request policy with client certificate

**Execute the client certificate scenario**

Execute the fourth request `Operation that will call the protected API using the send-request policy with a certificate (client_assertion)` in the `tests.http` file.

![Sequence Diagram - Send Request with Certificate](https://raw.githubusercontent.com/ronaldbosma/call-apim-backend-with-oauth/refs/heads/main/images/diagrams-send-request-with-certificate.png)

You'll receive a 200 OK response with details about the bearer token.

**Review the JWT assertion creation**

Open [send-request-with-certificate.xml](https://github.com/ronaldbosma/call-apim-backend-with-oauth/blob/main/src/apis/unprotected-api/send-request-with-certificate.xml) to see the implementation. This approach is more complex but more secure:

1. **Certificate retrieval**: The policy uses `context.Deployment.Certificates` to retrieve the certificate from Key Vault. `context.Deployment.Certificates` is a dictionary with the thumbprint as key. You can find the certificate reference under the Certificates section of your API Management service.
1. **JWT assertion creation**: The policy creates a JWT assertion with specific claims required by Entra ID
1. **Certificate signing**: The JWT is signed using the client certificate's private key with PSS padding
1. **Base64Url encoding**: The JWT uses Base64Url encoding (different from standard Base64)
1. **Token request**: The signed JWT assertion is sent to Entra ID using the client credentials flow
1. **Error handling**: Similar to the secret approach, errors are traced and 500 responses are returned

**Understand certificate authentication**

The [Microsoft identity platform application authentication certificate credentials](https://learn.microsoft.com/en-us/entra/identity-platform/certificate-credentials) documentation explains how client assertions work. Key points:

- Certificates provide stronger security than shared secrets
- The JWT assertion proves possession of the private key without transmitting it
- Entra ID validates the assertion using the public key from the certificate


### Compare the approaches

**Token caching behavior**

If you execute any request multiple times, you'll notice that the `IssuedAt` value in the response doesn't change. This shows that all three approaches cache access tokens effectively.

**Security differences**

You can observe the security difference in the `azpacr` claim:
- Value `1`: Client secret authentication (Credential Manager and secret scenarios)
- Value `2`: Client certificate authentication (certificate scenario)

**Management complexity**

1. **Credential Manager**: Azure manages everything automatically
1. **Client secret**: You manage token acquisition but Azure manages the secret
1. **Client certificate**: You manage both token acquisition and certificate lifecycle

### Monitoring and troubleshooting

You can monitor these requests in Application Insights. Each approach generates different trace patterns:

- Credential Manager requests don't show token acquisition details
- send-request policies don't generate any tracing by default, so the policies explicitly trace failures and return 500 responses with error details
- Certificate-based requests include the signed client assertion in error responses (for debugging only)

When token retrieval fails in the send-request scenarios, you'll see detailed error information because the policies explicitly trace failures and return 500 responses with error details.