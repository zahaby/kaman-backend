# Kaman Azure Functions Middleware (C#)

This is the middleware layer built with Azure Functions using C# and .NET 8 for the Kaman Gift Card System. It provides REST API endpoints to be consumed by the Flutter mobile application.

## Features

- **Company Management**: Create companies with automatic wallet setup
- **User Management**: Create and manage company users
- **Authentication**: JWT-based authentication with access and refresh tokens
- **Password Management**: Set/reset passwords with strength validation
- **Security**: Role-based access control (RBAC), login attempt tracking, account locking
- **Database**: SQL Server integration using Dapper with comprehensive error handling

## Prerequisites

- .NET 8.0 SDK
- Azure Functions Core Tools v4
- SQL Server (Azure SQL Database or local instance)
- Visual Studio 2022 or Visual Studio Code (optional)

## Installation

1. Clone the repository and navigate to the azure-functions-csharp directory:
```bash
cd azure-functions-csharp
```

2. Restore NuGet packages:
```bash
dotnet restore
```

3. Copy `local.settings.json.example` to `local.settings.json` and configure your settings:
```bash
cp local.settings.json.example local.settings.json
```

4. Update the `local.settings.json` file with your database credentials:
```json
{
  "Values": {
    "DbConnectionString": "Server=your-server;Database=KamanDb;User Id=your-user;Password=your-password;",
    "JwtSecret": "your-super-secret-jwt-key-minimum-32-characters",
    "JwtRefreshSecret": "your-super-secret-refresh-token-key"
  }
}
```

5. Build the project:
```bash
dotnet build
```

6. Start the Azure Functions runtime:
```bash
func start
```

The API will be available at `http://localhost:7071/api`

## API Endpoints

### 1. Create Company
**Endpoint**: `POST /api/company/create`

**Authorization**: Bearer token (Super Admin only)

**Request Body**:
```json
{
  "companyCode": "ACME001",
  "name": "Acme Corporation",
  "email": "admin@acme.com",
  "phone": "+201234567890",
  "country": "Egypt",
  "address": "123 Business Street, Cairo",
  "defaultCurrency": "EGP",
  "minimumBalance": 0
}
```

**Response**:
```json
{
  "success": true,
  "message": "Company and wallet created successfully",
  "data": {
    "company": {
      "companyId": 1,
      "companyCode": "ACME001",
      "name": "Acme Corporation",
      "email": "admin@acme.com",
      "defaultCurrency": "EGP",
      "isActive": true,
      "createdAt": "2025-10-27T10:00:00.000Z"
    },
    "wallet": {
      "walletId": 1,
      "companyId": 1,
      "currency": "EGP",
      "createdAt": "2025-10-27T10:00:00.000Z"
    }
  }
}
```

### 2. List All Companies
**Endpoint**: `GET /api/company/list`

**Authorization**: Bearer token (Super Admin only)

**Query Parameters** (optional):
- `includeInactive` (boolean): Set to `true` to include inactive companies. Default is `false`.

**Example Request**:
```
GET /api/company/list
GET /api/company/list?includeInactive=true
```

**Response**:
```json
{
  "Success": true,
  "Message": "Retrieved 5 companies successfully",
  "Data": {
    "TotalCount": 5,
    "Companies": [
      {
        "CompanyId": 1,
        "CompanyCode": "ACME001",
        "Name": "Acme Corporation",
        "Email": "admin@acme.com",
        "Phone": "+201234567890",
        "Country": "Egypt",
        "Address": "123 Business Street, Cairo",
        "DefaultCurrency": "EGP",
        "MinimumBalance": 0,
        "IsActive": true,
        "CreatedAt": "2025-10-27T10:00:00.000Z"
      },
      {
        "CompanyId": 2,
        "CompanyCode": "TEST001",
        "Name": "Test Company",
        "Email": "test@company.com",
        "Phone": "+201234567891",
        "Country": "Egypt",
        "Address": "456 Test Street",
        "DefaultCurrency": "EGP",
        "MinimumBalance": 100,
        "IsActive": true,
        "CreatedAt": "2025-10-28T10:00:00.000Z"
      }
    ]
  }
}
```

### 3. Create Company User
**Endpoint**: `POST /api/user/create`

**Authorization**: Bearer token (Super Admin or Company Admin)

**Request Body**:
```json
{
  "companyId": 1,
  "email": "user@acme.com",
  "displayName": "John Doe",
  "roleId": 2
}
```

