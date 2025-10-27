namespace KamanAzureFunctions.Models;

public class User
{
    public long UserId { get; set; }
    public long? CompanyId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public byte[] PasswordHash { get; set; } = Array.Empty<byte>();
    public byte[]? PasswordSalt { get; set; }
    public bool IsActive { get; set; }
    public bool IsLocked { get; set; }
    public int FailedLoginAttempts { get; set; }
    public DateTime? LastFailedLoginUtc { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? LastLoginUtc { get; set; }
    public DateTime? DeletedAtUtc { get; set; }
}
