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

            var response = await _httpClient.GetAsync("/gifts/categories");

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
}
