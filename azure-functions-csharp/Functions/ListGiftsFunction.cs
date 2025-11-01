using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using KamanAzureFunctions.Helpers;
using KamanAzureFunctions.Services;

namespace KamanAzureFunctions.Functions;

/// <summary>
/// Function to list gifts from Resal API with pagination and filters
/// This is a wrapper endpoint that calls Resal API and returns the gifts
/// </summary>
public class ListGiftsFunction
{
    private readonly ILogger<ListGiftsFunction> _logger;
    private readonly ResalService _resalService;
    private readonly JwtHelper _jwtHelper;

    public ListGiftsFunction(
        ILogger<ListGiftsFunction> logger,
        ResalService resalService,
        JwtHelper jwtHelper)
    {
        _logger = logger;
        _resalService = resalService;
        _jwtHelper = jwtHelper;
    }

    [Function("ListGifts")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "gifts")] HttpRequestData req)
    {
        _logger.LogInformation("ListGifts function processing request");

        try
        {
            // Authenticate request - any authenticated user can access this
            var authResult = AuthenticationHelper.AuthenticateRequest(req, _jwtHelper);
            if (!authResult.Authenticated || authResult.User == null)
            {
                return await ResponseHelper.UnauthorizedResponse(req, authResult.Error ?? "Unauthorized");
            }

            // Parse query parameters
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);

            // Get page number (default: 1)
            var pageStr = query["page"] ?? "1";
            if (!int.TryParse(pageStr, out int page) || page < 1)
            {
                page = 1;
            }

            // Get per_page (default: 10)
            var perPageStr = query["per_page"] ?? "10";
            if (!int.TryParse(perPageStr, out int perPage) || perPage < 1 || perPage > 100)
            {
                perPage = 10;
            }

            // Get countries filter (optional)
            int? countries = null;
            var countriesStr = query["countries"];
            if (!string.IsNullOrEmpty(countriesStr) && int.TryParse(countriesStr, out int countriesValue))
            {
                countries = countriesValue;
            }

            // Get all parameter (default: false)
            var allStr = query["all"] ?? "false";
            bool all = allStr.ToLower() == "true";

            _logger.LogInformation($"Fetching gifts - Page: {page}, PerPage: {perPage}, Countries: {countries}, All: {all}");

            // Call Resal API to get gifts (returns raw JSON)
            var giftsJson = await _resalService.GetGiftsAsync(page, perPage, countries, all);

            _logger.LogInformation($"Retrieved gifts response from Resal API");

            // Return the exact raw JSON response from Resal API
            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json; charset=utf-8");
            await response.WriteStringAsync(giftsJson);

            return response;
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Error calling Resal API");
            return await ResponseHelper.ServerErrorResponse(req, "Failed to retrieve gifts from Resal API", ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving gifts");
            return await ResponseHelper.ServerErrorResponse(req, "Failed to retrieve gifts", ex.ToString());
        }
    }
}
