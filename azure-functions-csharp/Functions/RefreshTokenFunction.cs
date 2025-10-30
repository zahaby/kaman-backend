using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using KamanAzureFunctions.DTOs;
using KamanAzureFunctions.Helpers;
using KamanAzureFunctions.Services;

namespace KamanAzureFunctions.Functions;

public class RefreshTokenFunction
{
    private readonly ILogger<RefreshTokenFunction> _logger;
    private readonly UserService _userService;
    private readonly JwtHelper _jwtHelper;

    public RefreshTokenFunction(
        ILogger<RefreshTokenFunction> logger,
        UserService userService,
        JwtHelper jwtHelper)
    {
        _logger = logger;
        _userService = userService;
        _jwtHelper = jwtHelper;
    }

    [Function("RefreshToken")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "auth/refresh")] HttpRequestData req)
    {
        _logger.LogInformation("RefreshToken function processing request");

        try
        {
            // Parse request body
            var request = await req.ReadFromJsonAsync<RefreshTokenRequest>();
            if (request == null)
            {
                return await ResponseHelper.ErrorResponse(req, "Invalid request body");
            }

            // Validate request
            var validator = new RefreshTokenRequestValidator();
            var validationResult = await validator.ValidateAsync(request);

            if (!validationResult.IsValid)
            {
                var errors = string.Join(", ", validationResult.Errors.Select(e => e.ErrorMessage));
                return await ResponseHelper.ErrorResponse(req, $"Validation error: {errors}");
            }

            // Verify refresh token
            var tokenPayload = _jwtHelper.VerifyRefreshToken(request.RefreshToken);

            if (tokenPayload == null)
            {
                return await ResponseHelper.ErrorResponse(req, "Invalid or expired refresh token", HttpStatusCode.Unauthorized);
            }

            // Get user with roles
            var (user, roles) = await _userService.GetUserWithRolesAsync(tokenPayload.Value.UserId);

            // Check if user is still active
            if (!user.IsActive)
            {
                return await ResponseHelper.ForbiddenResponse(req, "User account is inactive");
            }

            if (user.IsLocked)
            {
                return await ResponseHelper.ForbiddenResponse(req, "User account is locked");
            }

            // Generate new tokens
            var jwtPayload = new UserTokenClaims
            {
                UserId = user.UserId,
                Email = user.Email,
                CompanyId = user.CompanyId,
                Roles = roles
            };

            var tokens = _jwtHelper.GenerateTokens(jwtPayload);

            _logger.LogInformation($"Token refreshed successfully for user: {user.Email}");

            var responseData = new { Authentication = tokens };

            return await ResponseHelper.SuccessResponse(req, responseData, "Token refreshed successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error refreshing token");
            return await ResponseHelper.ServerErrorResponse(req, "Failed to refresh token", ex.ToString());
        }
    }
}
