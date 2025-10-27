# Kaman Azure Functions - API Documentation

## Overview

This document provides detailed API documentation for the Kaman Gift Card System middleware layer.

## Base URL

- **Local Development**: `http://localhost:7071/api`
- **Production**: `https://your-function-app.azurewebsites.net/api`

## Authentication

Most endpoints require JWT authentication. Include the access token in the Authorization header:

```
Authorization: Bearer <your_access_token>
```

## Common Response Format

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {
    // Response data
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error message",
  "error": "Detailed error description"
}
```

## Endpoints

---

## 1. Authentication Endpoints

### 1.1 Login

**POST** `/auth/login`

Authenticate a user and receive JWT tokens.

**Authentication**: None (public endpoint)

**Request Body**:
```json
{
  "email": "user@company.com",
  "password": "YourPassword123!"
}
```

**Success Response (200)**:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "userId": 123,
      "companyId": 45,
      "email": "user@company.com",
      "displayName": "John Doe",
      "isActive": true,
      "lastLoginAt": "2025-10-27T10:30:00.000Z"
    },
    "authentication": {
      "accessToken": "eyJhbGc...",
      "refreshToken": "eyJhbGc...",
      "expiresIn": "1h",
      "tokenType": "Bearer"
    }
  }
}
```

**Error Responses**:
- `400`: Invalid request body or validation error
- `401`: Invalid credentials or account locked
- `500`: Server error

**Example cURL**:
```bash
curl -X POST http://localhost:7071/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@company.com",
    "password": "YourPassword123!"
  }'
```

---

### 1.2 Refresh Token

**POST** `/auth/refresh`

Refresh an expired access token using a valid refresh token.

**Authentication**: None (uses refresh token)

**Request Body**:
```json
{
  "refreshToken": "eyJhbGc..."
}
```

**Success Response (200)**:
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "data": {
    "authentication": {
      "accessToken": "eyJhbGc...",
      "refreshToken": "eyJhbGc...",
      "expiresIn": "1h",
      "tokenType": "Bearer"
    }
  }
}
```

**Error Responses**:
- `400`: Invalid request body
- `401`: Invalid or expired refresh token
- `403`: User account inactive or locked
- `404`: User not found
- `500`: Server error

**Example cURL**:
```bash
curl -X POST http://localhost:7071/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "your_refresh_token_here"
  }'
```

---

## 2. Company Management

### 2.1 Create Company

**POST** `/company/create`

Create a new company with an automatically created wallet.

**Authentication**: Required (Super Admin only)

**Request Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

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

**Field Descriptions**:
- `companyCode` (required): Unique company code (3-32 chars, uppercase letters, numbers, underscores only)
- `name` (required): Company name (2-200 chars)
- `email` (required): Company email (valid email format)
- `phone` (optional): Phone number (max 64 chars)
- `country` (optional): Country name (max 64 chars)
- `address` (optional): Physical address (max 512 chars)
- `defaultCurrency` (optional): ISO currency code (3 chars, default: "EGP")
- `minimumBalance` (optional): Minimum wallet balance (default: 0)

**Success Response (201)**:
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
      "phone": "+201234567890",
      "country": "Egypt",
      "address": "123 Business Street, Cairo",
      "defaultCurrency": "EGP",
      "minimumBalance": 0,
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

**Error Responses**:
- `400`: Validation error or company already exists
- `401`: Unauthorized (no token or invalid token)
- `403`: Forbidden (not a super admin)
- `500`: Server error

**Example cURL**:
```bash
curl -X POST http://localhost:7071/api/company/create \
  -H "Authorization: Bearer your_access_token" \
  -H "Content-Type: application/json" \
  -d '{
    "companyCode": "ACME001",
    "name": "Acme Corporation",
    "email": "admin@acme.com",
    "defaultCurrency": "EGP"
  }'
