using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using KamanAzureFunctions.DTOs;
using KamanAzureFunctions.Helpers;
using KamanAzureFunctions.Services;

namespace KamanAzureFunctions.Functions;

public class CreateCompanyFunction
{
    private readonly ILogger<CreateCompanyFunction> _logger;
    private readonly CompanyService _companyService;
    private readonly JwtHelper _jwtHelper;

    public CreateCompanyFunction(
        ILogger<CreateCompanyFunction> logger,
        CompanyService companyService,
        JwtHelper jwtHelper)
    {
        _logger = logger;
        _companyService = companyService;
        _jwtHelper = jwtHelper;
    }

    [Function("CreateCompany")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "company/create")] HttpRequestData req)
    {
        _logger.LogInformation("CreateCompany function processing request");

        try
        {
            // Authenticate request
            var authResult = AuthenticationHelper.AuthenticateRequest(req, _jwtHelper);
            if (!authResult.Authenticated || authResult.User == null)
            {
                return await ResponseHelper.UnauthorizedResponse(req, authResult.Error ?? "Unauthorized");
            }

            // Check if user is super admin
            if (!AuthenticationHelper.IsSuperAdmin(authResult.User))
            {
                return await ResponseHelper.ForbiddenResponse(req, "Only super admins can create companies");
            }

            // Parse request body
            var request = await req.ReadFromJsonAsync<CreateCompanyRequest>();
            if (request == null)
            {
                return await ResponseHelper.ErrorResponse(req, "Invalid request body");
            }

            // Validate request
            var validator = new CreateCompanyRequestValidator();
            var validationResult = await validator.ValidateAsync(request);

            if (!validationResult.IsValid)
            {
                var errors = string.Join(", ", validationResult.Errors.Select(e => e.ErrorMessage));
                return await ResponseHelper.ErrorResponse(req, $"Validation error: {errors}");
            }

            // Create company
            var result = await _companyService.CreateCompanyWithWalletAsync(request);

            _logger.LogInformation($"Company created successfully: {result.Company.CompanyCode}");

            var responseData = new CreateCompanyResponse
            {
                Company = new CompanyResponse
                {
                    CompanyId = result.Company.CompanyId,
                    CompanyCode = result.Company.CompanyCode,
                    Name = result.Company.Name,
                    Email = result.Company.Email,
                    Phone = result.Company.Phone,
                    Country = result.Company.Country,
                    Address = result.Company.Address,
                    DefaultCurrency = result.Company.DefaultCurrency,
                    MinimumBalance = result.Company.MinimumBalance,
                    IsActive = result.Company.IsActive,
                    CreatedAt = result.Company.CreatedAtUtc
                },
                Wallet = new WalletResponse
                {
                    WalletId = result.Wallet.WalletId,
                    CompanyId = result.Wallet.CompanyId,
                    Currency = result.Wallet.Currency,
                    CreatedAt = result.Wallet.CreatedAtUtc
                }
            };

            return await ResponseHelper.SuccessResponse(
                req,
                responseData,
                "Company and wallet created successfully",
                HttpStatusCode.Created
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating company");
            return await ResponseHelper.ServerErrorResponse(req, ex.Message, ex.ToString());
        }
    }
}
