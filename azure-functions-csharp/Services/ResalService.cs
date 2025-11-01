using System.Net.Http.Headers;
using System.Text.Json;
using KamanAzureFunctions.DTOs;
using Microsoft.Extensions.Logging;

namespace KamanAzureFunctions.Services;

/// <summary>
/// Service for interacting with Resal API
/// </summary>
public class ResalService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<ResalService> _logger;
    private readonly string _bearerToken;

    public ResalService(HttpClient httpClient, ILogger<ResalService> logger, string baseUrl, string bearerToken)
    {
        _httpClient = httpClient;
        _logger = logger;
        _bearerToken = bearerToken;

        _httpClient.BaseAddress = new Uri(baseUrl);
        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", bearerToken);
    }

    /// <summary>
    /// Get all gift categories from Resal API
    /// </summary>
    public async Task<List<GiftCategoryDto>> GetGiftCategoriesAsync()
    {
        try
        {
            _logger.LogInformation("Calling Resal API to get gift categories");

            var response = await _httpClient.GetAsync("gifts/categories");

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError($"Resal API returned error status: {response.StatusCode}");
                throw new HttpRequestException($"Resal API error: {response.StatusCode}");
            }

            var content = await response.Content.ReadAsStringAsync();
            _logger.LogInformation($"Resal API response: {content}");

            var categories = JsonSerializer.Deserialize<List<GiftCategoryDto>>(content, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            return categories ?? new List<GiftCategoryDto>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calling Resal API to get gift categories");
            throw;
        }
    }

    /// <summary>
    /// Get gifts from Resal API with pagination and filters
    /// </summary>
    /// <param name="page">Page number (1-based)</param>
    /// <param name="perPage">Number of items per page</param>
    /// <param name="countries">Country ID filter (optional)</param>
    /// <param name="all">Include all items (optional)</param>
    public async Task<GiftsResponseDto> GetGiftsAsync(int page = 1, int perPage = 10, int? countries = null, bool all = false)
    {
        try
        {
            _logger.LogInformation($"Calling Resal API to get gifts - Page: {page}, PerPage: {perPage}, Countries: {countries}, All: {all}");

            // Build query string
            var queryParams = new List<string>
            {
                $"page={page}",
                $"per_page={perPage}",
                $"all={all.ToString().ToLower()}"
            };

            if (countries.HasValue)
            {
                queryParams.Add($"countries={countries.Value}");
            }

            var queryString = string.Join("&", queryParams);
            var url = $"gifts/?{queryString}";

            _logger.LogInformation($"Calling Resal API URL: {url}");
            _logger.LogInformation($"Full URL: {_httpClient.BaseAddress}{url}");

            var response = await _httpClient.GetAsync(url);

            _logger.LogInformation($"Resal API response status: {response.StatusCode}");
            _logger.LogInformation($"Response headers: {string.Join(", ", response.Headers.Select(h => $"{h.Key}={string.Join(",", h.Value)}"))}");

            if (!response.IsSuccessStatusCode)
            {
                var errorContent = await response.Content.ReadAsStringAsync();
                _logger.LogError($"Resal API returned error status: {response.StatusCode}, Content: {errorContent}");
                throw new HttpRequestException($"Resal API error: {response.StatusCode}");
            }

            var content = await response.Content.ReadAsStringAsync();
            _logger.LogInformation($"Resal API gifts response received (length: {content.Length})");

            var giftsResponse = JsonSerializer.Deserialize<GiftsResponseDto>(content, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            return giftsResponse ?? new GiftsResponseDto();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calling Resal API to get gifts");
            throw;
        }
    }
}
