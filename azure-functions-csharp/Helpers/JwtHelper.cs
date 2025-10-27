using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using KamanAzureFunctions.DTOs;

namespace KamanAzureFunctions.Helpers;

public class JwtHelper
{
    private readonly string _secret;
    private readonly string _refreshSecret;
    private readonly int _expiresInMinutes;
    private readonly int _refreshExpiresInDays;

    public JwtHelper(string secret, string refreshSecret, int expiresInMinutes, int refreshExpiresInDays)
    {
        _secret = secret;
        _refreshSecret = refreshSecret;
        _expiresInMinutes = expiresInMinutes;
        _refreshExpiresInDays = refreshExpiresInDays;
    }

    /// <summary>
    /// Generate access and refresh tokens
    /// </summary>
    public AuthenticationResponse GenerateTokens(JwtPayload payload)
    {
        var accessToken = GenerateAccessToken(payload);
        var refreshToken = GenerateRefreshToken(payload.UserId, payload.Email);

        return new AuthenticationResponse
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            ExpiresIn = $"{_expiresInMinutes}m",
            TokenType = "Bearer"
        };
    }

    /// <summary>
    /// Generate access token
    /// </summary>
    private string GenerateAccessToken(JwtPayload payload)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_secret));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new Claim("userId", payload.UserId.ToString()),
            new Claim("email", payload.Email),
            new Claim(JwtRegisteredClaimNames.Sub, payload.Email),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        if (payload.CompanyId.HasValue)
        {
            claims.Add(new Claim("companyId", payload.CompanyId.Value.ToString()));
        }

        foreach (var role in payload.Roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
        }

        var token = new JwtSecurityToken(
            issuer: "KamanGiftCards",
            audience: "KamanFlutterApp",
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(_expiresInMinutes),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    /// <summary>
    /// Generate refresh token
    /// </summary>
    private string GenerateRefreshToken(long userId, string email)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_refreshSecret));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new Claim("userId", userId.ToString()),
            new Claim("email", email),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var token = new JwtSecurityToken(
            issuer: "KamanGiftCards",
            audience: "KamanFlutterApp",
            claims: claims,
            expires: DateTime.UtcNow.AddDays(_refreshExpiresInDays),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    /// <summary>
    /// Verify access token
    /// </summary>
    public JwtPayload? VerifyAccessToken(string token)
    {
        try
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(_secret);

            tokenHandler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuer = true,
                ValidIssuer = "KamanGiftCards",
                ValidateAudience = true,
                ValidAudience = "KamanFlutterApp",
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            }, out SecurityToken validatedToken);

            var jwtToken = (JwtSecurityToken)validatedToken;

            var userId = long.Parse(jwtToken.Claims.First(x => x.Type == "userId").Value);
            var email = jwtToken.Claims.First(x => x.Type == "email").Value;
            var companyIdClaim = jwtToken.Claims.FirstOrDefault(x => x.Type == "companyId");
            var roles = jwtToken.Claims.Where(x => x.Type == ClaimTypes.Role).Select(x => x.Value).ToList();

            return new JwtPayload
            {
                UserId = userId,
                Email = email,
                CompanyId = companyIdClaim != null ? long.Parse(companyIdClaim.Value) : null,
                Roles = roles
            };
        }
        catch
        {
            return null;
        }
    }

    /// <summary>
    /// Verify refresh token
    /// </summary>
    public (long UserId, string Email)? VerifyRefreshToken(string token)
    {
        try
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(_refreshSecret);

            tokenHandler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuer = true,
                ValidIssuer = "KamanGiftCards",
                ValidateAudience = true,
                ValidAudience = "KamanFlutterApp",
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            }, out SecurityToken validatedToken);

            var jwtToken = (JwtSecurityToken)validatedToken;

            var userId = long.Parse(jwtToken.Claims.First(x => x.Type == "userId").Value);
            var email = jwtToken.Claims.First(x => x.Type == "email").Value;

            return (userId, email);
        }
        catch
        {
            return null;
        }
    }

    /// <summary>
    /// Extract token from Authorization header
    /// </summary>
    public static string? ExtractTokenFromHeader(string? authHeader)
    {
        if (string.IsNullOrWhiteSpace(authHeader))
            return null;

        var parts = authHeader.Split(' ');
        if (parts.Length != 2 || parts[0] != "Bearer")
            return null;

        return parts[1];
    }
}
