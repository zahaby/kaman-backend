using Dapper;
using KamanAzureFunctions.DTOs;
using KamanAzureFunctions.Helpers;
using KamanAzureFunctions.Models;

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
                @"SELECT UserId FROM [auth].[Users]
                  WHERE Email = @Email AND DeletedAtUtc IS NULL",
                new { request.Email },
                transaction
            );

            if (existingUser != null)
            {
                throw new InvalidOperationException("User with this email already exists");
            }

            // Verify company exists
            var company = await connection.QueryFirstOrDefaultAsync<Company>(
                @"SELECT CompanyId, IsActive FROM [core].[Companies]
                  WHERE CompanyId = @CompanyId AND DeletedAtUtc IS NULL",
                new { request.CompanyId },
                transaction
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
            var user = await connection.QuerySingleAsync<User>(
                @"INSERT INTO [auth].[Users] (
                    CompanyId, Email, DisplayName, PasswordHash, IsActive
                  )
                  OUTPUT INSERTED.*
                  VALUES (
                    @CompanyId, @Email, @DisplayName, @PasswordHash, 1
                  )",
                new
                {
                    request.CompanyId,
                    request.Email,
                    request.DisplayName,
                    PasswordHash = passwordHash
                },
                transaction
            );

            // Assign role (default to COMPANY_ADMIN if not specified)
            var roleId = request.RoleId ?? 2; // 2 = COMPANY_ADMIN
            await connection.ExecuteAsync(
                @"INSERT INTO [auth].[UserRoles] (UserId, RoleId)
                  VALUES (@UserId, @RoleId)",
                new { UserId = user.UserId, RoleId = roleId },
                transaction
            );

            // Get user roles
            var roles = await connection.QueryAsync<string>(
                @"SELECT r.Name
                  FROM [auth].[UserRoles] ur
                  JOIN [auth].[Roles] r ON r.RoleId = ur.RoleId
                  WHERE ur.UserId = @UserId",
                new { UserId = user.UserId },
                transaction
            );

            transaction.Commit();

            // Generate tokens
            var jwtPayload = new JwtPayload
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

        // Get user with roles
        var userResult = await connection.QueryAsync<dynamic>(
            @"SELECT u.*, r.Name as RoleName
              FROM [auth].[Users] u
              LEFT JOIN [auth].[UserRoles] ur ON ur.UserId = u.UserId
              LEFT JOIN [auth].[Roles] r ON r.RoleId = ur.RoleId
              WHERE u.Email = @Email AND u.DeletedAtUtc IS NULL",
            new { Email = email }
        );

        var userList = userResult.ToList();

        if (!userList.Any())
        {
            await LogLoginAttemptAsync(email, null, false, "User not found", ipAddress, userAgent);
            throw new UnauthorizedAccessException("Invalid email or password");
        }

        var userRecord = userList.First();
        var user = new User
        {
            UserId = userRecord.UserId,
            CompanyId = userRecord.CompanyId,
            Email = userRecord.Email,
            DisplayName = userRecord.DisplayName,
            PasswordHash = userRecord.PasswordHash,
            PasswordSalt = userRecord.PasswordSalt,
            IsActive = userRecord.IsActive,
            IsLocked = userRecord.IsLocked,
            FailedLoginAttempts = userRecord.FailedLoginAttempts,
            LastFailedLoginUtc = userRecord.LastFailedLoginUtc,
            CreatedAtUtc = userRecord.CreatedAtUtc,
            LastLoginUtc = userRecord.LastLoginUtc,
            DeletedAtUtc = userRecord.DeletedAtUtc
        };

        var roles = userList.Where(r => r.RoleName != null).Select(r => (string)r.RoleName).ToList();

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

        // Reset failed login attempts
        await ResetFailedLoginAttemptsAsync(user.UserId);

        // Update last login
        await connection.ExecuteAsync(
            @"UPDATE [auth].[Users]
              SET LastLoginUtc = SYSUTCDATETIME()
              WHERE UserId = @UserId",
            new { UserId = user.UserId }
        );

        // Log successful login
        await LogLoginAttemptAsync(email, user.UserId, true, null, ipAddress, userAgent);

        // Generate tokens
        var jwtPayload = new JwtPayload
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

        // Get user
        var user = await connection.QueryFirstOrDefaultAsync<User>(
            @"SELECT UserId, IsActive FROM [auth].[Users]
              WHERE UserId = @UserId AND DeletedAtUtc IS NULL",
            new { UserId = userId }
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

        // Update password and reset failed attempts if locked
        await connection.ExecuteAsync(
            @"UPDATE [auth].[Users]
              SET PasswordHash = @PasswordHash,
                  FailedLoginAttempts = 0,
                  IsLocked = 0,
                  LastFailedLoginUtc = NULL
              WHERE UserId = @UserId",
            new { UserId = userId, PasswordHash = passwordHash }
        );
    }

    /// <summary>
    /// Get user by ID
    /// </summary>
    public async Task<User?> GetUserByIdAsync(long userId)
    {
        using var connection = _dbHelper.GetConnection();
        return await connection.QueryFirstOrDefaultAsync<User>(
            @"SELECT * FROM [auth].[Users]
              WHERE UserId = @UserId AND DeletedAtUtc IS NULL",
            new { UserId = userId }
        );
    }

    /// <summary>
    /// Get user with roles
    /// </summary>
    public async Task<(User User, List<string> Roles)> GetUserWithRolesAsync(long userId)
    {
        using var connection = _dbHelper.GetConnection();

        var userResult = await connection.QueryAsync<dynamic>(
            @"SELECT u.*, r.Name as RoleName
              FROM [auth].[Users] u
              LEFT JOIN [auth].[UserRoles] ur ON ur.UserId = u.UserId
              LEFT JOIN [auth].[Roles] r ON r.RoleId = ur.RoleId
              WHERE u.UserId = @UserId AND u.DeletedAtUtc IS NULL",
            new { UserId = userId }
        );

        var userList = userResult.ToList();

        if (!userList.Any())
        {
            throw new InvalidOperationException("User not found");
        }

        var userRecord = userList.First();
        var user = new User
        {
            UserId = userRecord.UserId,
            CompanyId = userRecord.CompanyId,
            Email = userRecord.Email,
            DisplayName = userRecord.DisplayName,
            PasswordHash = userRecord.PasswordHash,
            PasswordSalt = userRecord.PasswordSalt,
            IsActive = userRecord.IsActive,
            IsLocked = userRecord.IsLocked,
            FailedLoginAttempts = userRecord.FailedLoginAttempts,
            LastFailedLoginUtc = userRecord.LastFailedLoginUtc,
            CreatedAtUtc = userRecord.CreatedAtUtc,
            LastLoginUtc = userRecord.LastLoginUtc,
            DeletedAtUtc = userRecord.DeletedAtUtc
        };

        var roles = userList.Where(r => r.RoleName != null).Select(r => (string)r.RoleName).ToList();

        return (user, roles);
    }

    /// <summary>
    /// Increment failed login attempts
    /// </summary>
    private async Task IncrementFailedLoginAttemptsAsync(long userId)
    {
        using var connection = _dbHelper.GetConnection();
        await connection.ExecuteAsync(
            @"UPDATE [auth].[Users]
              SET FailedLoginAttempts = FailedLoginAttempts + 1,
                  LastFailedLoginUtc = SYSUTCDATETIME(),
                  IsLocked = CASE WHEN FailedLoginAttempts >= 4 THEN 1 ELSE 0 END
              WHERE UserId = @UserId",
            new { UserId = userId }
        );
    }

    /// <summary>
    /// Reset failed login attempts
    /// </summary>
    private async Task ResetFailedLoginAttemptsAsync(long userId)
    {
        using var connection = _dbHelper.GetConnection();
        await connection.ExecuteAsync(
            @"UPDATE [auth].[Users]
              SET FailedLoginAttempts = 0,
                  LastFailedLoginUtc = NULL,
                  IsLocked = 0
              WHERE UserId = @UserId",
            new { UserId = userId }
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
        using var connection = _dbHelper.GetConnection();
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
}
