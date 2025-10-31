using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using KamanAzureFunctions.DTOs;
using KamanAzureFunctions.Helpers;
using KamanAzureFunctions.Services;
using Dapper;

namespace KamanAzureFunctions.Functions;

/// <summary>
/// Bootstrap function to create the initial super admin user.
/// WARNING: This endpoint should be disabled or removed in production after initial setup!
/// </summary>
public class BootstrapFunction
{
    private readonly ILogger<BootstrapFunction> _logger;
    private readonly UserService _userService;
    private readonly DatabaseHelper _dbHelper;

    public BootstrapFunction(
        ILogger<BootstrapFunction> logger,
        UserService userService,
        DatabaseHelper dbHelper)
    {
        _logger = logger;
        _userService = userService;
        _dbHelper = dbHelper;
    }

    [Function("Bootstrap")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "bootstrap/super-admin")] HttpRequestData req)
    {
        _logger.LogWarning("Bootstrap endpoint called - this should only be used for initial setup!");

        try
        {
            // Parse request body
            var request = await req.ReadFromJsonAsync<BootstrapRequest>();
            if (request == null)
            {
                return await ResponseHelper.ErrorResponse(req, "Invalid request body");
            }

            // Validate the bootstrap secret to prevent unauthorized use
            if (string.IsNullOrEmpty(request.BootstrapSecret) || request.BootstrapSecret != "KamanBootstrap2025!")
            {
                _logger.LogWarning("Bootstrap attempt with invalid secret");
                return await ResponseHelper.UnauthorizedResponse(req, "Invalid bootstrap secret");
            }

            // Check if any super admin already exists
            using var connection = _dbHelper.GetConnection();
            await connection.OpenAsync();

            var existingSuperAdmins = await connection.QueryAsync<dynamic>(
                @"SELECT u.UserId, u.Email
                  FROM [auth].[Users] u
                  JOIN [auth].[UserRoles] ur ON u.UserId = ur.UserId
                  JOIN [auth].[Roles] r ON ur.RoleId = r.RoleId
                  WHERE r.Name = 'SUPER_ADMIN'
                    AND u.DeletedAtUtc IS NULL"
            );

            if (existingSuperAdmins.Any())
            {
                _logger.LogInformation("Super admin already exists - bootstrap not needed");
                return await ResponseHelper.ErrorResponse(
                    req,
                    "Super admin user already exists. Bootstrap is only for initial setup.",
                    HttpStatusCode.Conflict
                );
            }

            // Ensure SUPER_ADMIN role exists
            var superAdminRole = await connection.QueryFirstOrDefaultAsync<dynamic>(
                @"SELECT RoleId, Name FROM [auth].[Roles]
                  WHERE Name = 'SUPER_ADMIN'"
            );

            long superAdminRoleId;
            if (superAdminRole == null)
            {
                _logger.LogInformation("Creating SUPER_ADMIN role");

                superAdminRoleId = await connection.ExecuteScalarAsync<long>(
                    @"INSERT INTO [auth].[Roles] (Name, Description)
                      OUTPUT INSERTED.RoleId
                      VALUES ('SUPER_ADMIN', 'Full system access')"
                );
            }
            else
            {
                superAdminRoleId = superAdminRole.RoleId;
            }

            // Create the super admin user
            var email = request.Email ?? "superadmin@kaman.com";
            var displayName = request.DisplayName ?? "Super Administrator";
            var password = request.Password ?? "Kaman@2025";

            // Validate password strength
            var passwordValidation = PasswordHelper.ValidatePasswordStrength(password);
            if (!passwordValidation.IsValid)
            {
                return await ResponseHelper.ErrorResponse(
                    req,
                    $"Password validation failed: {passwordValidation.ErrorMessage}"
                );
            }

            // Hash the password
            var passwordHash = PasswordHelper.HashPassword(password);

            // Insert the user
            var userId = await connection.ExecuteScalarAsync<long>(
                @"INSERT INTO [auth].[Users] (
                    CompanyId,
                    Email,
                    DisplayName,
                    PasswordHash,
                    IsActive,
                    IsLocked,
                    FailedLoginAttempts
                  )
                  OUTPUT INSERTED.UserId
                  VALUES (
                    NULL,  -- Super admin doesn't belong to any company
                    @Email,
                    @DisplayName,
                    @PasswordHash,
                    1,  -- IsActive
                    0,  -- IsLocked
                    0   -- FailedLoginAttempts
                  )",
                new
                {
                    Email = email,
                    DisplayName = displayName,
                    PasswordHash = passwordHash
                }
            );

            // Assign SUPER_ADMIN role to the user
            await connection.ExecuteAsync(
                @"INSERT INTO [auth].[UserRoles] (UserId, RoleId)
                  VALUES (@UserId, @RoleId)",
                new { UserId = userId, RoleId = superAdminRoleId }
            );

            _logger.LogInformation($"Super admin user created successfully: {email}");

            var responseData = new
            {
                UserId = userId,
                Email = email,
                DisplayName = displayName,
                Message = "Super admin user created successfully. You can now login with these credentials.",
                Warning = "IMPORTANT: Consider disabling or removing this bootstrap endpoint in production!"
            };

            return await ResponseHelper.SuccessResponse(
                req,
                responseData,
                "Bootstrap completed successfully",
                HttpStatusCode.Created
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during bootstrap");
            return await ResponseHelper.ServerErrorResponse(req, "Bootstrap failed", ex.ToString());
        }
    }
}

public class BootstrapRequest
{
    public string BootstrapSecret { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? DisplayName { get; set; }
    public string? Password { get; set; }
}
