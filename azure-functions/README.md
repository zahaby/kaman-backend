# Kaman Azure Functions Middleware

This is the middleware layer built with Azure Functions for the Kaman Gift Card System. It provides REST API endpoints to be consumed by the Flutter mobile application.

## Features

- **Company Management**: Create companies with automatic wallet setup
- **User Management**: Create and manage company users
- **Authentication**: JWT-based authentication with access and refresh tokens
- **Password Management**: Set/reset passwords with strength validation
- **Security**: Role-based access control (RBAC), login attempt tracking, account locking
- **Database**: SQL Server integration with comprehensive error handling

## Prerequisites

- Node.js >= 18.0.0
- Azure Functions Core Tools v4
- SQL Server (Azure SQL Database or local instance)
- npm or yarn

## Installation

1. Clone the repository and navigate to the azure-functions directory:
```bash
cd azure-functions
```

2. Install dependencies:
```bash
npm install
```

3. Copy `.env.example` to `.env` and configure your environment variables:
```bash
cp .env.example .env
```

4. Update the `.env` file with your database credentials and configuration:
```env
DB_SERVER=your-sql-server.database.windows.net
DB_NAME=KamanDb
DB_USER=your-username
DB_PASSWORD=your-password
JWT_SECRET=your-super-secret-jwt-key
```

5. Build the project:
```bash
npm run build
```

6. Start the Azure Functions runtime:
```bash
npm start
```

The API will be available at `http://localhost:7071/api`

## API Endpoints

### 1. Create Company
**Endpoint**: `POST /api/company/create`

**Authorization**: Bearer token (Super Admin only)

**Description**: Creates a new company and automatically creates a wallet for the company.

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

### 2. Create Company User
**Endpoint**: `POST /api/user/create`

**Authorization**: Bearer token (Super Admin or Company Admin)

**Description**: Creates a new company user with a default password and returns login tokens.

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
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expiresIn": "1h",
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

### 3. Login
**Endpoint**: `POST /api/auth/login`

**Authorization**: None (public endpoint)

**Description**: Authenticates a user and returns JWT tokens.

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
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expiresIn": "1h",
      "tokenType": "Bearer"
    }
  }
}
```

### 4. Set Password
**Endpoint**: `POST /api/user/set-password`

**Authorization**: Bearer token

**Description**: Sets or resets a user's password. Users can reset their own password, company admins can reset passwords for users in their company, and super admins can reset any password.

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

### 5. Refresh Token
**Endpoint**: `POST /api/auth/refresh`

**Authorization**: None (uses refresh token)

**Description**: Refreshes an expired access token using a valid refresh token.

**Request Body**:
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response**:
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "data": {
    "authentication": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expiresIn": "1h",
      "tokenType": "Bearer"
    }
  }
}
```

## Authentication

All protected endpoints require a JWT access token in the Authorization header:

```
Authorization: Bearer <access_token>
```

Access tokens expire after 1 hour (configurable via `JWT_EXPIRES_IN`). Use the refresh token endpoint to obtain a new access token.

## Role-Based Access Control

- **SUPER_ADMIN**: Full system access, can create companies and manage all users
- **COMPANY_ADMIN**: Can manage users within their own company

## Security Features

1. **Password Hashing**: Passwords are hashed using bcrypt with 12 salt rounds
2. **JWT Tokens**: Secure token-based authentication with separate access and refresh tokens
3. **Login Attempt Tracking**: Failed login attempts are logged
4. **Account Locking**: Accounts are locked after 5 failed login attempts
5. **Password Strength Validation**: Enforces strong password requirements
6. **Role-Based Access**: Fine-grained access control based on user roles

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

## Development

### Build
```bash
npm run build
```

### Watch mode (auto-rebuild on changes)
```bash
npm run watch
```

### Start locally
```bash
npm start
```

## Project Structure

```
azure-functions/
├── src/
│   ├── config/          # Configuration files
│   │   ├── database.ts  # Database connection
│   │   └── env.ts       # Environment variables
│   ├── functions/       # Azure Functions endpoints
│   │   ├── createCompany.ts
│   │   ├── createUserAndLogin.ts
│   │   ├── login.ts
│   │   ├── refreshToken.ts
│   │   └── setPassword.ts
│   ├── middleware/      # Middleware functions
│   │   └── auth.ts      # Authentication middleware
│   ├── services/        # Business logic layer
│   │   ├── companyService.ts
│   │   └── userService.ts
│   ├── types/           # TypeScript type definitions
│   │   └── index.ts
│   └── utils/           # Utility functions
│       ├── jwt.ts       # JWT token utilities
│       ├── password.ts  # Password hashing & validation
│       ├── response.ts  # Response helpers
│       └── validation.ts # Input validation
├── .env.example         # Example environment variables
├── .gitignore
├── host.json           # Azure Functions host configuration
├── package.json
├── tsconfig.json       # TypeScript configuration
└── README.md
```

## Deployment

### Azure Portal

1. Create an Azure Function App in the Azure Portal
2. Configure Application Settings with environment variables
3. Deploy using Azure Functions Core Tools:

```bash
func azure functionapp publish <function-app-name>
```

### CI/CD

Configure GitHub Actions or Azure DevOps for automated deployment.

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_SERVER` | SQL Server hostname | - |
| `DB_PORT` | SQL Server port | 1433 |
| `DB_NAME` | Database name | KamanDb |
| `DB_USER` | Database username | - |
| `DB_PASSWORD` | Database password | - |
| `DB_ENCRYPT` | Enable encryption | true |
| `JWT_SECRET` | Secret key for access tokens | - |
| `JWT_EXPIRES_IN` | Access token expiration | 1h |
| `JWT_REFRESH_SECRET` | Secret key for refresh tokens | - |
| `JWT_REFRESH_EXPIRES_IN` | Refresh token expiration | 7d |
| `DEFAULT_PASSWORD` | Default password for new users | Kaman@2025 |
| `NODE_ENV` | Environment | development |

## License

Proprietary - Kaman Gift Card System

## Support

For questions or issues, contact the development team.
