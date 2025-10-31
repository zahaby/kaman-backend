using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using KamanAzureFunctions.DTOs;
using KamanAzureFunctions.Helpers;
using KamanAzureFunctions.Services;
using Dapper;
using System.Data;

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
                "[auth].[sp_CheckSuperAdminExists]",
                commandType: CommandType.StoredProcedure
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
                "[auth].[sp_CheckRoleExists]",
                new { RoleName = "SUPER_ADMIN" },
                commandType: CommandType.StoredProcedure
            );

            long superAdminRoleId;
            if (superAdminRole == null)
            {
                _logger.LogInformation("Creating SUPER_ADMIN role");

                var roleResult = await connection.QuerySingleAsync<dynamic>(
                    "[auth].[sp_InsertRole]",
                    new { Name = "SUPER_ADMIN", Description = "Full system access" },
                    commandType: CommandType.StoredProcedure
                );
                superAdminRoleId = roleResult.RoleId;
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
            var userResult = await connection.QuerySingleAsync<dynamic>(
                "[auth].[sp_InsertUser]",
                new
                {
                    CompanyId = (long?)null,  // Super admin doesn't belong to any company
                    Email = email,
                    DisplayName = displayName,
                    PasswordHash = passwordHash,
                    IsActive = true
                },
                commandType: CommandType.StoredProcedure
            );

            long userId = userResult.UserId;

            // Assign SUPER_ADMIN role to the user
            await connection.ExecuteAsync(
                "[auth].[sp_AssignRoleToUser]",
                new { UserId = userId, RoleId = superAdminRoleId },
                commandType: CommandType.StoredProcedure
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
