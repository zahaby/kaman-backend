using BCrypt.Net;

namespace KamanAzureFunctions.Helpers;

public static class PasswordHelper
{
    /// <summary>
    /// Hash a password using BCrypt
    /// </summary>
    public static byte[] HashPassword(string password)
    {
        var hash = BCrypt.Net.BCrypt.HashPassword(password, 12);
        return System.Text.Encoding.UTF8.GetBytes(hash);
    }

    /// <summary>
    /// Verify a password against a hash
    /// </summary>
    public static bool VerifyPassword(string password, byte[] hashBytes)
    {
        try
        {
            var hashString = System.Text.Encoding.UTF8.GetString(hashBytes);
            return BCrypt.Net.BCrypt.Verify(password, hashString);
        }
        catch
        {
            return false;
        }
    }

    /// <summary>
    /// Validate password strength
    /// </summary>
    public static (bool IsValid, string? ErrorMessage) ValidatePasswordStrength(string password)
    {
        if (string.IsNullOrWhiteSpace(password))
            return (false, "Password is required");

        if (password.Length < 8)
            return (false, "Password must be at least 8 characters long");

        if (!password.Any(char.IsUpper))
            return (false, "Password must contain at least one uppercase letter");

        if (!password.Any(char.IsLower))
            return (false, "Password must contain at least one lowercase letter");

        if (!password.Any(char.IsDigit))
            return (false, "Password must contain at least one number");

        if (!password.Any(c => "!@#$%^&*(),.?\":{}|<>".Contains(c)))
            return (false, "Password must contain at least one special character");

        return (true, null);
    }
}
