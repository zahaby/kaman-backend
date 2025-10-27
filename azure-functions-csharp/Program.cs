using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using KamanAzureFunctions.Helpers;
using KamanAzureFunctions.Services;

var host = new HostBuilder()
    .ConfigureFunctionsWebApplication()
    .ConfigureServices((context, services) =>
    {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();

        var configuration = context.Configuration;

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

        // Register Services
        services.AddScoped<CompanyService>();
        services.AddScoped(sp => new UserService(
            sp.GetRequiredService<DatabaseHelper>(),
            sp.GetRequiredService<JwtHelper>(),
            defaultPassword
        ));
    })
    .Build();

host.Run();
