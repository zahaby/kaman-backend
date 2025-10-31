using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using KamanAzureFunctions.Helpers;
using KamanAzureFunctions.Services;

namespace KamanAzureFunctions.Functions;

/// <summary>
/// Function to list gift categories from Resal API
/// This is a wrapper endpoint that calls Resal API and returns the categories
/// </summary>
public class ListGiftCategoriesFunction
{
    private readonly ILogger<ListGiftCategoriesFunction> _logger;
    private readonly ResalService _resalService;
    private readonly JwtHelper _jwtHelper;

    public ListGiftCategoriesFunction(
        ILogger<ListGiftCategoriesFunction> logger,
        ResalService resalService,
        JwtHelper jwtHelper)
    {
        _logger = logger;
        _resalService = resalService;
        _jwtHelper = jwtHelper;
    }

    [Function("ListGiftCategories")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "gifts/categories")] HttpRequestData req)
    {
        _logger.LogInformation("ListGiftCategories function processing request");

        try
        {
            // Authenticate request - any authenticated user can access this
            var authResult = AuthenticationHelper.AuthenticateRequest(req, _jwtHelper);
            if (!authResult.Authenticated || authResult.User == null)
            {
                return await ResponseHelper.UnauthorizedResponse(req, authResult.Error ?? "Unauthorized");
            }

            // Call Resal API to get gift categories
            var categories = await _resalService.GetGiftCategoriesAsync();

            _logger.LogInformation($"Retrieved {categories.Count} gift categories from Resal API");

            // Return the exact response from Resal API
            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(categories);

            return response;
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Error calling Resal API");
            return await ResponseHelper.ServerErrorResponse(req, "Failed to retrieve gift categories from Resal API", ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving gift categories");
            return await ResponseHelper.ServerErrorResponse(req, "Failed to retrieve gift categories", ex.ToString());
        }
    }
}
