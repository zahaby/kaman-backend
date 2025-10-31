# Stored Procedures Implementation Guide

## ✅ What Has Been Done (Part 1)

### 1. Created 22 Stored Procedures (`StoredProcedures.sql`)

All SQL logic has been moved to the database layer for better security, performance, and maintainability.

**Company Procedures (7):**
- `sp_CheckCompanyCodeExists` - Check if company code exists
- `sp_CheckCompanyEmailExists` - Check if email exists
- `sp_InsertCompany` - Create new company
- `sp_GetCompanyById` - Get company by ID
- `sp_IsCompanyActive` - Check if company is active
- `sp_GetAllCompanies` - List all companies (with optional inactive filter)

**Wallet Procedures (1):**
- `sp_GetWalletByCompanyId` - Get wallet for a company

**User Procedures (9):**
- `sp_CheckUserEmailExists` - Check if user email exists
- `sp_InsertUser` - Create new user
- `sp_GetUserById` - Get user by ID
- `sp_GetUserByEmailForLogin` - Get user for login validation
- `sp_GetUserWithRoles` - Get user with all their roles
- `sp_UpdateUserPassword` - Update user password
- `sp_UpdateLastLogin` - Update last login timestamp and clear failed attempts
- `sp_TrackFailedLogin` - Increment failed login counter and lock if needed
- `sp_ResetPasswordAndUnlock` - Reset password and unlock account

**Role Procedures (4):**
- `sp_CheckRoleExists` - Check if role exists by name
- `sp_InsertRole` - Create new role
- `sp_GetUserRoles` - Get all roles for a user
- `sp_AssignRoleToUser` - Assign role to user

**Admin Procedures (2):**
- `sp_CheckSuperAdminExists` - Check if any super admin exists
- `sp_VerifyUserIsSuperAdmin` - Verify user is super admin by email

### 2. Refactored CompanyService (COMPLETE ✅)

All 5 methods now use stored procedures:
- `CreateCompanyWithWalletAsync`
- `GetCompanyByIdAsync`
- `IsCompanyActiveAsync`
- `GetAllCompaniesAsync`

---

## 🔄 Still To Do (Part 2)

### Remaining Services to Refactor:

1. **UserService.cs** - 8 methods need refactoring
2. **BootstrapFunction.cs** - Database operations need refactoring
3. **ResetSuperAdminPasswordFunction.cs** - Password reset logic

---

## 📋 Installation Steps

### Step 1: Run the Stored Procedures Script

**On your SQL Server database:**

```sql
-- Connect to your KamanDb database
USE [KamanDb]
GO

-- Run the entire StoredProcedures.sql script
-- This will create all 22 stored procedures
```

**In SQL Server Management Studio or Azure Data Studio:**
1. Open `StoredProcedures.sql`
2. Execute the entire script
3. Verify all procedures were created successfully

### Step 2: Test the Refactored CompanyService

After running the stored procedures, test the company endpoints:

```bash
cd azure-functions-csharp
dotnet clean
dotnet build
func start
```

**Test in Postman:**
- Create Company: `POST {{baseUrl}}/company/create`
- List Companies: `GET {{baseUrl}}/company/list`

Both should work exactly as before!

---

## 🎯 Pattern for Future Development

### How to Add New Functionality with Stored Procedures

When adding new features, follow this pattern:

#### 1. Create the Stored Procedure First

```sql
-- Add to StoredProcedures.sql or create a new migration script
IF OBJECT_ID('[schema].[sp_YourProcedureName]', 'P') IS NOT NULL
    DROP PROCEDURE [schema].[sp_YourProcedureName];
GO

CREATE PROCEDURE [schema].[sp_YourProcedureName]
    @Parameter1 TYPE,
    @Parameter2 TYPE = NULL  -- Optional parameters with defaults
AS
BEGIN
    SET NOCOUNT ON;

    -- Your SQL logic here
    SELECT * FROM [schema].[TableName]
    WHERE Column = @Parameter1;
END
GO
```

#### 2. Call from C# Service

```csharp
using System.Data;  // Required for CommandType

public async Task<YourModel> YourMethodAsync(parameters)
{
    using var connection = _dbHelper.GetConnection();

    return await connection.QueryFirstOrDefaultAsync<YourModel>(
        "[schema].[sp_YourProcedureName]",
        new {
            Parameter1 = value1,
            Parameter2 = value2
        },
        commandType: CommandType.StoredProcedure
    );
}
```

### Key Points:

1. **Always specify `CommandType.StoredProcedure`**
2. **Use proper schema prefix**: `[schema].[sp_ProcedureName]`
3. **Parameter names must match** between SQL and C#
4. **Handle transactions properly** when needed

---

## 🔍 Examples

### Example 1: Simple Query (No Transaction)

