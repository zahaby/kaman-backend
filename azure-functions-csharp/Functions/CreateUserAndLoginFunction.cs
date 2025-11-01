using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using KamanAzureFunctions.DTOs;
using KamanAzureFunctions.Helpers;
using KamanAzureFunctions.Services;

namespace KamanAzureFunctions.Functions;

public class CreateUserAndLoginFunction
{
    private readonly ILogger<CreateUserAndLoginFunction> _logger;
    private readonly UserService _userService;
    private readonly CompanyService _companyService;
    private readonly JwtHelper _jwtHelper;

    public CreateUserAndLoginFunction(
        ILogger<CreateUserAndLoginFunction> logger,
        UserService userService,
        CompanyService companyService,
        JwtHelper jwtHelper)
    {
        _logger = logger;
        _userService = userService;
        _companyService = companyService;
        _jwtHelper = jwtHelper;
    }

    [Function("CreateUserAndLogin")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "user/create")] HttpRequestData req)
    {
        _logger.LogInformation("CreateUserAndLogin function processing request");

        try
        {
            // Authenticate request
            var authResult = AuthenticationHelper.AuthenticateRequest(req, _jwtHelper);
            if (!authResult.Authenticated || authResult.User == null)
            {
                return await ResponseHelper.UnauthorizedResponse(req, authResult.Error ?? "Unauthorized");
            }

            // Parse request body
            var request = await req.ReadFromJsonAsync<CreateUserRequest>();
            if (request == null)
            {
                return await ResponseHelper.ErrorResponse(req, "Invalid request body");
            }

            // Validate request
            var validator = new CreateUserRequestValidator();
            var validationResult = await validator.ValidateAsync(request);

            if (!validationResult.IsValid)
            {
                var errors = string.Join(", ", validationResult.Errors.Select(e => e.ErrorMessage));
                return await ResponseHelper.ErrorResponse(req, $"Validation error: {errors}");
            }

            // Authorization check
            var isSuperAdminUser = AuthenticationHelper.IsSuperAdmin(authResult.User);
            var isCompanyAdminUser = AuthenticationHelper.IsCompanyAdmin(authResult.User);

            if (!isSuperAdminUser && !isCompanyAdminUser)
            {
                return await ResponseHelper.ForbiddenResponse(req, "Insufficient permissions");
            }

            // Company admins can only create users for their own company
            if (isCompanyAdminUser && !isSuperAdminUser)
            {
                if (!AuthenticationHelper.BelongsToCompany(authResult.User, request.CompanyId))
                {
                    return await ResponseHelper.ForbiddenResponse(req, "You can only create users for your own company");
                }
            }

            // Verify company exists and is active
            var company = await _companyService.GetCompanyByIdAsync(request.CompanyId);
            if (company == null)
            {
                return await ResponseHelper.NotFoundResponse(req, "Company not found");
            }

            if (!company.IsActive)
            {
                return await ResponseHelper.ErrorResponse(req, "Company is not active");
            }

            // Create user
            var result = await _userService.CreateUserWithDefaultPasswordAsync(request);

            _logger.LogInformation($"User created successfully: {result.User.Email}");

            var responseData = new CreateUserResponse
            {
                User = new UserResponse
                {
                    UserId = result.User.UserId,
                    CompanyId = result.User.CompanyId,
                    Email = result.User.Email,
                    DisplayName = result.User.DisplayName,
                    IsActive = result.User.IsActive,
                    CreatedAt = result.User.CreatedAtUtc
                },
                Authentication = result.Tokens,
                Credentials = new UserCredentials
                {
                    Email = result.User.Email,
                    DefaultPassword = result.DefaultPassword
                }
            };

            return await ResponseHelper.SuccessResponse(
                req,
                responseData,
                "User created successfully with default password",
                HttpStatusCode.Created
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating user");
            return await ResponseHelper.ServerErrorResponse(req, ex.Message, ex.ToString());
        }
    }
}
