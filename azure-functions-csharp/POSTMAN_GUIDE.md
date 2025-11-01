# Postman Collection for Kaman Azure Functions API

Complete guide for testing the Kaman Gift Card System API using Postman.

## Files

1. **Kaman_API_Collection.postman_collection.json** - Main API collection with all endpoints
2. **Kaman_API_Environment_Local.postman_environment.json** - Environment for local development
3. **Kaman_API_Environment_Azure.postman_environment.json** - Environment for Azure deployment

## Quick Start

### 1. Import into Postman

**Method 1: Import Files**
1. Open Postman
2. Click "Import" button in the top left
3. Drag and drop all three JSON files or click "Upload Files"
4. Click "Import"

**Method 2: Import from URL (if hosted on GitHub)**
1. Open Postman
2. Click "Import" > "Link"
3. Paste the raw GitHub URL to the collection file
4. Click "Continue" and "Import"

### 2. Select Environment

After importing, select the appropriate environment from the dropdown in the top-right corner:
- **Kaman API - Local Development** for local testing (`http://localhost:7071/api`)
- **Kaman API - Azure Production** for Azure testing

### 3. Configure Environment Variables

Before testing, update the following environment variables:

**For Local Development:**
- `baseUrl`: Should be `http://localhost:7071/api` (already set)
- `functionKey`: Leave empty for local development (function keys are optional locally)
- `userEmail`: Your super admin email (default: `superadmin@kaman.local`)
- `userPassword`: Your super admin password

