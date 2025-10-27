namespace KamanAzureFunctions.Models;

public class Company
{
    public long CompanyId { get; set; }
    public string CompanyCode { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? Country { get; set; }
    public string? Address { get; set; }
    public string DefaultCurrency { get; set; } = "EGP";
    public decimal MinimumBalance { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }
    public DateTime? DeletedAtUtc { get; set; }
}
