using Microsoft.Extensions.Configuration;

namespace IntegrationTests.Configuration;

/// <summary>
/// Contains configuration settings for the integration tests.
/// </summary>
internal class TestConfiguration
{
    private static readonly Lazy<TestConfiguration> _instance = new(() =>
    {
        AzdDotEnv.Load(optional: true); // Loads Azure Developer CLI environment variables; optional since .env file might be missing in CI/CD pipelines

        var configuration = new ConfigurationBuilder()
            .AddEnvironmentVariables()
            .Build();

        return new TestConfiguration
        {
            AzureApiManagementGatewayUrl = configuration.GetRequiredUri("AZURE_API_MANAGEMENT_GATEWAY_URL")
        };
    });

    public required Uri AzureApiManagementGatewayUrl { get; init; }

    public static TestConfiguration Load() => _instance.Value;
}