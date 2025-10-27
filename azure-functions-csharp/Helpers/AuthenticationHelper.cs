using System.Net;
using Microsoft.Azure.Functions.Worker.Http;
using KamanAzureFunctions.DTOs;

namespace KamanAzureFunctions.Helpers;

public static class AuthenticationHelper
{
    /// <summary>
    /// Authenticate request using JWT
    /// </summary>
    public static (bool Authenticated, JwtPayload? User, string? Error) AuthenticateRequest(
        HttpRequestData req,
        JwtHelper jwtHelper)
    {
        var authHeader = req.Headers.TryGetValues("Authorization", out var values)
            ? values.FirstOrDefault()
            : null;

        var token = JwtHelper.ExtractTokenFromHeader(authHeader);

        if (string.IsNullOrEmpty(token))
        {
            return (false, null, "No authentication token provided");
        }

        var user = jwtHelper.VerifyAccessToken(token);

        if (user == null)
        {
            return (false, null, "Invalid or expired token");
        }

        return (true, user, null);
    }

    /// <summary>
    /// Check if user has required role
    /// </summary>
    public static bool HasRole(JwtPayload user, string requiredRole)
    {
        return user.Roles.Contains(requiredRole);
    }

    /// <summary>
    /// Check if user is super admin
    /// </summary>
    public static bool IsSuperAdmin(JwtPayload user)
    {
        return HasRole(user, "SUPER_ADMIN");
    }

    /// <summary>
    /// Check if user is company admin
    /// </summary>
    public static bool IsCompanyAdmin(JwtPayload user)
    {
        return HasRole(user, "COMPANY_ADMIN");
    }

    /// <summary>
    /// Check if user belongs to a specific company
    /// </summary>
    public static bool BelongsToCompany(JwtPayload user, long companyId)
    {
        return user.CompanyId == companyId;
    }

    /// <summary>
    /// Get client IP address
    /// </summary>
    public static string GetClientIpAddress(HttpRequestData req)
    {
        if (req.Headers.TryGetValues("X-Forwarded-For", out var forwardedFor))
        {
            return forwardedFor.FirstOrDefault() ?? "unknown";
        }

        if (req.Headers.TryGetValues("X-Real-IP", out var realIp))
        {
            return realIp.FirstOrDefault() ?? "unknown";
        }

        return "unknown";
    }

    /// <summary>
    /// Get user agent
    /// </summary>
    public static string GetUserAgent(HttpRequestData req)
    {
        if (req.Headers.TryGetValues("User-Agent", out var userAgent))
        {
            return userAgent.FirstOrDefault() ?? "unknown";
        }

        return "unknown";
    }
}