**Stored Procedure:**
```sql
CREATE PROCEDURE [auth].[sp_GetUserById]
    @UserId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [auth].[Users] WHERE UserId = @UserId;
END
GO
```

**C# Usage:**
```csharp
public async Task<User?> GetUserByIdAsync(long userId)
{
    using var connection = _dbHelper.GetConnection();
    return await connection.QueryFirstOrDefaultAsync<User>(
        "[auth].[sp_GetUserById]",
        new { UserId = userId },
        commandType: CommandType.StoredProcedure
    );
}
```

### Example 2: Insert with Return Value

**Stored Procedure:**
```sql
CREATE PROCEDURE [core].[sp_InsertCompany]
    @CompanyCode NVARCHAR(32),
    @Name NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [core].[Companies] (CompanyCode, Name)
    VALUES (@CompanyCode, @Name);

    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS CompanyId;
END
GO
```

**C# Usage:**
```csharp
var result = await connection.QuerySingleAsync<dynamic>(
    "[core].[sp_InsertCompany]",
    new { CompanyCode = "TEST", Name = "Test Company" },
    transaction,
    commandType: CommandType.StoredProcedure
);

long companyId = result.CompanyId;
```

### Example 3: Multiple Result Sets

**Stored Procedure:**
```sql
CREATE PROCEDURE [auth].[sp_GetUserWithRoles]
    @UserId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    -- First result set: User
    SELECT * FROM [auth].[Users] WHERE UserId = @UserId;

    -- Second result set: Roles
    SELECT r.Name
    FROM [auth].[UserRoles] ur
    JOIN [auth].[Roles] r ON ur.RoleId = r.RoleId
    WHERE ur.UserId = @UserId;
END
GO
```

**C# Usage:**
```csharp
using var connection = _dbHelper.GetConnection();
using var multi = await connection.QueryMultipleAsync(
    "[auth].[sp_GetUserWithRoles]",
    new { UserId = userId },
    commandType: CommandType.StoredProcedure
);

var user = await multi.ReadSingleOrDefaultAsync<User>();
var roles = (await multi.ReadAsync<string>()).ToList();

return (user, roles);
```

### Example 4: With Transaction

**C# Usage:**
```csharp
using var connection = _dbHelper.GetConnection();
await connection.OpenAsync();

using var transaction = connection.BeginTransaction();

try
{
    // Call stored procedure within transaction
    var companyId = await connection.ExecuteScalarAsync<long>(
        "[core].[sp_InsertCompany]",
        new { CompanyCode = "TEST", Name = "Test" },
        transaction,
        commandType: CommandType.StoredProcedure
    );

    // Call another stored procedure
    await connection.ExecuteAsync(
        "[core].[sp_SomeOtherProcedure]",
        new { CompanyId = companyId },
        transaction,
        commandType: CommandType.StoredProcedure
    );

    transaction.Commit();
}
catch
{
    transaction.Rollback();
    throw;
}
```

---

## ✅ Benefits of Using Stored Procedures

1. **Security**
   - SQL injection prevention
   - Parameterized queries enforced
   - Database-level permission control

2. **Performance**
   - Query execution plans cached
   - Reduced network traffic
   - Compiled and optimized by SQL Server

3. **Maintainability**
   - SQL logic in one place (database)
   - Easier to test SQL independently
   - Can update SQL without C# code changes

4. **Separation of Concerns**
   - Business logic in C#
   - Data access logic in SQL
   - Clear boundaries

5. **Compatibility**
   - Works with table triggers (no OUTPUT INSERTED conflicts)
   - Consistent behavior across different SQL Server versions

---

## ⚠️ Important Notes

### DO:
- ✅ Always use `CommandType.StoredProcedure`
- ✅ Include schema prefix: `[schema].[sp_Name]`
- ✅ Match parameter names exactly
- ✅ Use `SCOPE_IDENTITY()` for inserted IDs
- ✅ Set `NOCOUNT ON` in procedures
- ✅ Document your stored procedures

### DON'T:
- ❌ Mix inline SQL with stored procedures
- ❌ Forget to drop existing procedure before CREATE
- ❌ Use dynamic SQL in stored procedures (unless absolutely necessary)
- ❌ Return multiple result sets unless needed
- ❌ Forget to handle NULL parameters

---

## 🚀 Next Steps

1. **Complete the refactoring** of remaining services (UserService, Bootstrap, Reset)
2. **Test all endpoints** thoroughly
3. **Monitor performance** - stored procedures should be faster
4. **Document new procedures** as you add them
5. **Keep StoredProcedures.sql updated** with all changes

---

## 📞 Need Help?

When creating new stored procedures:
1. Follow the existing patterns in `StoredProcedures.sql`
2. Test the procedure in SQL Server Management Studio first
3. Use the examples above as templates
4. Always handle errors appropriately

Remember: **Database first, then C# code!**