```

---

## 3. User Management

### 3.1 Create User

**POST** `/user/create`

Create a new company user with a default password.

**Authentication**: Required (Super Admin or Company Admin)

**Authorization Rules**:
- Super Admins: Can create users for any company
- Company Admins: Can only create users for their own company

**Request Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body**:
```json
{
  "companyId": 1,
  "email": "user@acme.com",
  "displayName": "John Doe",
  "roleId": 2
}
```

**Field Descriptions**:
- `companyId` (required): ID of the company (positive integer)
- `email` (required): User email (valid email format, max 256 chars)
- `displayName` (required): User display name (2-128 chars)
- `roleId` (optional): Role ID (default: 2 for COMPANY_ADMIN)
  - 1: SUPER_ADMIN
  - 2: COMPANY_ADMIN

**Success Response (201)**:
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

**Error Responses**:
- `400`: Validation error, user already exists, or company inactive
- `401`: Unauthorized
- `403`: Insufficient permissions
- `404`: Company not found
- `500`: Server error

**Example cURL**:
```bash
curl -X POST http://localhost:7071/api/user/create \
  -H "Authorization: Bearer your_access_token" \
  -H "Content-Type: application/json" \
  -d '{
    "companyId": 1,
    "email": "user@acme.com",
    "displayName": "John Doe"
  }'
```

---

### 3.2 Set Password

**POST** `/user/set-password`

Set or reset a user's password.

**Authentication**: Required

**Authorization Rules**:
- Super Admins: Can reset any user's password
- Users: Can reset their own password
- Company Admins: Can reset passwords for users in their company

**Request Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body**:
```json
{
  "userId": 1,
  "newPassword": "NewSecure@Pass123"
}
```

**Field Descriptions**:
- `userId` (required): ID of the user (positive integer)
- `newPassword` (required): New password (8-128 chars)

**Password Requirements**:
- Minimum 8 characters
- At least one uppercase letter (A-Z)
- At least one lowercase letter (a-z)
- At least one number (0-9)
- At least one special character (!@#$%^&*(),.?":{}|<>)

**Success Response (200)**:
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

**Error Responses**:
- `400`: Validation error or weak password
- `401`: Unauthorized
- `403`: Insufficient permissions
- `404`: User not found
- `500`: Server error

**Example cURL**:
```bash
curl -X POST http://localhost:7071/api/user/set-password \
  -H "Authorization: Bearer your_access_token" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "newPassword": "NewSecure@Pass123"
  }'
```

---

## Security Features

### Account Locking
- After 5 consecutive failed login attempts, the account is automatically locked
- Locked accounts must be unlocked by resetting the password

### Login Attempt Logging
- All login attempts (successful and failed) are logged
- Logs include: email, user ID, IP address, user agent, timestamp, and failure reason

### Token Expiration
- Access tokens expire after 1 hour (configurable)
- Refresh tokens expire after 7 days (configurable)
- Use the refresh token endpoint to obtain new tokens

### Password Security
- Passwords are hashed using bcrypt with 12 salt rounds
- Strong password requirements enforced
- Failed login attempts tracked and limited

---

## HTTP Status Codes

| Status Code | Description |
|-------------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request (validation error) |
| 401 | Unauthorized (authentication required) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not Found |
| 500 | Internal Server Error |

---

## Rate Limiting

Currently, there is no rate limiting implemented. Consider implementing rate limiting in production using Azure API Management or a custom middleware.

---

## CORS Configuration

CORS is configured in `local.settings.json` for local development. For production, configure CORS in the Azure Portal under your Function App settings.

---

## Testing with Postman

1. Import the provided Postman collection (if available)
2. Set the `base_url` variable to your API endpoint
3. Login to get an access token
4. Set the `access_token` variable
5. Test other endpoints

---

## Flutter Integration Example

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class KamanApiClient {
  final String baseUrl = 'https://your-function-app.azurewebsites.net/api';
  String? accessToken;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      accessToken = data['data']['authentication']['accessToken'];
      return data;
    } else {
      throw Exception('Login failed');
    }
  }

  Future<Map<String, dynamic>> createUser(
    int companyId,
    String email,
    String displayName,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({
        'companyId': companyId,
        'email': email,
        'displayName': displayName,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('User creation failed');
    }
  }
}
```

---

## Troubleshooting

### Connection Issues
- Verify database connection string in environment variables
- Check firewall rules for SQL Server
- Ensure Azure Function App can access the database

### Authentication Errors
- Verify JWT_SECRET is configured correctly
- Check token expiration times
- Ensure Authorization header format is correct

### Validation Errors
- Review request body against API documentation
- Check data types and required fields
- Validate password strength requirements

---

## Support

For issues or questions, contact the development team or refer to the main README.md file.
