using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using KamanAzureFunctions.DTOs;
using KamanAzureFunctions.Helpers;
using Dapper;

namespace KamanAzureFunctions.Functions;

/// <summary>
/// Emergency password reset function for super admin users.
/// WARNING: This endpoint should be used carefully and protected with a strong secret!
/// </summary>
public class ResetSuperAdminPasswordFunction
{
    private readonly ILogger<ResetSuperAdminPasswordFunction> _logger;
    private readonly DatabaseHelper _dbHelper;

    public ResetSuperAdminPasswordFunction(
        ILogger<ResetSuperAdminPasswordFunction> logger,
        DatabaseHelper dbHelper)
    {
        _logger = logger;
        _dbHelper = dbHelper;
    }

    [Function("ResetSuperAdminPassword")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "admin/reset-superadmin-password")] HttpRequestData req)
    {
        _logger.LogWarning("ResetSuperAdminPassword endpoint called - emergency password reset!");

        try
        {
            // Parse request body
            var request = await req.ReadFromJsonAsync<ResetSuperAdminPasswordRequest>();
            if (request == null)
            {
                return await ResponseHelper.ErrorResponse(req, "Invalid request body");
            }

            // Validate the reset secret to prevent unauthorized use
            if (string.IsNullOrEmpty(request.ResetSecret) || request.ResetSecret != "KamanResetSecret2025!")
            {
                _logger.LogWarning("Password reset attempt with invalid secret");
                return await ResponseHelper.UnauthorizedResponse(req, "Invalid reset secret");
            }

            // Validate email is provided
            if (string.IsNullOrWhiteSpace(request.Email))
            {
                return await ResponseHelper.ErrorResponse(req, "Email is required");
            }

            // Validate new password is provided
            if (string.IsNullOrWhiteSpace(request.NewPassword))
            {
                return await ResponseHelper.ErrorResponse(req, "New password is required");
            }

            // Validate password strength
            var passwordValidation = PasswordHelper.ValidatePasswordStrength(request.NewPassword);
            if (!passwordValidation.IsValid)
            {
                return await ResponseHelper.ErrorResponse(
                    req,
                    $"Password validation failed: {passwordValidation.ErrorMessage}"
                );
            }

            using var connection = _dbHelper.GetConnection();
            await connection.OpenAsync();

            // Verify the user exists and is a super admin
            var superAdmin = await connection.QueryFirstOrDefaultAsync<dynamic>(
                @"SELECT u.UserId, u.Email, u.DisplayName, u.IsActive
                  FROM [auth].[Users] u
                  JOIN [auth].[UserRoles] ur ON u.UserId = ur.UserId
                  JOIN [auth].[Roles] r ON ur.RoleId = r.RoleId
                  WHERE u.Email = @Email
                    AND r.Name = 'SUPER_ADMIN'
                    AND u.DeletedAtUtc IS NULL",
                new { Email = request.Email }
            );

            if (superAdmin == null)
            {
                _logger.LogWarning($"Password reset attempt for non-existent or non-super-admin user: {request.Email}");
                return await ResponseHelper.NotFoundResponse(
                    req,
                    "Super admin user not found with this email"
                );
            }

            // Hash the new password
            var passwordHash = PasswordHelper.HashPassword(request.NewPassword);

            // Update the password
            var rowsAffected = await connection.ExecuteAsync(
                @"UPDATE [auth].[Users]
                  SET PasswordHash = @PasswordHash,
                      IsLocked = 0,
                      FailedLoginAttempts = 0,
                      LastFailedLoginUtc = NULL
                  WHERE UserId = @UserId",
                new
                {
                    UserId = (long)superAdmin.UserId,
                    PasswordHash = passwordHash
                }
            );

            if (rowsAffected == 0)
            {
                _logger.LogError($"Failed to update password for user: {request.Email}");
                return await ResponseHelper.ServerErrorResponse(req, "Failed to update password");
            }

            _logger.LogInformation($"Super admin password reset successfully for: {request.Email}");

            var responseData = new
            {
                UserId = (long)superAdmin.UserId,
                Email = (string)superAdmin.Email,
                DisplayName = (string)superAdmin.DisplayName,
                Message = "Password reset successfully. The account has been unlocked and failed login attempts cleared.",
                Warning = "IMPORTANT: Keep the reset secret secure and consider changing it in production!"
            };

            return await ResponseHelper.SuccessResponse(
                req,
                responseData,
                "Super admin password reset successfully"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error resetting super admin password");
            return await ResponseHelper.ServerErrorResponse(req, "Password reset failed", ex.ToString());
        }
    }
}

public class ResetSuperAdminPasswordRequest
{
    public string ResetSecret { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string NewPassword { get; set; } = string.Empty;
}
