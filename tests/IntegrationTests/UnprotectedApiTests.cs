using IntegrationTests.Configuration;
using IntegrationTests.Handlers;
using System.Net;

namespace IntegrationTests;

/// <summary>
/// Tests scenarios where the Unprotected API is called, which inturn calls a Protected Backend with OAuth.
/// </summary>
[TestClass]
public sealed class UnprotectedApiTests
{
    private static HttpClient? HttpClient;

    [ClassInitialize]
    public static void ClassInitialize(TestContext context)
    {
        var config = TestConfiguration.Load();
        HttpClient = new HttpClient(new HttpMessageLoggingHandler(new HttpClientHandler()))
        {
            BaseAddress = config.AzureApiManagementGatewayUrl
        };
    }

    [ClassCleanup]
    public static void ClassCleanup()
    {
        HttpClient?.Dispose();
    }

    [TestMethod]
    public async Task GetWithoutAuthentication_ApimCallsProtectedBackendWithoutAuthentication_401UnauthorizedReturned()
    {
        // Act
        var response = await HttpClient!.GetAsync("unprotected/without-authentication");

        // Assert
        Assert.AreEqual(HttpStatusCode.Unauthorized, response.StatusCode, "Unexpected status code returned");
    }

    [TestMethod]
    public async Task GetCredentialManager_ApimCallsProtectedBackendUsingCredentialManager_200OkReturned()
    {
        // Act
        var response = await HttpClient!.GetAsync("unprotected/credential-manager");

        // Assert
        Assert.AreEqual(HttpStatusCode.OK, response.StatusCode, "Unexpected status code returned");
    }

    [TestMethod]
    public async Task GetSendRequestWithSecret_ApimCallsProtectedBackendUsingSendRequestPolicyWithSecret_200OkReturned()
    {
        // Act
        var response = await HttpClient!.GetAsync("unprotected/send-request-with-secret");

        // Assert
        Assert.AreEqual(HttpStatusCode.OK, response.StatusCode, "Unexpected status code returned");
    }

    [TestMethod]
    public async Task GetSendRequestWithCertificate_ApimCallsProtectedBackendUsingSendRequestPolicyWithCertificate_200OkReturned()
    {
        // Act
        var response = await HttpClient!.GetAsync("unprotected/send-request-with-certificate");

        // Assert
        Assert.AreEqual(HttpStatusCode.OK, response.StatusCode, "Unexpected status code returned");
    }
}
