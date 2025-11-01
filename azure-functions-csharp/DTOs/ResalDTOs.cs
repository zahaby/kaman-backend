using System.Text.Json.Serialization;

namespace KamanAzureFunctions.DTOs;

/// <summary>
/// Gift category from Resal API
/// </summary>
public class GiftCategoryDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("name_en")]
    public string NameEn { get; set; } = string.Empty;

    [JsonPropertyName("name_ar")]
    public string NameAr { get; set; } = string.Empty;
}

/// <summary>
/// Gift item from Resal API
/// </summary>
public class GiftDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("name_en")]
    public string NameEn { get; set; } = string.Empty;

    [JsonPropertyName("name_ar")]
    public string NameAr { get; set; } = string.Empty;

    [JsonPropertyName("description_en")]
    public string? DescriptionEn { get; set; }

    [JsonPropertyName("description_ar")]
    public string? DescriptionAr { get; set; }

    [JsonPropertyName("price")]
    public decimal Price { get; set; }

    [JsonPropertyName("currency")]
    public string? Currency { get; set; }

    [JsonPropertyName("image")]
    public string? Image { get; set; }

    [JsonPropertyName("category_id")]
    public int? CategoryId { get; set; }

    [JsonPropertyName("category_name_en")]
    public string? CategoryNameEn { get; set; }

    [JsonPropertyName("category_name_ar")]
    public string? CategoryNameAr { get; set; }

    [JsonPropertyName("country_id")]
    public int? CountryId { get; set; }

    [JsonPropertyName("is_active")]
    public bool? IsActive { get; set; }
}

/// <summary>
/// Pagination metadata from Resal API
/// </summary>
public class ResalPaginationDto
{
    [JsonPropertyName("current_page")]
    public int CurrentPage { get; set; }

    [JsonPropertyName("per_page")]
    public int PerPage { get; set; }

    [JsonPropertyName("total")]
    public int Total { get; set; }

    [JsonPropertyName("last_page")]
    public int LastPage { get; set; }

    [JsonPropertyName("from")]
    public int? From { get; set; }

    [JsonPropertyName("to")]
    public int? To { get; set; }
}

/// <summary>
/// Gifts list response from Resal API
/// </summary>
public class GiftsResponseDto
{
    [JsonPropertyName("data")]
    public List<GiftDto> Data { get; set; } = new();

    [JsonPropertyName("current_page")]
    public int? CurrentPage { get; set; }

    [JsonPropertyName("per_page")]
    public int? PerPage { get; set; }

    [JsonPropertyName("total")]
    public int? Total { get; set; }

    [JsonPropertyName("last_page")]
    public int? LastPage { get; set; }

    [JsonPropertyName("from")]
    public int? From { get; set; }

    [JsonPropertyName("to")]
    public int? To { get; set; }
}

