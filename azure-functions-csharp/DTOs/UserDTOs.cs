namespace KamanAzureFunctions.DTOs;

public class CreateUserRequest
{
    public long CompanyId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public int? RoleId { get; set; }
}

public class LoginRequest
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class SetPasswordRequest
{
    public long UserId { get; set; }
    public string NewPassword { get; set; } = string.Empty;
}

public class RefreshTokenRequest
{
    public string RefreshToken { get; set; } = string.Empty;
}

public class UserResponse
{
    public long UserId { get; set; }
    public long? CompanyId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? LastLoginAt { get; set; }
}

public class AuthenticationResponse
{
    public string AccessToken { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public string ExpiresIn { get; set; } = string.Empty;
    public string TokenType { get; set; } = "Bearer";
}

public class LoginResponse
{
    public UserResponse User { get; set; } = null!;
    public AuthenticationResponse Authentication { get; set; } = null!;
}

public class CreateUserResponse
{
    public UserResponse User { get; set; } = null!;
    public AuthenticationResponse Authentication { get; set; } = null!;
    public UserCredentials Credentials { get; set; } = null!;
}

public class UserCredentials
{
    public string Email { get; set; } = string.Empty;
    public string DefaultPassword { get; set; } = string.Empty;
    public string Note { get; set; } = "User should change this password on first login";
}

public class SetPasswordResponse
{
    public long UserId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string Message { get; set; } = "Password has been set successfully";
}

public class UserTokenClaims
{
    public long UserId { get; set; }
    public string Email { get; set; } = string.Empty;
    public long? CompanyId { get; set; }
    public List<string> Roles { get; set; } = new();
}
