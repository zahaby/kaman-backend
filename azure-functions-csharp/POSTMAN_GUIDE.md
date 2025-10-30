# Postman Collection for Kaman Azure Functions API

This directory contains Postman collections and environments for testing the Kaman Azure Functions API.

## Files

1. **Kaman_API_Collection.postman_collection.json** - Main API collection with all endpoints
2. **Kaman_API_Environment_Local.postman_environment.json** - Environment for local development
3. **Kaman_API_Environment_Azure.postman_environment.json** - Environment for Azure deployment

## Importing into Postman

### Method 1: Import Files

1. Open Postman
2. Click "Import" button in the top left
3. Drag and drop all three JSON files or click "Upload Files"
4. Click "Import"

### Method 2: Import from URL (if hosted on GitHub)

1. Open Postman
2. Click "Import" > "Link"
3. Paste the raw GitHub URL to the collection file
4. Click "Continue" and "Import"

## Setup

### 1. Select Environment

After importing, select the appropriate environment from the dropdown in the top-right corner:
- **Kaman API - Local Development** for local testing (http://localhost:7071/api)
- **Kaman API - Azure Production** for Azure testing

### 2. Configure Environment Variables

Before testing, update the following environment variables:

#### For Local Development:
- `baseUrl`: Should be `http://localhost:7071/api` (already set)
- `userEmail`: Your super admin email (default: `superadmin@kaman.local`)
- `userPassword`: Your super admin password

#### For Azure Production:
- `baseUrl`: Replace `your-function-app` with your actual Azure Function App name
- `userEmail`: Your super admin email
- `userPassword`: Your super admin password

To edit environment variables:
1. Click the eye icon next to the environment dropdown
2. Click "Edit" next to the selected environment
3. Update the values in the "Current Value" column
4. Click "Save"

## Collection Structure

### 1. Authentication
- **Login** - Authenticate and get JWT tokens
- **Refresh Token** - Refresh expired access token

### 2. Company Management
- **Create Company** - Create new company with wallet (Super Admin only)

### 3. User Management
- **Create User** - Create company user with default password
- **Set Password** - Change user password

### 4. Test Workflows
A complete end-to-end workflow that tests:
1. Login as Super Admin
2. Create New Company
3. Create Company User
4. Login as New User
5. Change User Password
6. Login with New Password

Run these requests in sequence to test the complete flow.

## Using the Collection

### Running Individual Requests

1. Select an environment
2. Navigate to any request in the collection
3. Click "Send"
4. View the response in the response pane below

### Running the Complete Workflow

1. Navigate to "Test Workflows" folder
2. Right-click on the folder
3. Select "Run folder"
4. Click "Run Kaman API Collection" to execute all requests in sequence

### Automatic Token Management

The collection includes automatic token management:
- After successful login, access and refresh tokens are automatically saved to environment variables
- Authenticated requests automatically use the saved access token
- Token refresh automatically updates the saved tokens

## Features

### Pre-request Scripts
- Logs request URL before each request

### Test Scripts
Each endpoint includes automatic tests that:
- Verify response status codes
- Check response structure
- Save important data to environment variables (tokens, IDs, etc.)
- Log success/failure messages

### Dynamic Data
Requests use Postman's dynamic variables for testing:
- `{{$randomInt}}` - Random integer
- `{{$randomFirstName}}` - Random first name
- `{{$randomLastName}}` - Random last name
- `{{$timestamp}}` - Current timestamp

### Response Examples

Each endpoint includes example responses showing:
- Success responses with sample data
- Error responses with validation errors
- Authentication failures

## Testing Scenarios

### Scenario 1: First Time Setup
1. Login as Super Admin (Authentication > Login)
2. Create Company (Company Management > Create Company)
3. Create User for the company (User Management > Create User)
4. Test login with the new user credentials

### Scenario 2: Password Reset
1. Login as any user
2. Use Set Password to change password
3. Login again with new password

### Scenario 3: Token Refresh
1. Login to get tokens
2. Wait for access token to expire (60 minutes)
3. Use Refresh Token to get new access token
4. Make authenticated request with new token

## Common Issues

### Issue: "Unauthorized" Error
**Solution**:
- Ensure you've logged in first
- Check that the access token is saved in environment variables
- Token might be expired - try refreshing it

### Issue: "Company not found" when creating user
**Solution**:
- Create a company first
- Ensure `companyId` environment variable is set
- Check that you're using the correct company ID

### Issue: "Insufficient permissions"
**Solution**:
- Check that you're logged in with the correct role
- Super Admin can do everything
- Company Admin can only manage their own company

### Issue: Connection refused
**Solution**:
- Ensure Azure Functions is running (`func start`)
- Check that the base URL is correct
- Verify the port (default: 7071)

## Environment Variables Reference

| Variable | Description | Auto-populated | Example |
|----------|-------------|----------------|---------|
| `baseUrl` | API base URL | No | http://localhost:7071/api |
| `accessToken` | JWT access token | Yes (after login) | eyJhbGc... |
| `refreshToken` | JWT refresh token | Yes (after login) | eyJhbGc... |
| `userId` | Current user ID | Yes (after login) | 123 |
| `companyId` | Current company ID | Yes (after company creation) | 45 |
| `companyCode` | Company code | Yes (after company creation) | ACME001 |
| `userEmail` | Login email | No | user@company.com |
| `userPassword` | Login password | No | Password123! |
| `newUserId` | Newly created user ID | Yes (after user creation) | 124 |
| `newUserEmail` | Newly created user email | Yes (after user creation) | newuser@company.com |
| `newUserPassword` | New user password | Yes (after user creation) | Kaman@2025 |
| `userAccessToken` | Separate token for testing | Yes (in workflows) | eyJhbGc... |

## Tips

1. **Run requests in order**: Some requests depend on previous ones (e.g., create company before creating users)
2. **Use the Test Workflows folder**: It includes a complete end-to-end test
3. **Check the Console**: Open Postman Console (View > Show Postman Console) to see detailed logs
4. **Save responses**: Click "Save as Example" on successful responses for future reference
5. **Duplicate requests**: Right-click any request and select "Duplicate" to create variations

## Support

For issues or questions:
- Check the main README.md in the project root
- Review Azure Functions logs
- Check Postman Console for detailed error messages

## License

Proprietary - Kaman Gift Card System