**Response**:
```json
{
  "success": true,
  "message": "User created successfully with default password",
  "data": {
    "user": {
      "userId": 1,
      "companyId": 1,
      "email": "user@acme.com",
      "displayName": "John Doe",
      "isActive": true,
      "createdAt": "2025-10-27T10:00:00.000Z"
    },
    "authentication": {
      "accessToken": "eyJhbGc...",
      "refreshToken": "eyJhbGc...",
      "expiresIn": "60m",
      "tokenType": "Bearer"
    },
    "credentials": {
      "email": "user@acme.com",
      "defaultPassword": "Kaman@2025",
      "note": "User should change this password on first login"
    }
  }
}
```

### 4. Login
**Endpoint**: `POST /api/auth/login`

**Authorization**: None (public endpoint)

**Request Body**:
```json
{
  "email": "user@acme.com",
  "password": "Kaman@2025"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "userId": 1,
      "companyId": 1,
      "email": "user@acme.com",
      "displayName": "John Doe",
      "isActive": true,
      "lastLoginAt": "2025-10-27T10:00:00.000Z"
    },
    "authentication": {
      "accessToken": "eyJhbGc...",
      "refreshToken": "eyJhbGc...",
      "expiresIn": "60m",
      "tokenType": "Bearer"
    }
  }
}
```

### 5. Set Password
**Endpoint**: `POST /api/user/set-password`

**Authorization**: Bearer token

**Request Body**:
```json
{
  "userId": 1,
  "newPassword": "NewSecure@Pass123"
}
```

**Password Requirements**:
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character

**Response**:
```json
{
  "success": true,
  "message": "Password updated successfully",
  "data": {
    "userId": 1,
    "email": "user@acme.com",
    "message": "Password has been set successfully"
  }
}
```

### 6. Refresh Token
**Endpoint**: `POST /api/auth/refresh`

**Authorization**: None (uses refresh token)

**Request Body**:
```json
{
  "refreshToken": "eyJhbGc..."
}
```