**For Azure Production:**
- `baseUrl`: Replace with your actual Azure Function App URL (e.g., `https://kaman-prod.azurewebsites.net/api`)
- `functionKey`: **REQUIRED** - Get from Azure Portal ([see how](#getting-your-function-key))
- `userEmail`: Your super admin email
- `userPassword`: Your super admin password

#### Getting Your Function Key

All API endpoints require an Azure Function key sent in the `x-functions-key` header for security.

**Method 1: Azure Portal**
1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your Function App
3. Click "App keys" (under Function App settings)
4. Copy the **default** host key value
5. Paste into Postman's `functionKey` environment variable

**Method 2: Azure CLI**
```bash
az functionapp keys list \
  --name your-function-app-name \
  --resource-group kaman_group \
  --query masterKey \
  --output tsv
```

**Method 3: Collection Variable**

Alternatively, set the function key at the collection level:
1. Click on the collection name
2. Go to "Variables" tab
3. Set `functionKey` value
4. This applies to all environments

📖 **For detailed instructions, see [Function Keys Guide](./FUNCTION_KEYS_GUIDE.md)**

**To edit environment variables:**
1. Click the eye icon next to the environment dropdown
2. Click "Edit" next to the selected environment
3. Update the values in the "Current Value" column
4. Click "Save"

---

## Collection Structure

The collection is organized into the following sections:

### 1. Bootstrap

**Purpose**: Initialize the system and create the Super Admin account.

- **Bootstrap Super Admin**
  - Method: `POST`
  - Endpoint: `/bootstrap/super-admin`
  - Authentication: None required
  - Description: Creates the Super Admin account when the system is first deployed. Can only be used once.
  - Request Body:
    ```json
    {
      "password": "YourSuperAdminPassword123!"
    }
    ```

### 2. Authentication

**Purpose**: User authentication and session management.

- **Login**
  - Method: `POST`
  - Endpoint: `/auth/login`
  - Authentication: None required
  - Description: Authenticate a user and receive JWT access and refresh tokens
  - Auto-saves: `accessToken`, `refreshToken`, `userId`, `companyId`
  - Request Body:
    ```json
    {
      "email": "superadmin@kaman.local",
      "password": "YourPassword123!"
    }
    ```

- **Refresh Token**
  - Method: `POST`
  - Endpoint: `/auth/refresh`
  - Authentication: None required
  - Description: Refresh an expired access token using a valid refresh token
  - Auto-updates: `accessToken`, `refreshToken`
  - Request Body:
    ```json
    {
      "refreshToken": "{{refreshToken}}"
    }
    ```

- **Reset Super Admin Password**
  - Method: `POST`
  - Endpoint: `/auth/reset-superadmin-password`
  - Authentication: None required
  - Description: Reset the Super Admin password (recovery endpoint)
  - Request Body:
    ```json
    {
      "newPassword": "NewSuperAdminPassword123!"
    }
    ```

### 3. Company Management

**Purpose**: Manage companies in the system (Super Admin only).

- **Create Company**
  - Method: `POST`
  - Endpoint: `/company/create`
  - Authentication: Bearer token (Super Admin only)
  - Description: Create a new company with automatic wallet setup
  - Auto-saves: `companyId`, `companyCode`
  - Request Body:
    ```json
    {
      "companyCode": "ACME001",
      "name": "ACME Corporation",
      "email": "admin@acme.com",
      "phone": "+201234567890",
      "country": "Egypt",
      "address": "123 Business Street, Cairo",
      "defaultCurrency": "EGP",
      "minimumBalance": 0
    }
    ```

- **List Companies**
  - Method: `GET`
  - Endpoint: `/company/list`
  - Authentication: Bearer token (Super Admin only)
  - Description: Retrieve a list of all companies in the system
  - Returns: Array of company objects with their details

### 4. User Management

**Purpose**: Manage users within companies.

- **Create User**
  - Method: `POST`
  - Endpoint: `/user/create`
  - Authentication: Bearer token (Super Admin or Company Admin)
  - Description: Create a new user for a company with auto-generated default password
  - Auto-saves: `newUserId`, `newUserEmail`, `newUserPassword`
  - Request Body:
    ```json
    {
      "companyId": 2,
      "email": "user@company.com",
      "displayName": "John Doe",
      "roleId": 2
    }
    ```
  - Role IDs:
    - `1` - Super Admin (system-level)
    - `2` - Company Admin
    - `3` - Company User

- **Set Password**
  - Method: `POST`
  - Endpoint: `/user/set-password`
  - Authentication: Bearer token
  - Description: Set or reset a user's password
  - Permissions: Users can change their own password; Admins can change passwords for their company users
  - Request Body:
    ```json
    {
      "userId": 123,
      "newPassword": "NewSecure@Pass123"
    }
    ```

### 5. Gifts & Categories

**Purpose**: Access gift catalog and categories from Resal API.

- **List Gift Categories**
  - Method: `GET`
  - Endpoint: `/gifts/categories`
  - Authentication: Bearer token
  - Description: Get all gift categories from Resal API
  - Returns: Raw response from Resal API with category list
  - Response Format:
    ```json
    [
      {
        "id": 6,
        "name_en": "health-and-beauty",
        "name_ar": "صحة و جمال"
      }
    ]
    ```

- **List Gifts**
  - Method: `GET`
  - Endpoint: `/gifts?page=1&per_page=10&countries=1&all=false`
  - Authentication: Bearer token
  - Description: Get gifts from Resal API with pagination and filters
  - Returns: Raw response from Resal API including all fields
  - Query Parameters:
    - `page`: Page number (default: 1)
    - `per_page`: Items per page (default: 10, max: 100)
    - `countries`: Country ID filter (optional)
    - `all`: Include all items (default: false)
  - Response Format:
    ```json
    {
      "data": [
        {
          "id": 4146,
          "title_en": "Gift Name",
          "title_ar": "اسم الهدية",
          "description_en": "Description",
          "description_ar": "الوصف",
          "image": "https://...",
          "category": {
            "id": 6,
            "name_en": "category",
            "name_ar": "الفئة"
          },
          "denominations": [
            {
              "id": "uuid",
              "price": 50.0,
              "price_currency": "SAR",
              "title_en": "50 SAR",
              "title_ar": "50 ريال"
            }
          ]
        }
      ],
      "meta": {
        "total": 35,
        "per_page": 10,
        "current_page": 1,
        "last_page": 4
      }
    }
    ```

### 6. Test Workflows

**Purpose**: Complete end-to-end testing sequences.

#### Complete Onboarding Flow (8 Steps)

Tests the entire system setup from bootstrap to user management:

1. **Bootstrap System**
   - Creates Super Admin account
   - Sets up initial system access

2. **Login as Super Admin**
   - Authenticates with Super Admin credentials
   - Saves access tokens

3. **Create New Company**
   - Creates a test company with wallet
   - Saves company ID for subsequent requests

4. **List All Companies**
   - Verifies company was created
   - Shows all companies in the system

5. **Create Company User**
   - Creates a user for the test company
   - Saves user credentials

6. **Login as New User**
   - Authenticates with the newly created user
   - Verifies user can access the system

7. **Change User Password**
   - Updates the user's password from default
   - Tests password change functionality

8. **Login with New Password**
   - Verifies new password works
   - Confirms password change was successful

**How to Run:**
1. Right-click on "Complete Onboarding Flow" folder
2. Select "Run folder"
3. Click "Run Kaman API Collection"
4. Watch all 8 requests execute in sequence
5. Check the test results tab

#### Gifts API Flow (3 Steps)

Tests the gift catalog functionality:

1. **Login**
   - Authenticates to get access token
   - Required for accessing gift endpoints

2. **Get Gift Categories**
   - Retrieves all available gift categories
   - Useful for filtering gifts by category

3. **Get Gifts List**
   - Retrieves paginated gift list
   - Tests filtering by country
   - Verifies response includes all required fields

**How to Run:**
1. Right-click on "Gifts API Flow" folder
2. Select "Run folder"
3. Review the responses for each step

---

## Features

### Automatic Token Management

The collection includes smart token management:
- **After Login**: Access and refresh tokens are automatically saved to environment variables
- **Authenticated Requests**: Automatically use the saved access token
- **Token Refresh**: Automatically updates saved tokens when refreshing
- **Multi-User Testing**: Separate token variables for different user sessions

### Pre-request Scripts

- Logs request URL before each request
- Helps with debugging and tracking API calls

### Test Scripts

Each endpoint includes automatic tests that:
- ✅ Verify response status codes
- ✅ Check response structure and required fields
- ✅ Save important data to environment variables (tokens, IDs, emails, passwords)
- ✅ Log success/failure messages to console
- ✅ Validate data types and values

### Dynamic Data

Requests use Postman's dynamic variables for testing:
- `{{$randomInt}}` - Random integer for unique values
- `{{$randomFirstName}}` - Random first name
- `{{$randomLastName}}` - Random last name
- `{{$timestamp}}` - Current timestamp for unique identifiers

---

## Usage Guide

### Running Individual Requests

1. Select an environment (Local or Azure)
2. Navigate to any request in the collection
3. Review the request details (URL, headers, body)
4. Click "Send"
5. View the response in the pane below
6. Check the "Test Results" tab for automatic test results

### Running Complete Workflows

**Option 1: Using Collection Runner**
1. Navigate to "Test Workflows" folder
2. Right-click on a workflow folder
3. Select "Run folder"
4. Configure run options if needed
5. Click "Run [Workflow Name]"
6. Monitor execution and results

**Option 2: Manual Sequential Execution**
1. Open a workflow folder
2. Execute each request in numbered order
3. Verify results before proceeding to next request
4. Check environment variables are populated correctly

### Viewing Detailed Logs

1. Open Postman Console: `View > Show Postman Console` or `Alt+Ctrl+C`
2. View detailed logs for:
   - Request URLs
   - Response status codes
   - Test results
   - Console.log messages
   - Environment variable changes

---

## Testing Scenarios

### Scenario 1: First-Time System Setup

**Goal**: Set up the system from scratch

1. Ensure the database is initialized with tables
2. Run "Bootstrap Super Admin" to create initial admin account
3. Login as Super Admin
4. Create your first company
5. Create a company admin user
6. Test login with the new company admin

### Scenario 2: Company Onboarding

**Goal**: Onboard a new company to the system

1. Login as Super Admin
2. Create Company with company details
3. Verify company appears in List Companies
4. Create Company Admin user
5. Login as Company Admin to verify access
6. Have Company Admin change their password

### Scenario 3: Gift Catalog Access

**Goal**: Access and browse the gift catalog

1. Login as any authenticated user
2. Get Gift Categories to see available categories
3. Use List Gifts with filters:
   - Filter by country
   - Paginate through results
   - Adjust items per page
4. Review gift details including denominations

### Scenario 4: Password Management

**Goal**: Test password reset and changes

1. Login as a user
2. Use Set Password to change password
3. Logout (or wait for token expiry)
4. Login with new password to verify change
5. Test Reset Super Admin Password for Super Admin recovery

### Scenario 5: Token Lifecycle

**Goal**: Test JWT token management

1. Login to get fresh tokens
2. Make authenticated requests (tokens valid for 60 minutes)
3. Wait for access token to expire
4. Use Refresh Token endpoint with saved refresh token
5. Verify new access token works
6. Note: Refresh tokens are valid for 7 days

---

## Common Issues & Solutions

### Issue: "Unauthorized" Error

**Symptoms**: 401 status code, "Unauthorized" message

**Solutions**:
1. Ensure you've logged in first
2. Check that `accessToken` is saved in environment variables
3. Token might be expired (60-minute lifetime) - try logging in again or refreshing
4. Verify you selected the correct environment
5. Check the Authorization tab shows `Bearer {{accessToken}}`

### Issue: "Company not found" when creating user

**Symptoms**: Error message about company not existing

**Solutions**:
1. Create a company first using "Create Company"
2. Ensure `companyId` environment variable is set correctly
3. Verify the company ID exists in the database
4. Check that you're not using a deleted company ID

### Issue: "Insufficient permissions"

**Symptoms**: 403 Forbidden, permission denied messages

**Solutions**:
1. Verify you're logged in with the correct role:
   - Super Admin can access all endpoints
   - Company Admin can only manage their own company
2. Check the user's role in the database
3. Ensure you're not trying to access another company's resources

### Issue: "0 functions found" or Connection refused

**Symptoms**: Cannot connect to API, connection errors

**Solutions**:
1. **Local Development**:
   - Ensure Azure Functions is running: `func start`
   - Check port is 7071: `http://localhost:7071/api`
   - Verify no other service is using port 7071
   - Check local.settings.json is configured

2. **Azure Deployment**:
   - Verify function app is running in Azure Portal
   - Check function app URL is correct
   - Ensure host.json doesn't contain extensionBundle
   - Review Azure Function logs for errors

### Issue: SSL Certificate Error

**Symptoms**: Certificate trust errors in database connection

**Solutions**:
1. Update connection string to use `TrustServerCertificate=True`
2. Run the fix script: `cd deploy && ./fix-db-connection.sh`
3. Restart the function app after updating settings

### Issue: Bootstrap endpoint returns "Already exists"

**Symptoms**: Cannot create Super Admin, already exists message

**Solutions**:
1. This is expected if Super Admin already exists
2. Use the Login endpoint with existing credentials
3. If you need to reset password, use "Reset Super Admin Password" endpoint
4. To create a fresh Super Admin, clear the database first

### Issue: Gift API returns empty results

**Symptoms**: Empty data array in gifts response

**Solutions**:
1. Check Resal API credentials are configured correctly
2. Verify `ResalApiBearerToken` in app settings
3. Check country filter - try `countries=1` for default
4. Verify `all=false` parameter is set correctly
5. Check Resal API is accessible from your deployment

---

## Environment Variables Reference

| Variable | Description | Auto-populated | Example | Used By |
|----------|-------------|----------------|---------|---------|
| `baseUrl` | API base URL | No | `http://localhost:7071/api` | All requests |
| `functionKey` | Azure Function key for authorization | No | `abc123...xyz` | All requests (x-functions-key header) |
| `accessToken` | JWT access token (60 min) | Yes (after login) | `eyJhbGc...` | Authenticated endpoints |
| `refreshToken` | JWT refresh token (7 days) | Yes (after login) | `eyJhbGc...` | Refresh endpoint |
| `userId` | Current user ID | Yes (after login) | `1` | Set Password |
| `companyId` | Current/selected company ID | Yes (after company creation) | `2` | Create User |
| `companyCode` | Company code | Yes (after company creation) | `ACME001` | Reference only |
| `userEmail` | Login email | No | `superadmin@kaman.local` | Login |
| `userPassword` | Login password | No | `YourPassword123!` | Login |
| `newUserId` | Newly created user ID | Yes (after user creation) | `5` | Testing |
| `newUserEmail` | Newly created user email | Yes (after user creation) | `user@company.com` | Testing |
| `newUserPassword` | Default password for new user | Yes (after user creation) | `Kaman@2025` | Testing |
| `userAccessToken` | Separate token for multi-user testing | Yes (in workflows) | `eyJhbGc...` | Workflow testing |
| `superAdminPassword` | Bootstrap password | Yes (in bootstrap workflow) | `YourPassword123!` | Bootstrap workflow |

---

## Tips & Best Practices

### 1. Request Execution Order

**Important**: Some requests depend on previous ones. Follow this order:

1. Bootstrap (first time only)
2. Login
3. Create Company (if needed)
4. Create User (if needed)
5. Access any other endpoints

### 2. Use Test Workflows

- **Save Time**: Workflows automate multiple requests
- **Consistency**: Ensures correct execution order
- **Validation**: Built-in tests verify each step
- **Learning**: Review workflow structure to understand API flow

### 3. Monitor the Console

- Open Postman Console to see:
  - Request/response details
  - Environment variable changes
  - Custom log messages
  - Error details

### 4. Save Responses as Examples

- Successful responses: Click "Save as Example"
- Helps team members understand expected responses
- Useful for API documentation
- Reference for troubleshooting

### 5. Duplicate Requests for Testing

- Right-click any request → "Duplicate"
- Create variations with different parameters
- Test edge cases without modifying original
- Organize in separate folders

### 6. Use Collection Variables

- Collection-level variables apply to all requests
- Good for API version, common paths
- Edit via Collection → Variables tab

### 7. Environment Management

- Keep separate environments for:
  - Local development
  - Development/staging server
  - Production (read-only testing)
- Never commit environment files with credentials

### 8. Test Script Debugging

- Use `console.log()` in test scripts
- View output in Postman Console
- Helps debug test failures
- Example:
  ```javascript
  console.log("Company ID:", pm.environment.get("companyId"));
  ```

---

## API Endpoint Quick Reference

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/bootstrap/super-admin` | POST | None | Create Super Admin account |
| `/auth/login` | POST | None | User login |
| `/auth/refresh` | POST | None | Refresh access token |
| `/auth/reset-superadmin-password` | POST | None | Reset Super Admin password |
| `/company/create` | POST | Bearer | Create company (Super Admin) |
| `/company/list` | GET | Bearer | List all companies (Super Admin) |
| `/user/create` | POST | Bearer | Create user |
| `/user/set-password` | POST | Bearer | Set/reset password |
| `/gifts/categories` | GET | Bearer | List gift categories |
| `/gifts` | GET | Bearer | List gifts (paginated) |

---

## Response Format Standards

All API responses follow this structure:

### Success Response
```json
{
  "success": true,
  "data": {
    // Response data here
  },
  "message": "Optional success message"
}
```

### Error Response
```json
{
  "success": false,
  "data": null,
  "message": "Error description",
  "error": "Detailed error information"
}
```

---

## Support

### Getting Help

1. **Check Logs**: Review Postman Console and Azure Function logs
2. **Test Scripts**: Check test results tab for specific failures
3. **Environment**: Verify all required variables are set
4. **Documentation**: Review this guide and deploy.md

### Reporting Issues

When reporting issues, include:
- Request details (method, endpoint, body)
- Response received
- Expected behavior
- Environment (Local/Azure)
- Postman Console logs
- Azure Function logs (if applicable)

### Additional Resources

- [Main Project README](../README.md)
- [Deployment Guide](../deploy/deploy.md)
- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [Postman Documentation](https://learning.postman.com/)

---

**Last Updated**: 2025-11-01

**Collection Version**: 2.0 - Includes Bootstrap, Complete Auth, Company Management, User Management, and Gifts/Categories

---
