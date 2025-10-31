-- =============================================
-- Kaman Azure Functions - Stored Procedures
-- =============================================
-- This script creates all stored procedures needed for the Azure Functions middleware
-- Run this script on your KamanDb database before deploying the application
--
-- Author: Kaman Development Team
-- Date: 2025-10-31
-- =============================================

USE [KamanDb]
GO

-- =============================================
-- SECTION 1: COMPANY STORED PROCEDURES
-- =============================================

-- Check if company code exists
IF OBJECT_ID('[core].[sp_CheckCompanyCodeExists]', 'P') IS NOT NULL
    DROP PROCEDURE [core].[sp_CheckCompanyCodeExists];
GO

CREATE PROCEDURE [core].[sp_CheckCompanyCodeExists]
    @CompanyCode NVARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT CompanyId
    FROM [core].[Companies]
    WHERE CompanyCode = @CompanyCode
      AND DeletedAtUtc IS NULL;
END
GO

-- Check if company email exists
IF OBJECT_ID('[core].[sp_CheckCompanyEmailExists]', 'P') IS NOT NULL
    DROP PROCEDURE [core].[sp_CheckCompanyEmailExists];
GO

CREATE PROCEDURE [core].[sp_CheckCompanyEmailExists]
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT CompanyId
    FROM [core].[Companies]
    WHERE Email = @Email
      AND DeletedAtUtc IS NULL;
END
GO

-- Insert new company
IF OBJECT_ID('[core].[sp_InsertCompany]', 'P') IS NOT NULL
    DROP PROCEDURE [core].[sp_InsertCompany];
GO

CREATE PROCEDURE [core].[sp_InsertCompany]
    @CompanyCode NVARCHAR(32),
    @Name NVARCHAR(200),
    @Email NVARCHAR(256),
    @Phone NVARCHAR(64) = NULL,
    @Country NVARCHAR(64) = NULL,
    @Address NVARCHAR(512) = NULL,
    @DefaultCurrency NVARCHAR(3) = 'EGP',
    @MinimumBalance DECIMAL(18, 2) = 0
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [core].[Companies] (
        CompanyCode, Name, Email, Phone, Country, Address,
        DefaultCurrency, MinimumBalance, IsActive
    )
    VALUES (
        @CompanyCode, @Name, @Email, @Phone, @Country, @Address,
        @DefaultCurrency, @MinimumBalance, 1
    );

    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS CompanyId;
END
GO

-- Get company by ID
IF OBJECT_ID('[core].[sp_GetCompanyById]', 'P') IS NOT NULL
    DROP PROCEDURE [core].[sp_GetCompanyById];
GO

CREATE PROCEDURE [core].[sp_GetCompanyById]
    @CompanyId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM [core].[Companies]
    WHERE CompanyId = @CompanyId
      AND DeletedAtUtc IS NULL;
END
GO

-- Check if company is active
IF OBJECT_ID('[core].[sp_IsCompanyActive]', 'P') IS NOT NULL
    DROP PROCEDURE [core].[sp_IsCompanyActive];
GO

CREATE PROCEDURE [core].[sp_IsCompanyActive]
    @CompanyId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT IsActive
    FROM [core].[Companies]
    WHERE CompanyId = @CompanyId
      AND DeletedAtUtc IS NULL;
END
GO

-- Get all companies
IF OBJECT_ID('[core].[sp_GetAllCompanies]', 'P') IS NOT NULL
    DROP PROCEDURE [core].[sp_GetAllCompanies];
GO

CREATE PROCEDURE [core].[sp_GetAllCompanies]
    @IncludeInactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @IncludeInactive = 1
    BEGIN
        SELECT *
        FROM [core].[Companies]
        WHERE DeletedAtUtc IS NULL
        ORDER BY CreatedAtUtc DESC;
    END
    ELSE
    BEGIN
        SELECT *
        FROM [core].[Companies]
        WHERE IsActive = 1
          AND DeletedAtUtc IS NULL
        ORDER BY CreatedAtUtc DESC;
    END
