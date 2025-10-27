using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using KamanAzureFunctions.DTOs;
using KamanAzureFunctions.Helpers;
using KamanAzureFunctions.Services;

namespace KamanAzureFunctions.Functions;

public class LoginFunction
{
    private readonly ILogger<LoginFunction> _logger;
    private readonly UserService _userService;

    public LoginFunction(
        ILogger<LoginFunction> logger,
        UserService userService)
    {
        _logger = logger;
        _userService = userService;
    }

    [Function("Login")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "auth/login")] HttpRequestData req)
    {
        _logger.LogInformation("Login function processing request");

        try
        {
            // Parse request body
            var request = await req.ReadFromJsonAsync<LoginRequest>();
            if (request == null)
            {
                return await ResponseHelper.ErrorResponse(req, "Invalid request body");
            }

            // Validate request
            var validator = new LoginRequestValidator();
            var validationResult = await validator.ValidateAsync(request);

            if (!validationResult.IsValid)
            {
                var errors = string.Join(", ", validationResult.Errors.Select(e => e.ErrorMessage));
                return await ResponseHelper.ErrorResponse(req, $"Validation error: {errors}");
            }

            // Get client info for logging
            var ipAddress = AuthenticationHelper.GetClientIpAddress(req);
            var userAgent = AuthenticationHelper.GetUserAgent(req);

            // Attempt login
            var result = await _userService.LoginAsync(request.Email, request.Password, ipAddress, userAgent);

            _logger.LogInformation($"User logged in successfully: {result.User.Email}");

            var responseData = new LoginResponse
            {
                User = new UserResponse
                {
                    UserId = result.User.UserId,
                    CompanyId = result.User.CompanyId,
                    Email = result.User.Email,
                    DisplayName = result.User.DisplayName,
                    IsActive = result.User.IsActive,
                    CreatedAt = result.User.CreatedAtUtc,
                    LastLoginAt = result.User.LastLoginUtc
                },
                Authentication = result.Tokens
            };

            return await ResponseHelper.SuccessResponse(req, responseData, "Login successful");
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Login failed");
            return await ResponseHelper.ErrorResponse(req, ex.Message, HttpStatusCode.Unauthorized);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during login");
            return await ResponseHelper.ServerErrorResponse(req, "Login failed", ex.ToString());
        }
    }
}
