namespace KamanAzureFunctions.Models;

public class Wallet
{
    public long WalletId { get; set; }
    public long CompanyId { get; set; }
    public string Currency { get; set; } = string.Empty;
    public DateTime CreatedAtUtc { get; set; }
}
