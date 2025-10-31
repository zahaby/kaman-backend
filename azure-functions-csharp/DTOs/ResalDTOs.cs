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
