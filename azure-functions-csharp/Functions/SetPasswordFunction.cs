using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using KamanAzureFunctions.DTOs;
using KamanAzureFunctions.Helpers;
using KamanAzureFunctions.Services;

namespace KamanAzureFunctions.Functions;

public class SetPasswordFunction
{
    private readonly ILogger<SetPasswordFunction> _logger;
    private readonly UserService _userService;
    private readonly JwtHelper _jwtHelper;

    public SetPasswordFunction(
        ILogger<SetPasswordFunction> logger,
        UserService userService,
        JwtHelper jwtHelper)
    {
        _logger = logger;
        _userService = userService;
        _jwtHelper = jwtHelper;
    }

    [Function("SetPassword")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "user/set-password")] HttpRequestData req)
    {
        _logger.LogInformation("SetPassword function processing request");

        try
        {
            // Authenticate request
            var authResult = AuthenticationHelper.AuthenticateRequest(req, _jwtHelper);
            if (!authResult.Authenticated || authResult.User == null)
            {
                return await ResponseHelper.UnauthorizedResponse(req, authResult.Error ?? "Unauthorized");
            }

            // Parse request body
            var request = await req.ReadFromJsonAsync<SetPasswordRequest>();
            if (request == null)
            {
                return await ResponseHelper.ErrorResponse(req, "Invalid request body");
            }

            // Validate request
            var validator = new SetPasswordRequestValidator();
            var validationResult = await validator.ValidateAsync(request);

            if (!validationResult.IsValid)
            {
                var errors = string.Join(", ", validationResult.Errors.Select(e => e.ErrorMessage));
                return await ResponseHelper.ErrorResponse(req, $"Validation error: {errors}");
            }

            // Validate password strength
            var passwordValidation = PasswordHelper.ValidatePasswordStrength(request.NewPassword);
            if (!passwordValidation.IsValid)
            {
                return await ResponseHelper.ErrorResponse(req, $"Password validation failed: {passwordValidation.ErrorMessage}");
            }

            // Get the user whose password is being changed
            var targetUser = await _userService.GetUserByIdAsync(request.UserId);

            if (targetUser == null)
            {
                return await ResponseHelper.NotFoundResponse(req, "User not found");
            }

            // Authorization check
            var isSuperAdminUser = AuthenticationHelper.IsSuperAdmin(authResult.User);
            var isSelfReset = authResult.User.UserId == request.UserId;
            var isSameCompanyUser = targetUser.CompanyId.HasValue &&
                                   AuthenticationHelper.BelongsToCompany(authResult.User, targetUser.CompanyId.Value);

            // Super admins can reset any password
            // Users can reset their own password
            // Company admins can reset passwords for users in their company
            if (!isSuperAdminUser && !isSelfReset && !isSameCompanyUser)
            {
                return await ResponseHelper.ForbiddenResponse(req, "You do not have permission to reset this user's password");
            }

            // Set password
            await _userService.SetPasswordAsync(request.UserId, request.NewPassword);

            _logger.LogInformation($"Password set successfully for user: {targetUser.Email}");

            var responseData = new SetPasswordResponse
            {
                UserId = targetUser.UserId,
                Email = targetUser.Email
            };

            return await ResponseHelper.SuccessResponse(req, responseData, "Password updated successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error setting password");
            return await ResponseHelper.ServerErrorResponse(req, ex.Message, ex.ToString());
        }
    }
}
