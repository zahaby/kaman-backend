using Dapper;
using KamanAzureFunctions.DTOs;
using KamanAzureFunctions.Helpers;
using KamanAzureFunctions.Models;
using System.Data;

namespace KamanAzureFunctions.Services;

public class UserService
{
    private readonly DatabaseHelper _dbHelper;
    private readonly JwtHelper _jwtHelper;
    private readonly string _defaultPassword;

    public UserService(DatabaseHelper dbHelper, JwtHelper jwtHelper, string defaultPassword)
    {
        _dbHelper = dbHelper;
        _jwtHelper = jwtHelper;
        _defaultPassword = defaultPassword;
    }

    /// <summary>
    /// Create a new user with default password
    /// </summary>
    public async Task<(User User, AuthenticationResponse Tokens, string DefaultPassword)> CreateUserWithDefaultPasswordAsync(CreateUserRequest request)
    {
        using var connection = _dbHelper.GetConnection();
        await connection.OpenAsync();

        using var transaction = connection.BeginTransaction();

        try
        {
            // Check if email already exists
            var existingUser = await connection.QueryFirstOrDefaultAsync<User>(
                "[auth].[sp_CheckUserEmailExists]",
                new { Email = request.Email },
                transaction,
                commandType: CommandType.StoredProcedure
            );

            if (existingUser != null)
            {
                throw new InvalidOperationException("User with this email already exists");
            }

            // Verify company exists and is active
            var company = await connection.QueryFirstOrDefaultAsync<Company>(
                "[core].[sp_GetCompanyById]",
                new { CompanyId = request.CompanyId },
                transaction,
                commandType: CommandType.StoredProcedure
            );

            if (company == null)
            {
                throw new InvalidOperationException("Company not found");
            }

            if (!company.IsActive)
            {
                throw new InvalidOperationException("Company is not active");
            }

            // Hash default password
            var passwordHash = PasswordHelper.HashPassword(_defaultPassword);

            // Insert user
            var userIdResult = await connection.QuerySingleAsync<dynamic>(
                "[auth].[sp_InsertUser]",
                new
                {
                    CompanyId = request.CompanyId,
                    Email = request.Email,
                    DisplayName = request.DisplayName,
                    PasswordHash = passwordHash,
                    IsActive = true
                },
                transaction,
                commandType: CommandType.StoredProcedure
            );

            long userId = userIdResult.UserId;

            // Retrieve the inserted user
            var user = await connection.QuerySingleAsync<User>(
                "[auth].[sp_GetUserById]",
                new { UserId = userId },
                transaction,
                commandType: CommandType.StoredProcedure
            );

            // Assign role (default to COMPANY_ADMIN if not specified)
            var roleId = request.RoleId ?? 2; // 2 = COMPANY_ADMIN
            await connection.ExecuteAsync(
                "[auth].[sp_AssignRoleToUser]",
                new { UserId = userId, RoleId = roleId },
                transaction,
                commandType: CommandType.StoredProcedure
            );

            // Get user roles
            var roles = await connection.QueryAsync<string>(
                "[auth].[sp_GetUserRoles]",
                new { UserId = userId },
                transaction,
                commandType: CommandType.StoredProcedure
            );

            transaction.Commit();

            // Generate tokens
            var jwtPayload = new UserTokenClaims
            {
                UserId = user.UserId,
                Email = user.Email,
                CompanyId = user.CompanyId,
                Roles = roles.ToList()
            };

            var tokens = _jwtHelper.GenerateTokens(jwtPayload);

            return (user, tokens, _defaultPassword);
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    /// <summary>
    /// Login user
    /// </summary>
    public async Task<(User User, AuthenticationResponse Tokens)> LoginAsync(string email, string password, string? ipAddress = null, string? userAgent = null)
    {
        using var connection = _dbHelper.GetConnection();

        // Get user for login
        var user = await connection.QueryFirstOrDefaultAsync<User>(
            "[auth].[sp_GetUserByEmailForLogin]",
            new { Email = email },
            commandType: CommandType.StoredProcedure
        );

        if (user == null)
        {
            await LogLoginAttemptAsync(email, null, false, "User not found", ipAddress, userAgent);
            throw new UnauthorizedAccessException("Invalid email or password");
        }

        // Get user roles
        var roles = (await connection.QueryAsync<string>(
            "[auth].[sp_GetUserRoles]",
            new { UserId = user.UserId },
            commandType: CommandType.StoredProcedure
        )).ToList();

        // Check if user is active
        if (!user.IsActive)
        {
            await LogLoginAttemptAsync(email, user.UserId, false, "User is inactive", ipAddress, userAgent);
            throw new UnauthorizedAccessException("User account is inactive");
        }

        // Check if user is locked
        if (user.IsLocked)
        {
            await LogLoginAttemptAsync(email, user.UserId, false, "User is locked", ipAddress, userAgent);
            throw new UnauthorizedAccessException("User account is locked due to too many failed login attempts");
        }

        // Verify password
        var isValidPassword = PasswordHelper.VerifyPassword(password, user.PasswordHash);

        if (!isValidPassword)
        {
            await IncrementFailedLoginAttemptsAsync(user.UserId);
            await LogLoginAttemptAsync(email, user.UserId, false, "Invalid password", ipAddress, userAgent);
            throw new UnauthorizedAccessException("Invalid email or password");
        }

        // Update last login and reset failed attempts
        await connection.ExecuteAsync(
            "[auth].[sp_UpdateLastLogin]",
            new { UserId = user.UserId, IpAddress = ipAddress, UserAgent = userAgent },
            commandType: CommandType.StoredProcedure
        );

        // Log successful login
        await LogLoginAttemptAsync(email, user.UserId, true, null, ipAddress, userAgent);

        // Generate tokens
        var jwtPayload = new UserTokenClaims
        {
            UserId = user.UserId,
            Email = user.Email,
            CompanyId = user.CompanyId,
            Roles = roles
        };

        var tokens = _jwtHelper.GenerateTokens(jwtPayload);

        return (user, tokens);
    }

    /// <summary>
    /// Set/Reset user password
    /// </summary>
    public async Task SetPasswordAsync(long userId, string newPassword)
    {
        using var connection = _dbHelper.GetConnection();

        // Get user to validate
        var user = await connection.QueryFirstOrDefaultAsync<User>(
            "[auth].[sp_GetUserById]",
            new { UserId = userId },
            commandType: CommandType.StoredProcedure
        );

        if (user == null)
        {
            throw new InvalidOperationException("User not found");
        }

        if (!user.IsActive)
        {
            throw new InvalidOperationException("User is not active");
        }

        // Hash new password
        var passwordHash = PasswordHelper.HashPassword(newPassword);

        // Update password and unlock/reset failed attempts
        await connection.ExecuteAsync(
            "[auth].[sp_ResetPasswordAndUnlock]",
            new { UserId = userId, PasswordHash = passwordHash },
            commandType: CommandType.StoredProcedure
        );
    }

    /// <summary>
    /// Get user by ID
    /// </summary>
    public async Task<User?> GetUserByIdAsync(long userId)
    {
        using var connection = _dbHelper.GetConnection();
        return await connection.QueryFirstOrDefaultAsync<User>(
            "[auth].[sp_GetUserById]",
            new { UserId = userId },
            commandType: CommandType.StoredProcedure
        );
    }

    /// <summary>
    /// Get user with roles
    /// </summary>
    public async Task<(User User, List<string> Roles)> GetUserWithRolesAsync(long userId)
    {
        using var connection = _dbHelper.GetConnection();

        // Call stored procedure that returns multiple result sets
        using var multi = await connection.QueryMultipleAsync(
            "[auth].[sp_GetUserWithRoles]",
            new { UserId = userId },
            commandType: CommandType.StoredProcedure
        );

        var user = await multi.ReadSingleOrDefaultAsync<User>();
        if (user == null)
        {
            throw new InvalidOperationException("User not found");
        }

        var roles = (await multi.ReadAsync<string>()).ToList();

        return (user, roles);
    }

    /// <summary>
    /// Increment failed login attempts
    /// </summary>
    private async Task IncrementFailedLoginAttemptsAsync(long userId)
    {
        using var connection = _dbHelper.GetConnection();
        await connection.ExecuteAsync(
            "[auth].[sp_TrackFailedLogin]",
            new { UserId = userId, IpAddress = (string?)null, UserAgent = (string?)null },
            commandType: CommandType.StoredProcedure
        );
    }

    /// <summary>
    /// Reset failed login attempts
    /// </summary>
    private async Task ResetFailedLoginAttemptsAsync(long userId)
    {
        using var connection = _dbHelper.GetConnection();
        await connection.ExecuteAsync(
            "[auth].[sp_UpdateLastLogin]",
            new { UserId = userId, IpAddress = (string?)null, UserAgent = (string?)null },
            commandType: CommandType.StoredProcedure
        );
    }

    /// <summary>
    /// Log login attempt
    /// </summary>
    private async Task LogLoginAttemptAsync(
        string email,
        long? userId,
        bool success,
        string? failureReason,
        string? ipAddress,
        string? userAgent)
    {
        // Keep inline SQL for logging (optional table, not critical)
        using var connection = _dbHelper.GetConnection();

        try
        {
            await connection.ExecuteAsync(
                @"INSERT INTO [auth].[LoginAttempts]
                  (Email, UserId, IpAddress, UserAgent, Success, FailureReason)
                  VALUES (@Email, @UserId, @IpAddress, @UserAgent, @Success, @FailureReason)",
                new
                {
                    Email = email,
                    UserId = userId,
                    IpAddress = ipAddress,
                    UserAgent = userAgent,
                    Success = success,
                    FailureReason = failureReason
                }
            );
        }
        catch
        {
            // Ignore logging errors - don't fail the operation
        }
    }
}
