# Admin Operations Guide

This guide covers administrative operations for the Kaman Azure Functions middleware, including initial setup and emergency procedures.

---

## Table of Contents
1. [Bootstrap: Create First Super Admin](#bootstrap-create-first-super-admin)
2. [Reset Super Admin Password](#reset-super-admin-password)
3. [Security Best Practices](#security-best-practices)

---

## Bootstrap: Create First Super Admin

### When to Use
Use this endpoint **once** during initial setup when you have no users in the database and need to create your first super admin.

### Endpoint
**POST** `http://localhost:7071/api/bootstrap/super-admin`

### Request Body

**Option A: Default Credentials (Quick Start)**
```json
{
  "BootstrapSecret": "KamanBootstrap2025!"
}
```

This creates a super admin with:
- Email: `superadmin@kaman.com`
- Password: `Kaman@2025`

**Option B: Custom Credentials**
```json
{
  "BootstrapSecret": "KamanBootstrap2025!",
  "Email": "your-email@company.com",
  "DisplayName": "Your Name",
  "Password": "YourSecurePassword123!"
}
```

### Password Requirements
- At least 8 characters long
- Contains uppercase letter
- Contains lowercase letter
- Contains number
- Contains special character (!@#$%^&*(),.?":{}|<>)

### Success Response
```json
{
  "Success": true,
  "Message": "Bootstrap completed successfully",
  "Data": {
    "UserId": 1,
    "Email": "superadmin@kaman.com",
    "DisplayName": "Super Administrator",
    "Message": "Super admin user created successfully. You can now login with these credentials.",
    "Warning": "IMPORTANT: Consider disabling or removing this bootstrap endpoint in production!"
  }
}
```

### Error Responses

**Super Admin Already Exists**
```json
{
  "Success": false,
  "Message": "Super admin user already exists. Bootstrap is only for initial setup."
}
```

**Invalid Secret**
```json
{
  "Success": false,
  "Message": "Invalid bootstrap secret"
}
```

### Security Notes
- This endpoint can only be used successfully **once** (before any super admin exists)
- Change the `BootstrapSecret` in production
- Consider removing or disabling this endpoint after initial setup

---

## Reset Super Admin Password

### When to Use
Use this endpoint for **emergency password reset** when:
- A super admin has forgotten their password
- A super admin account is locked due to failed login attempts
- You need to recover access to a super admin account

### Endpoint
**POST** `http://localhost:7071/api/admin/reset-superadmin-password`

### Request Body
```json
{
  "ResetSecret": "KamanResetSecret2025!",
  "Email": "superadmin@kaman.com",
  "NewPassword": "NewSecurePassword123!"
}
```

### Parameters
- **ResetSecret** (required): Secret key to authorize the reset
- **Email** (required): Email address of the super admin to reset
- **NewPassword** (required): New password (must meet strength requirements)

### Password Requirements
Same as bootstrap:
- At least 8 characters long
- Contains uppercase letter
- Contains lowercase letter
- Contains number
- Contains special character

### Success Response
```json
{
  "Success": true,
  "Message": "Super admin password reset successfully",
  "Data": {
    "UserId": 1,
    "Email": "superadmin@kaman.com",
    "DisplayName": "Super Administrator",
    "Message": "Password reset successfully. The account has been unlocked and failed login attempts cleared.",
    "Warning": "IMPORTANT: Keep the reset secret secure and consider changing it in production!"
  }
}
```

### What This Endpoint Does
1. ✅ Resets the password to the new one you provide
2. ✅ Unlocks the account if it was locked
3. ✅ Clears failed login attempt counter
4. ✅ Clears last failed login timestamp

### Error Responses

**Invalid Secret**
```json
{
  "Success": false,
  "Message": "Invalid reset secret"
}
```

**User Not Found or Not Super Admin**
```json
{
  "Success": false,
  "Message": "Super admin user not found with this email"
}
```

**Weak Password**
```json
{
  "Success": false,
  "Message": "Password validation failed: Password must contain at least one uppercase letter"
}
```

### Security Notes
- This endpoint bypasses normal authentication (by design for emergency access)
- **CRITICAL**: Keep the `ResetSecret` secure and share only with authorized personnel
- This endpoint only works for users with the `SUPER_ADMIN` role
- All password resets are logged for audit purposes

---

## Security Best Practices

### 1. Change Default Secrets

**Before deploying to production**, change the default secrets:

#### Bootstrap Secret
Edit `Functions/BootstrapFunction.cs` line 48:
```csharp
// Change this:
if (string.IsNullOrEmpty(request.BootstrapSecret) || request.BootstrapSecret != "KamanBootstrap2025!")

// To something strong and unique:
if (string.IsNullOrEmpty(request.BootstrapSecret) || request.BootstrapSecret != "YourVeryStrongSecretHere123!@#")
```

#### Reset Secret
Edit `Functions/ResetSuperAdminPasswordFunction.cs` line 48:
```csharp
// Change this:
if (string.IsNullOrEmpty(request.ResetSecret) || request.ResetSecret != "KamanResetSecret2025!")

// To something strong and unique:
if (string.IsNullOrEmpty(request.ResetSecret) || request.ResetSecret != "YourVeryStrongResetSecretHere456!@#")
```

### 2. Use Environment Variables for Secrets

**Better approach**: Store secrets in environment variables instead of hardcoding.

Update `local.settings.json`:
```json
{
  "Values": {
    "BootstrapSecret": "your-strong-bootstrap-secret",
    "ResetSecret": "your-strong-reset-secret"
  }
}
```

Then update the code to read from configuration:
```csharp
private readonly string _bootstrapSecret;

public BootstrapFunction(IConfiguration configuration, ...)
{
    _bootstrapSecret = configuration["BootstrapSecret"] ?? "default-secret";
}
```

### 3. Disable Bootstrap After Setup

**Option A: Delete the file**
```bash
rm Functions/BootstrapFunction.cs
dotnet build
```

**Option B: Comment out the Function attribute**
```csharp
// [Function("Bootstrap")]
public async Task<HttpResponseData> Run(...)
```

**Option C: Add additional checks**
```csharp
// Only allow in development environment
var environment = configuration["Environment"];
if (environment != "Development")
{
    return await ResponseHelper.ForbiddenResponse(req, "Bootstrap is disabled in production");
}
```

### 4. IP Whitelist (Production)

For production, consider adding IP whitelist for admin endpoints:
```csharp
var clientIp = AuthenticationHelper.GetClientIpAddress(req);
var allowedIps = new[] { "192.168.1.100", "10.0.0.50" };

if (!allowedIps.Contains(clientIp))
{
    return await ResponseHelper.ForbiddenResponse(req, "Access denied from this IP");
}
```

### 5. Rotate Secrets Regularly

Change the bootstrap and reset secrets:
- After initial setup
- Every 90 days
- Immediately if compromised
- When team members leave

### 6. Audit Logging

All admin operations are logged. Monitor logs regularly:
```bash
# View recent logs
func start --verbose

# Check for suspicious activity:
# - Multiple failed bootstrap attempts
# - Password reset attempts with wrong secret
# - Unusual IP addresses
```

### 7. Two-Person Rule

For critical operations, implement a two-person rule:
1. One person initiates the operation
2. Another person provides the secret
3. Both actions are required for success

---

## Testing the Endpoints

### Test Bootstrap (First Time Setup)

1. **Start Azure Functions**
   ```bash
   cd azure-functions-csharp
   dotnet clean && dotnet build
   func start
   ```

2. **Call Bootstrap in Postman**
   - URL: `http://localhost:7071/api/bootstrap/super-admin`
   - Method: POST
   - Body:
     ```json
     {
       "BootstrapSecret": "KamanBootstrap2025!",
       "Email": "admin@test.com",
       "Password": "TestAdmin123!"
     }
     ```

3. **Verify Success**
   - Check response is successful
   - Try logging in with the new credentials

### Test Password Reset

1. **Reset a Super Admin Password**
   - URL: `http://localhost:7071/api/admin/reset-superadmin-password`
   - Method: POST
   - Body:
     ```json
     {
       "ResetSecret": "KamanResetSecret2025!",
       "Email": "admin@test.com",
       "NewPassword": "NewTestPassword456!"
     }
     ```

2. **Verify Success**
   - Check response is successful
   - Try logging in with the new password
   - Verify old password no longer works

---

## Troubleshooting

### Bootstrap says "Super admin already exists"
- This is correct behavior - bootstrap can only be used once
- Use the login endpoint with existing credentials instead
- Or use password reset if you've forgotten the password

### "Invalid reset secret"
- Check for typos in the secret
- Ensure you're using the correct secret (case-sensitive)
- Verify the secret matches what's in the code

### "Super admin user not found"
- Verify the email address is correct
- Check that the user has the SUPER_ADMIN role:
  ```sql
  SELECT u.Email, r.RoleCode
  FROM [auth].[Users] u
  JOIN [auth].[UserRoles] ur ON u.UserId = ur.UserId
  JOIN [auth].[Roles] r ON ur.RoleId = r.RoleId
  WHERE u.Email = 'your-email@company.com'
  ```

### Database connection errors
- Verify connection string in `local.settings.json`
- Check database server is accessible
- Verify firewall rules allow connections

### Password validation fails
- Ensure password meets all requirements
- Use a password with: uppercase, lowercase, number, special character
- Minimum 8 characters

---

## Support

For issues or questions:
1. Check the logs with `func start --verbose`
2. Review TROUBLESHOOTING.md for common issues
3. Check database connectivity
4. Verify all secrets match what's in the code

Remember: These admin endpoints are powerful tools. Use them carefully and keep them secure!
