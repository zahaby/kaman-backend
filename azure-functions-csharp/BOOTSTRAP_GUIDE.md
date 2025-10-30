# Bootstrap Guide - Creating Your First Super Admin User

## Problem
You're getting "Invalid email or password" because there are no users in your database yet. You need a super admin user to create companies and other users.

## Solution: Use the Bootstrap Endpoint

I've created a special **Bootstrap endpoint** that lets you create the first super admin user without authentication.

### Step 1: Rebuild and Restart Azure Functions

```bash
cd azure-functions-csharp

# Clean and rebuild to include the new Bootstrap function
dotnet clean
dotnet build

# Start the functions
func start
```

You should now see the new Bootstrap endpoint:
```
Functions:

  Bootstrap: [POST] http://localhost:7071/api/bootstrap/super-admin
  CreateCompany: [POST] http://localhost:7071/api/company/create
  CreateUserAndLogin: [POST] http://localhost:7071/api/user/create
  Login: [POST] http://localhost:7071/api/auth/login
  RefreshToken: [POST] http://localhost:7071/api/auth/refresh
  SetPassword: [POST] http://localhost:7071/api/user/set-password
```

### Step 2: Call the Bootstrap Endpoint in Postman

**Option A: Use Default Credentials (Quick Start)**

Send a POST request to: `http://localhost:7071/api/bootstrap/super-admin`

Headers:
```
Content-Type: application/json
```

Body (JSON):
```json
{
  "BootstrapSecret": "KamanBootstrap2025!"
}
```

This will create a super admin with:
- **Email**: `superadmin@kaman.com`
- **Password**: `Kaman@2025`

**Option B: Use Custom Credentials**

Body (JSON):
```json
{
  "BootstrapSecret": "KamanBootstrap2025!",
  "Email": "your-email@company.com",
  "DisplayName": "Your Name",
  "Password": "YourSecurePassword123!"
}
```

Note: Password must meet these requirements:
- At least 8 characters long
- Contains uppercase letter
- Contains lowercase letter
- Contains number
- Contains special character (!@#$%^&*(),.?":{}|<>)

### Step 3: Expected Response

If successful, you'll get:
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
  },
  "Error": null
}
```

### Step 4: Test Login

Now try logging in with Postman:

POST to: `http://localhost:7071/api/auth/login`

Body (JSON):
```json
{
  "Email": "superadmin@kaman.com",
  "Password": "Kaman@2025"
}
```

You should get a successful response with access and refresh tokens!

### Step 5: Continue with Your Workflow

Now you can:

1. **Create a Company** (using CreateCompany endpoint with super admin token)
2. **Create Company Users** (using CreateUserAndLogin endpoint)
3. **Manage passwords**, etc.

Follow the test workflow in `POSTMAN_GUIDE.md` for the complete testing sequence.

---

## Security Notes

### IMPORTANT: Production Security

1. **The Bootstrap endpoint should ONLY be used for initial setup!**
2. **After creating your first super admin, you should:**
   - Delete the `Functions/BootstrapFunction.cs` file
   - Or comment out the `[Function("Bootstrap")]` attribute
   - Or add additional security checks (IP whitelist, stronger secret, etc.)

3. **Change the BootstrapSecret** in production:
   - Open `Functions/BootstrapFunction.cs`
   - Change `"KamanBootstrap2025!"` to a strong, unique secret
   - Store it securely and share it only with authorized personnel

4. **The bootstrap endpoint can only be used ONCE**:
   - Once a super admin exists, the endpoint will return an error
   - This prevents accidental creation of multiple super admins

---

## Troubleshooting

### "Invalid bootstrap secret"
- Make sure you're sending exactly: `"KamanBootstrap2025!"`
- Check for typos or extra spaces

### "Super admin user already exists"
- This means bootstrap was already successful
- Use the existing credentials to login
- To check existing users, run the SQL query in `setup-super-admin.sql`

### Bootstrap endpoint doesn't appear
- Make sure you ran `dotnet build` after creating the BootstrapFunction.cs file
- Restart the functions with `func start`
- Check for build errors with `dotnet build --verbosity detailed`

### Database connection errors
- Verify your connection string in `local.settings.json`
- Test database connectivity from SQL Server Management Studio or Azure Data Studio
- Check firewall rules for the database server (15.237.228.106)

### "SUPER_ADMIN role not found"
- The bootstrap endpoint automatically creates the role if it doesn't exist
- No manual intervention needed

---

## Alternative Method: Manual SQL Script

If you prefer to create the super admin directly in the database without using the API, you can use the SQL script provided in `setup-super-admin.sql`. However, you'll need to generate a BCrypt hash for the password manually.

The Bootstrap endpoint is much simpler and recommended for initial setup.