**Response**:
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "data": {
    "authentication": {
      "accessToken": "eyJhbGc...",
      "refreshToken": "eyJhbGc...",
      "expiresIn": "60m",
      "tokenType": "Bearer"
    }
  }
}
```

## Admin Endpoints

### 7. Bootstrap (Create First Super Admin)
**Endpoint**: `POST /api/bootstrap/super-admin`

**Authorization**: None (requires bootstrap secret)

**When to Use**: Only for initial setup when no super admin exists

**Request Body**:
```json
{
  "BootstrapSecret": "KamanBootstrap2025!",
  "Email": "admin@company.com",
  "DisplayName": "Administrator",
  "Password": "SecurePassword123!"
}
```

**Response**:
```json
{
  "Success": true,
  "Message": "Bootstrap completed successfully",
  "Data": {
    "UserId": 1,
    "Email": "admin@company.com",
    "DisplayName": "Administrator"
  }
}
```

**Security Note**: This endpoint can only be used once (before any super admin exists). See [BOOTSTRAP_GUIDE.md](BOOTSTRAP_GUIDE.md) for details.

### 8. Reset Super Admin Password
**Endpoint**: `POST /api/auth/reset-superadmin-password`

**Authorization**: None (requires reset secret)

**When to Use**: Emergency password reset for super admin accounts

**Request Body**:
```json
{
  "ResetSecret": "KamanResetSecret2025!",
  "Email": "admin@company.com",
  "NewPassword": "NewSecurePassword123!"
}
```

**Response**:
```json
{
  "Success": true,
  "Message": "Super admin password reset successfully",
  "Data": {
    "UserId": 1,
    "Email": "admin@company.com",
    "Message": "Password reset successfully. The account has been unlocked and failed login attempts cleared."
  }
}
```

**What it does**:
- Resets the password
- Unlocks the account
- Clears failed login attempts

**Security Note**: Keep the reset secret secure. See [ADMIN_GUIDE.md](ADMIN_GUIDE.md) for complete security guidelines.

## Authentication

All protected endpoints require a JWT access token in the Authorization header:

```
Authorization: Bearer <access_token>
```

Access tokens expire after 60 minutes (configurable). Use the refresh token endpoint to obtain a new access token.

## Role-Based Access Control

- **SUPER_ADMIN**: Full system access, can create companies and manage all users
- **COMPANY_ADMIN**: Can manage users within their own company

## Security Features

1. **Password Hashing**: Passwords are hashed using BCrypt with 12 work factor
2. **JWT Tokens**: Secure token-based authentication with separate access and refresh tokens
3. **Login Attempt Tracking**: Failed login attempts are logged
4. **Account Locking**: Accounts are locked after 5 failed login attempts
5. **Password Strength Validation**: Enforces strong password requirements
6. **Role-Based Access**: Fine-grained access control based on user roles

## Development

### Build
```bash
dotnet build
```

### Run locally
```bash
func start
```

### Run with watch (auto-rebuild)
```bash
dotnet watch run
```

### Clean
```bash
dotnet clean
```

## Project Structure

```
azure-functions-csharp/
├── DTOs/                       # Data Transfer Objects
│   ├── ApiResponse.cs
│   ├── CompanyDTOs.cs
│   └── UserDTOs.cs
├── Functions/                  # Azure Functions endpoints
│   ├── CreateCompanyFunction.cs
│   ├── CreateUserAndLoginFunction.cs
│   ├── LoginFunction.cs
│   ├── RefreshTokenFunction.cs
│   └── SetPasswordFunction.cs
├── Helpers/                    # Helper classes
│   ├── AuthenticationHelper.cs
│   ├── DatabaseHelper.cs
│   ├── JwtHelper.cs
│   ├── PasswordHelper.cs
│   ├── ResponseHelper.cs
│   └── ValidationHelper.cs
├── Models/                     # Database models
│   ├── Company.cs
│   ├── User.cs
│   └── Wallet.cs
├── Services/                   # Business logic layer
│   ├── CompanyService.cs
│   └── UserService.cs
├── Program.cs                  # Dependency injection configuration
├── host.json                   # Azure Functions host configuration
├── local.settings.json         # Local configuration (not in source control)
├── local.settings.json.example # Example configuration
├── KamanAzureFunctions.csproj  # Project file
└── README.md
```

## Deployment

### Azure Portal

1. Create an Azure Function App in the Azure Portal (.NET 8, Isolated)
2. Configure Application Settings with environment variables
3. Deploy using Azure Functions Core Tools:

```bash
func azure functionapp publish <function-app-name>
```

### Using Visual Studio

1. Right-click the project in Solution Explorer
2. Select "Publish"
3. Follow the wizard to deploy to Azure

### CI/CD

Configure GitHub Actions or Azure DevOps for automated deployment.

## Configuration

| Setting | Description | Default |
|---------|-------------|---------|
| `DbConnectionString` | SQL Server connection string | - |
| `JwtSecret` | Secret key for access tokens (min 32 chars) | - |
| `JwtExpiresInMinutes` | Access token expiration in minutes | 60 |
| `JwtRefreshSecret` | Secret key for refresh tokens | - |
| `JwtRefreshExpiresInDays` | Refresh token expiration in days | 7 |
| `DefaultPassword` | Default password for new users | Kaman@2025 |
| `Environment` | Environment name | Development |

## NuGet Packages

- **Microsoft.Azure.Functions.Worker** - Azure Functions isolated worker
- **Microsoft.Data.SqlClient** - SQL Server connectivity
- **Dapper** - Lightweight ORM
- **BCrypt.Net-Next** - Password hashing
- **System.IdentityModel.Tokens.Jwt** - JWT token generation/validation
- **FluentValidation** - Input validation
- **Newtonsoft.Json** - JSON serialization

## Error Handling

All endpoints return a consistent error response format:

```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message"
}
```

Common HTTP status codes:
- `200`: Success
- `201`: Created
- `400`: Bad Request (validation errors)
- `401`: Unauthorized (authentication required)
- `403`: Forbidden (insufficient permissions)
- `404`: Not Found
- `500`: Internal Server Error

## Testing

### Using cURL

```bash
# Login
curl -X POST http://localhost:7071/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@acme.com","password":"Kaman@2025"}'

# Create Company (requires token)
curl -X POST http://localhost:7071/api/company/create \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"companyCode":"TEST001","name":"Test Company","email":"test@example.com"}'
```

### Using Postman

1. Import the API collection
2. Set environment variables for base URL and tokens
3. Test endpoints sequentially

## License

Proprietary - Kaman Gift Card System

## Support

For questions or issues, contact the development team.
