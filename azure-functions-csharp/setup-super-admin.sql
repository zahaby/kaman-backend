-- ============================================
-- Setup Super Admin User for Kaman Azure Functions
-- ============================================
-- This script creates a super admin user that you can use to login
-- and create companies and other users through the API

-- 1. First, let's check if we have any existing users
SELECT
    u.UserId,
    u.Email,
    u.DisplayName,
    u.CompanyId,
    u.IsActive,
    u.IsLocked,
    STRING_AGG(r.RoleCode, ', ') as Roles
FROM [auth].[Users] u
LEFT JOIN [auth].[UserRoles] ur ON u.UserId = ur.UserId
LEFT JOIN [auth].[Roles] r ON ur.RoleId = r.RoleId
WHERE u.DeletedAtUtc IS NULL
GROUP BY u.UserId, u.Email, u.DisplayName, u.CompanyId, u.IsActive, u.IsLocked;

-- 2. Check what roles exist in the system
SELECT RoleId, RoleCode, RoleName, Description
FROM [auth].[Roles]
WHERE DeletedAtUtc IS NULL;

-- ============================================
-- 3. CREATE SUPER ADMIN USER
-- ============================================
-- Run this section if you don't have a super admin user yet
-- Default credentials will be:
-- Email: superadmin@kaman.com
-- Password: Kaman@2025

-- The password hash below is BCrypt hash of "Kaman@2025" with work factor 12
-- Generated using: BCrypt.Net.BCrypt.HashPassword("Kaman@2025", 12)

DECLARE @SuperAdminEmail NVARCHAR(256) = 'superadmin@kaman.com';
DECLARE @SuperAdminDisplayName NVARCHAR(128) = 'Super Administrator';
DECLARE @PasswordHash VARBINARY(MAX);
DECLARE @UserId BIGINT;
DECLARE @SuperAdminRoleId BIGINT;

-- Check if user already exists
IF NOT EXISTS (SELECT 1 FROM [auth].[Users] WHERE Email = @SuperAdminEmail AND DeletedAtUtc IS NULL)
BEGIN
    -- BCrypt hash for "Kaman@2025"
    -- Note: You'll need to generate this using the actual BCrypt library
    -- For now, this is a placeholder - see instructions below
    SET @PasswordHash = CONVERT(VARBINARY(MAX), '$2a$12$YourBCryptHashWillGoHere');

    PRINT 'Creating super admin user...';

    -- Insert the super admin user
    INSERT INTO [auth].[Users] (
        CompanyId,
        Email,
        DisplayName,
        PasswordHash,
        IsActive,
        IsLocked,
        FailedLoginAttempts
    )
    VALUES (
        NULL,  -- Super admin doesn't belong to any company
        @SuperAdminEmail,
        @SuperAdminDisplayName,
        @PasswordHash,
        1,  -- IsActive
        0,  -- IsLocked
        0   -- FailedLoginAttempts
    );

    SET @UserId = SCOPE_IDENTITY();
    PRINT 'Super admin user created with UserId: ' + CAST(@UserId AS NVARCHAR(20));

    -- Get the SUPER_ADMIN role ID
    SELECT @SuperAdminRoleId = RoleId
    FROM [auth].[Roles]
    WHERE RoleCode = 'SUPER_ADMIN' AND DeletedAtUtc IS NULL;

    IF @SuperAdminRoleId IS NOT NULL
    BEGIN
        -- Assign SUPER_ADMIN role to the user
        INSERT INTO [auth].[UserRoles] (UserId, RoleId)
        VALUES (@UserId, @SuperAdminRoleId);

        PRINT 'SUPER_ADMIN role assigned successfully';
    END
    ELSE
    BEGIN
        PRINT 'ERROR: SUPER_ADMIN role not found in the database!';
        PRINT 'You may need to insert the role first:';
        PRINT 'INSERT INTO [auth].[Roles] (RoleCode, RoleName, Description, IsActive) VALUES (''SUPER_ADMIN'', ''Super Administrator'', ''Full system access'', 1);';
    END
END
ELSE
BEGIN
    PRINT 'Super admin user already exists with email: ' + @SuperAdminEmail;
END

-- ============================================
-- 4. ALTERNATIVE: Create SUPER_ADMIN role if it doesn't exist
-- ============================================
IF NOT EXISTS (SELECT 1 FROM [auth].[Roles] WHERE RoleCode = 'SUPER_ADMIN' AND DeletedAtUtc IS NULL)
BEGIN
    PRINT 'Creating SUPER_ADMIN role...';

    INSERT INTO [auth].[Roles] (RoleCode, RoleName, Description, IsActive)
    VALUES ('SUPER_ADMIN', 'Super Administrator', 'Full system access', 1);

    PRINT 'SUPER_ADMIN role created successfully';
END

-- ============================================
-- 5. VERIFY SETUP
-- ============================================
PRINT '========================================';
PRINT 'Verification:';
PRINT '========================================';

-- Check the super admin user
SELECT
    u.UserId,
    u.Email,
    u.DisplayName,
    u.IsActive,
    u.IsLocked,
    u.CreatedAtUtc
FROM [auth].[Users] u
WHERE u.Email = 'superadmin@kaman.com' AND u.DeletedAtUtc IS NULL;

-- Check the user's roles
SELECT
    u.Email,
    r.RoleCode,
    r.RoleName
FROM [auth].[Users] u
JOIN [auth].[UserRoles] ur ON u.UserId = ur.UserId
JOIN [auth].[Roles] r ON ur.RoleId = r.RoleId
WHERE u.Email = 'superadmin@kaman.com' AND u.DeletedAtUtc IS NULL;

PRINT '========================================';
PRINT 'IMPORTANT NOTES:';
PRINT '========================================';
PRINT '1. The password hash in this script is a PLACEHOLDER';
PRINT '2. You need to generate a proper BCrypt hash for "Kaman@2025"';
PRINT '3. See the instructions below on how to generate the hash';
PRINT '';
PRINT 'Default Login Credentials:';
PRINT 'Email: superadmin@kaman.com';
PRINT 'Password: Kaman@2025';
PRINT '========================================';

/*
============================================
HOW TO GENERATE BCRYPT HASH
============================================

Option 1: Use a C# snippet
---------------------------
using BCrypt.Net;
var hash = BCrypt.Net.BCrypt.HashPassword("Kaman@2025", 12);
Console.WriteLine(hash);

Option 2: Use the Azure Function
---------------------------------
Create a temporary endpoint to hash passwords, or use the Azure Function's
PasswordHelper.HashPassword method directly in a test.

Option 3: Use an online BCrypt generator
-----------------------------------------
Visit: https://bcrypt-generator.com/
Enter: Kaman@2025
Rounds: 12
Copy the generated hash

Then update the script above:
SET @PasswordHash = CONVERT(VARBINARY(MAX), '<your-bcrypt-hash-here>');

============================================
ALTERNATIVE: Insert User Using Azure Function
============================================

If you prefer, you can use the CreateUserAndLogin API endpoint:
1. First, manually insert a super admin user in the database using a simple password
2. Login with that user to get a token
3. Then use the SetPassword endpoint to set a secure password

OR create a temporary "bootstrap" endpoint that creates the first super admin
without authentication (then disable it after use).
*/