END
GO

-- =============================================
-- SECTION 2: WALLET STORED PROCEDURES
-- =============================================

-- Get wallet by company ID
IF OBJECT_ID('[wallet].[sp_GetWalletByCompanyId]', 'P') IS NOT NULL
    DROP PROCEDURE [wallet].[sp_GetWalletByCompanyId];
GO

CREATE PROCEDURE [wallet].[sp_GetWalletByCompanyId]
    @CompanyId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM [wallet].[Wallets]
    WHERE CompanyId = @CompanyId;
END
GO

-- =============================================
-- SECTION 3: USER STORED PROCEDURES
-- =============================================

-- Check if user email exists
IF OBJECT_ID('[auth].[sp_CheckUserEmailExists]', 'P') IS NOT NULL
    DROP PROCEDURE [auth].[sp_CheckUserEmailExists];
GO

CREATE PROCEDURE [auth].[sp_CheckUserEmailExists]
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT UserId
    FROM [auth].[Users]
    WHERE Email = @Email
      AND DeletedAtUtc IS NULL;
END
GO

-- Insert new user
IF OBJECT_ID('[auth].[sp_InsertUser]', 'P') IS NOT NULL
    DROP PROCEDURE [auth].[sp_InsertUser];
GO

CREATE PROCEDURE [auth].[sp_InsertUser]
    @CompanyId BIGINT = NULL,
    @Email NVARCHAR(256),
    @DisplayName NVARCHAR(128),
    @PasswordHash VARBINARY(MAX),
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [auth].[Users] (
        CompanyId, Email, DisplayName, PasswordHash, IsActive
    )
    VALUES (
        @CompanyId, @Email, @DisplayName, @PasswordHash, @IsActive
    );

    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS UserId;
END
GO

-- Get user by ID
IF OBJECT_ID('[auth].[sp_GetUserById]', 'P') IS NOT NULL
    DROP PROCEDURE [auth].[sp_GetUserById];
GO

CREATE PROCEDURE [auth].[sp_GetUserById]
    @UserId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM [auth].[Users]
    WHERE UserId = @UserId
      AND DeletedAtUtc IS NULL;
END
GO

-- Get user by email for login
IF OBJECT_ID('[auth].[sp_GetUserByEmailForLogin]', 'P') IS NOT NULL
    DROP PROCEDURE [auth].[sp_GetUserByEmailForLogin];
GO

CREATE PROCEDURE [auth].[sp_GetUserByEmailForLogin]
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM [auth].[Users]
    WHERE Email = @Email
      AND DeletedAtUtc IS NULL;
END
GO

-- Get user with roles
IF OBJECT_ID('[auth].[sp_GetUserWithRoles]', 'P') IS NOT NULL
    DROP PROCEDURE [auth].[sp_GetUserWithRoles];
GO

CREATE PROCEDURE [auth].[sp_GetUserWithRoles]
    @UserId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    -- Return user
    SELECT *
    FROM [auth].[Users]
    WHERE UserId = @UserId
      AND DeletedAtUtc IS NULL;

    -- Return roles
    SELECT r.Name
    FROM [auth].[UserRoles] ur
    JOIN [auth].[Roles] r ON r.RoleId = ur.RoleId
    WHERE ur.UserId = @UserId;
END
GO

-- Update user password
IF OBJECT_ID('[auth].[sp_UpdateUserPassword]', 'P') IS NOT NULL
    DROP PROCEDURE [auth].[sp_UpdateUserPassword];
GO

