using System.Net.Http;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using KamanAzureFunctions.Helpers;
using KamanAzureFunctions.Services;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices((hostContext, services) =>
    {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();

        // Get configuration
        var configuration = hostContext.Configuration;

        // Register DatabaseHelper
        var connectionString = configuration["DbConnectionString"]
            ?? throw new InvalidOperationException("Database connection string is not configured");
        services.AddSingleton(new DatabaseHelper(connectionString));

        // Register JwtHelper
        var jwtSecret = configuration["JwtSecret"]
            ?? throw new InvalidOperationException("JWT secret is not configured");
        var jwtRefreshSecret = configuration["JwtRefreshSecret"]
            ?? throw new InvalidOperationException("JWT refresh secret is not configured");
        var jwtExpiresInMinutes = int.Parse(configuration["JwtExpiresInMinutes"] ?? "60");
        var jwtRefreshExpiresInDays = int.Parse(configuration["JwtRefreshExpiresInDays"] ?? "7");

        services.AddSingleton(new JwtHelper(jwtSecret, jwtRefreshSecret, jwtExpiresInMinutes, jwtRefreshExpiresInDays));

        // Get default password
        var defaultPassword = configuration["DefaultPassword"] ?? "Kaman@2025";

        // Get Resal API configuration
        var resalApiBaseUrl = configuration["ResalApiBaseUrl"]
            ?? throw new InvalidOperationException("Resal API base URL is not configured");
        var resalApiBearerToken = configuration["ResalApiBearerToken"]
            ?? throw new InvalidOperationException("Resal API bearer token is not configured");

        // Register HttpClient for ResalService with proper configuration
        services.AddHttpClient("ResalClient", client =>
        {
            client.Timeout = TimeSpan.FromSeconds(30);
        })
        .ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler
        {
            AllowAutoRedirect = true,
            MaxAutomaticRedirections = 5
        });

        // Register Services
        services.AddScoped<CompanyService>();
        services.AddScoped(sp => new UserService(
            sp.GetRequiredService<DatabaseHelper>(),
            sp.GetRequiredService<JwtHelper>(),
            defaultPassword
        ));
        services.AddScoped(sp => new ResalService(
            sp.GetRequiredService<IHttpClientFactory>().CreateClient("ResalClient"),
            sp.GetRequiredService<ILogger<ResalService>>(),
            resalApiBaseUrl,
            resalApiBearerToken
        ));
    })
    .Build();

host.Run();
