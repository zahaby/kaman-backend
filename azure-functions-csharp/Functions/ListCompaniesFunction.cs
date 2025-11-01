using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using KamanAzureFunctions.DTOs;
using KamanAzureFunctions.Helpers;
using KamanAzureFunctions.Services;

namespace KamanAzureFunctions.Functions;

/// <summary>
/// Function to list all companies (Super Admin only)
/// </summary>
public class ListCompaniesFunction
{
    private readonly ILogger<ListCompaniesFunction> _logger;
    private readonly CompanyService _companyService;
    private readonly JwtHelper _jwtHelper;

    public ListCompaniesFunction(
        ILogger<ListCompaniesFunction> logger,
        CompanyService companyService,
        JwtHelper jwtHelper)
    {
        _logger = logger;
        _companyService = companyService;
        _jwtHelper = jwtHelper;
    }

    [Function("ListCompanies")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "company/list")] HttpRequestData req)
    {
        _logger.LogInformation("ListCompanies function processing request");

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
                return await ResponseHelper.ForbiddenResponse(req, "Only super admins can list all companies");
            }

            // Parse query parameters
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var includeInactive = query["includeInactive"]?.ToLower() == "true";

            // Get all companies
            var companies = await _companyService.GetAllCompaniesAsync(includeInactive);

            var companiesList = companies.Select(c => new CompanyResponse
            {
                CompanyId = c.CompanyId,
                CompanyCode = c.CompanyCode,
                Name = c.Name,
                Email = c.Email,
                Phone = c.Phone,
                Country = c.Country,
                Address = c.Address,
                DefaultCurrency = c.DefaultCurrency,
                MinimumBalance = c.MinimumBalance,
                IsActive = c.IsActive,
                CreatedAt = c.CreatedAtUtc
            }).ToList();

            _logger.LogInformation($"Retrieved {companiesList.Count} companies");

            var responseData = new
            {
                TotalCount = companiesList.Count,
                Companies = companiesList
            };

            return await ResponseHelper.SuccessResponse(
                req,
                responseData,
                $"Retrieved {companiesList.Count} companies successfully"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error listing companies");
            return await ResponseHelper.ServerErrorResponse(req, "Failed to retrieve companies", ex.ToString());
        }
    }
}
