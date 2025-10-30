# Quick Start Guide - Kaman Azure Functions API

## Prerequisites

- [x] .NET 8.0 SDK installed
- [x] Azure Functions Core Tools v4
- [x] Database credentials provided
- [x] Postman installed (for testing)

## Step-by-Step Setup

### 1. Verify Prerequisites

```bash
# Check .NET version
dotnet --version
# Should show 8.0.x

# Check Azure Functions Core Tools
func --version
# Should show 4.x.x
```

### 2. Navigate to Project Directory

```bash
cd azure-functions-csharp
```

### 3. Configuration is Already Done! ✓

Your `local.settings.json` has been configured with:
- ✓ Database connection string (15.237.228.106)
- ✓ JWT secrets
- ✓ Default password (Kaman@2025)

**No additional configuration needed!**

### 4. Restore NuGet Packages

```bash
dotnet restore
```

Expected output:
```
Restoring packages for KamanAzureFunctions.csproj...
  Determining projects to restore...
  Restored KamanAzureFunctions.csproj (in X ms).
```

### 5. Build the Project

```bash
dotnet build
```

Expected output:
```
Build succeeded.
    0 Warning(s)
    0 Error(s)
```

### 6. Start Azure Functions

```bash
func start
```

Expected output:
```
Azure Functions Core Tools
Core Tools Version: 4.x.x
Function Runtime Version: 4.x.x

Functions:

  CreateCompany: [POST] http://localhost:7071/api/company/create
  CreateUserAndLogin: [POST] http://localhost:7071/api/user/create
  Login: [POST] http://localhost:7071/api/auth/login
  RefreshToken: [POST] http://localhost:7071/api/auth/refresh
  SetPassword: [POST] http://localhost:7071/api/user/set-password

For detailed output, run func with --verbose flag.
```

**✅ If you see this, your API is running!**

### 7. Test with Postman

#### Import Collection

1. Open Postman
2. Click **Import** button
3. Drag and drop these files:
   - `Kaman_API_Collection.postman_collection.json`
   - `Kaman_API_Environment_Local.postman_environment.json`

#### Configure Super Admin Credentials

1. Select **Kaman API - Local Development** environment (top-right dropdown)
2. Click the **eye icon** next to the environment
3. Click **Edit**
4. Update these values:
   - `userEmail`: Your super admin email (e.g., `superadmin@kaman.local`)
   - `userPassword`: Your super admin password
5. Click **Save**

#### Run First Test

1. Navigate to **Authentication > Login**
2. Click **Send**
3. ✅ You should see:
   ```json
   {
     "success": true,
     "message": "Login successful",
     "data": {
       "user": { ... },
       "authentication": {
         "accessToken": "eyJ...",
         "refreshToken": "eyJ...",
         ...
       }
     }
   }
   ```

#### Run Complete Workflow

1. Navigate to **Test Workflows** folder
2. Right-click the folder
3. Select **Run folder**
4. Click **Run Kaman API Collection**
5. Watch all 6 tests run automatically!

Expected results:
```
✓ 1. Login as Super Admin
✓ 2. Create New Company
✓ 3. Create Company User
✓ 4. Login as New User
✓ 5. Change User Password
✓ 6. Login with New Password

6/6 tests passed
```

## Troubleshooting

### Issue: "Cannot connect to SQL Server"

**Check:**
```bash
# Test if you can reach the server
ping 15.237.228.106

# Check if port 1433 is open
telnet 15.237.228.106 1433
```

**Solution:** Ensure your firewall allows outbound connections to SQL Server port 1433

### Issue: "Invalid email or password" when logging in

**Possible causes:**
1. Super admin user doesn't exist in database
2. Password is incorrect
3. User account is locked

**Solution:** Verify the super admin credentials in your database or create one using SQL:

```sql
-- Check if super admin exists
SELECT * FROM [auth].[Users]
WHERE Email = 'superadmin@kaman.local';

-- Check user roles
SELECT u.Email, r.Name as Role
FROM [auth].[Users] u
JOIN [auth].[UserRoles] ur ON u.UserId = ur.UserId
JOIN [auth].[Roles] r ON r.RoleId = ur.RoleId
WHERE u.Email = 'superadmin@kaman.local';
```

### Issue: "Tokens are null or undefined" in Postman

**Solution:**
1. Check the **Console** in Postman (View > Show Postman Console)
2. Verify the test scripts ran successfully
3. Manually check the environment variables (eye icon)

### Issue: Build errors

**Solution:**
```bash
# Clean and rebuild
dotnet clean
dotnet restore
dotnet build
```

## Quick Test Commands

### Test Login with cURL

```bash
curl -X POST http://localhost:7071/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "superadmin@kaman.local",
    "password": "YourPassword123!"
  }'
```

### Test Create Company (replace TOKEN)

```bash
curl -X POST http://localhost:7071/api/company/create \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "companyCode": "TEST001",
    "name": "Test Company",
    "email": "test@company.com",
    "defaultCurrency": "EGP"
  }'
```

## Next Steps

After successful setup:

1. ✅ **Test all endpoints** using Postman collection
2. ✅ **Create test companies and users** for development
3. ✅ **Review the API documentation** in README.md
4. ✅ **Integrate with Flutter app** using the base URL `http://localhost:7071/api`

## Connection Details Summary

| Setting | Value |
|---------|-------|
| API Base URL | http://localhost:7071/api |
| Database Server | 15.237.228.106 |
| Database Name | KamanDb |
| Default Password | Kaman@2025 |
| JWT Expiration | 60 minutes |
| Refresh Token Expiration | 7 days |

## Support Files

- `README.md` - Complete documentation
- `POSTMAN_GUIDE.md` - Detailed Postman usage guide
- `DATABASE_CONFIG.md` - Database configuration details
- `QUICK_START.md` - This file

## Getting Help

If you encounter issues:

1. Check the Azure Functions console output for errors
2. Review the Postman Console (View > Show Postman Console)
3. Check database connectivity
4. Verify all configuration values in `local.settings.json`

---

**You're all set!** 🚀 Start testing your API endpoints with Postman.
