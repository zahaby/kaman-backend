namespace KamanAzureFunctions.DTOs;

public class CreateCompanyRequest
{
    public string CompanyCode { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Country { get; set; }
    public string? Address { get; set; }
    public string DefaultCurrency { get; set; } = "EGP";
    public decimal MinimumBalance { get; set; } = 0;
}

public class CompanyResponse
{
    public long CompanyId { get; set; }
    public string CompanyCode { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? Country { get; set; }
    public string? Address { get; set; }
    public string DefaultCurrency { get; set; } = string.Empty;
    public decimal MinimumBalance { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class WalletResponse
{
    public long WalletId { get; set; }
    public long CompanyId { get; set; }
    public string Currency { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class CreateCompanyResponse
{
    public CompanyResponse Company { get; set; } = null!;
    public WalletResponse Wallet { get; set; } = null!;
}