CREATE PROCEDURE [auth].[sp_UpdateUserPassword]
    @UserId BIGINT,
    @PasswordHash VARBINARY(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [auth].[Users]
    SET PasswordHash = @PasswordHash
    WHERE UserId = @UserId;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- Update last login
IF OBJECT_ID('[auth].[sp_UpdateLastLogin]', 'P') IS NOT NULL
    DROP PROCEDURE [auth].[sp_UpdateLastLogin];
GO

CREATE PROCEDURE [auth].[sp_UpdateLastLogin]
    @UserId BIGINT,
    @IpAddress NVARCHAR(45) = NULL,
    @UserAgent NVARCHAR(512) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [auth].[Users]
    SET LastLoginUtc = GETUTCDATE(),
        FailedLoginAttempts = 0,
        LastFailedLoginUtc = NULL
    WHERE UserId = @UserId;

    -- Log successful login attempt (if you have a login log table)
    -- INSERT INTO [auth].[LoginAttempts] (UserId, IpAddress, UserAgent, IsSuccessful, AttemptedAt)
    -- VALUES (@UserId, @IpAddress, @UserAgent, 1, GETUTCDATE());
END
GO

-- Track failed login attempt
IF OBJECT_ID('[auth].[sp_TrackFailedLogin]', 'P') IS NOT NULL
    DROP PROCEDURE [auth].[sp_TrackFailedLogin];
GO

CREATE PROCEDURE [auth].[sp_TrackFailedLogin]
    @UserId BIGINT,
    @IpAddress NVARCHAR(45) = NULL,
    @UserAgent NVARCHAR(512) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FailedAttempts INT;

    UPDATE [auth].[Users]
    SET FailedLoginAttempts = FailedLoginAttempts + 1,
        LastFailedLoginUtc = GETUTCDATE(),
        IsLocked = CASE WHEN FailedLoginAttempts + 1 >= 5 THEN 1 ELSE IsLocked END
    WHERE UserId = @UserId;

    SELECT FailedLoginAttempts, IsLocked
    FROM [auth].[Users]
    WHERE UserId = @UserId;

    -- Log failed login attempt (if you have a login log table)
    -- INSERT INTO [auth].[LoginAttempts] (UserId, IpAddress, UserAgent, IsSuccessful, AttemptedAt)
    -- VALUES (@UserId, @IpAddress, @UserAgent, 0, GETUTCDATE());
END
GO

-- Reset password and unlock account
IF OBJECT_ID('[auth].[sp_ResetPasswordAndUnlock]', 'P') IS NOT NULL
    DROP PROCEDURE [auth].[sp_ResetPasswordAndUnlock];
GO

CREATE PROCEDURE [auth].[sp_ResetPasswordAndUnlock]
    @UserId BIGINT,
    @PasswordHash VARBINARY(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [auth].[Users]
    SET PasswordHash = @PasswordHash,
        IsLocked = 0,
        FailedLoginAttempts = 0,
        LastFailedLoginUtc = NULL
    WHERE UserId = @UserId;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- =============================================
-- SECTION 4: ROLE STORED PROCEDURES
-- =============================================

-- Check if role exists by name
IF OBJECT_ID('[auth].[sp_CheckRoleExists]', 'P') IS NOT NULL
    DROP PROCEDURE [auth].[sp_CheckRoleExists];
GO

CREATE PROCEDURE [auth].[sp_CheckRoleExists]
    @RoleName NVARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT RoleId, Name
    FROM [auth].[Roles]
    WHERE Name = @RoleName;
END
GO

-- Insert new role
IF OBJECT_ID('[auth].[sp_InsertRole]', 'P') IS NOT NULL
    DROP PROCEDURE [auth].[sp_InsertRole];
GO

CREATE PROCEDURE [auth].[sp_InsertRole]
    @RoleName NVARCHAR(64),
    @Description NVARCHAR(512) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [auth].[Roles] (Name, Description)
    VALUES (@RoleName, @Description);

    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS RoleId;
END
GO

-- Get user roles
IF OBJECT_ID('[auth].[sp_GetUserRoles]', 'P') IS NOT NULL
    DROP PROCEDURE [auth].[sp_GetUserRoles];
GO

CREATE PROCEDURE [auth].[sp_GetUserRoles]
    @UserId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT r.Name
    FROM [auth].[UserRoles] ur
    JOIN [auth].[Roles] r ON r.RoleId = ur.RoleId
    WHERE ur.UserId = @UserId;
END
GO

-- Assign role to user
IF OBJECT_ID('[auth].[sp_AssignRoleToUser]', 'P') IS NOT NULL
    DROP PROCEDURE [auth].[sp_AssignRoleToUser];
GO

CREATE PROCEDURE [auth].[sp_AssignRoleToUser]
    @UserId BIGINT,
    @RoleId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if already assigned
    IF NOT EXISTS (
        SELECT 1 FROM [auth].[UserRoles]
        WHERE UserId = @UserId AND RoleId = @RoleId
    )
    BEGIN
        INSERT INTO [auth].[UserRoles] (UserId, RoleId)
        VALUES (@UserId, @RoleId);
    END
END
GO

-- =============================================
-- SECTION 5: BOOTSTRAP/ADMIN STORED PROCEDURES
-- =============================================

-- Check if super admin exists
IF OBJECT_ID('[auth].[sp_CheckSuperAdminExists]', 'P') IS NOT NULL
    DROP PROCEDURE [auth].[sp_CheckSuperAdminExists];
GO

CREATE PROCEDURE [auth].[sp_CheckSuperAdminExists]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT u.UserId, u.Email
    FROM [auth].[Users] u
    JOIN [auth].[UserRoles] ur ON u.UserId = ur.UserId
    JOIN [auth].[Roles] r ON ur.RoleId = r.RoleId
    WHERE r.Name = 'SUPER_ADMIN'
      AND u.DeletedAtUtc IS NULL;
END
GO

-- Verify user is super admin by email
IF OBJECT_ID('[auth].[sp_VerifyUserIsSuperAdmin]', 'P') IS NOT NULL
    DROP PROCEDURE [auth].[sp_VerifyUserIsSuperAdmin];
GO

CREATE PROCEDURE [auth].[sp_VerifyUserIsSuperAdmin]
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT u.UserId, u.Email, u.DisplayName, u.IsActive
    FROM [auth].[Users] u
    JOIN [auth].[UserRoles] ur ON u.UserId = ur.UserId
    JOIN [auth].[Roles] r ON ur.RoleId = r.RoleId
    WHERE u.Email = @Email
      AND r.Name = 'SUPER_ADMIN'
      AND u.DeletedAtUtc IS NULL;
END
GO

-- =============================================
-- VERIFICATION
-- =============================================

PRINT '========================================';
PRINT 'Stored Procedures Created Successfully!';
PRINT '========================================';
PRINT '';
PRINT 'Company Procedures:';
PRINT '  - sp_CheckCompanyCodeExists';
PRINT '  - sp_CheckCompanyEmailExists';
PRINT '  - sp_InsertCompany';
PRINT '  - sp_GetCompanyById';
PRINT '  - sp_IsCompanyActive';
PRINT '  - sp_GetAllCompanies';
PRINT '';
PRINT 'Wallet Procedures:';
PRINT '  - sp_GetWalletByCompanyId';
PRINT '';
PRINT 'User Procedures:';
PRINT '  - sp_CheckUserEmailExists';
PRINT '  - sp_InsertUser';
PRINT '  - sp_GetUserById';
PRINT '  - sp_GetUserByEmailForLogin';
PRINT '  - sp_GetUserWithRoles';
PRINT '  - sp_UpdateUserPassword';
PRINT '  - sp_UpdateLastLogin';
PRINT '  - sp_TrackFailedLogin';
PRINT '  - sp_ResetPasswordAndUnlock';
PRINT '';
PRINT 'Role Procedures:';
PRINT '  - sp_CheckRoleExists';
PRINT '  - sp_InsertRole';
PRINT '  - sp_GetUserRoles';
PRINT '  - sp_AssignRoleToUser';
PRINT '';
PRINT 'Admin Procedures:';
PRINT '  - sp_CheckSuperAdminExists';
PRINT '  - sp_VerifyUserIsSuperAdmin';
PRINT '';
PRINT '========================================';
PRINT 'Total: 22 stored procedures';
PRINT '========================================';

GO
