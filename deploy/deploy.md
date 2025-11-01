# Kaman Azure Functions Deployment Guide

Complete guide for deploying the Kaman Gift Card System to Azure.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Configuration](#configuration)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

---

## Prerequisites

### Required Tools

1. **Azure CLI** - [Install Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
   ```bash
   az --version
   ```

2. **Azure Functions Core Tools** - [Install Guide](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)
   ```bash
   func --version
   ```

3. **.NET 8 SDK** - [Download](https://dotnet.microsoft.com/download/dotnet/8.0)
   ```bash
   dotnet --version
   ```

### Required Information

Before deploying, gather the following information:

- **Azure Subscription ID**
- **SQL Server Details**:
  - Server: `your-server.database.windows.net`
  - Database Name: `KamanDB`
  - Username
  - Password
- **Resal API Credentials**:
  - API Base URL: `https://glee-sandbox.resal.me/api/v1/`
  - Bearer Token
- **JWT Secrets** (minimum 32 characters each):
  - JWT Secret for access tokens
  - JWT Refresh Secret for refresh tokens

---

## Quick Start

### Option 1: Using the Deployment Script (Recommended)

1. **Configure the script**:
   ```bash
   cd deploy
   cp deploy.sh my-deploy.sh
   chmod +x my-deploy.sh
   ```

2. **Edit `my-deploy.sh`** and update the configuration section with your values:
   ```bash
   nano my-deploy.sh
   # Update all variables in the "Configuration" section
   ```

3. **Run the deployment**:
   ```bash
   ./my-deploy.sh
   ```

### Option 2: Manual Deployment

Follow the [Step-by-Step Deployment](#step-by-step-deployment) section below.

---

## Step-by-Step Deployment

### 1. Login to Azure

```bash
az login
```

If you have multiple subscriptions, list and select the correct one:

```bash
# List all subscriptions
az account list --output table

# Set the subscription
az account set --subscription "YOUR-SUBSCRIPTION-ID"

# Verify current subscription
az account show --output table
```

### 2. Set Configuration Variables

```bash
# Basic Configuration
RESOURCE_GROUP="kaman_group"
LOCATION="eastus"
FUNCTION_APP="kaman-prod"  # Must be globally unique
STORAGE_ACCOUNT="kamanstorage$(date +%s)"  # Must be globally unique

# Database Configuration
SQL_SERVER="your-sql-server.database.windows.net"
SQL_DATABASE="KamanDB"
SQL_USER="your-sql-username"
SQL_PASSWORD="your-sql-password"

# Resal API Configuration
RESAL_API_URL="https://glee-sandbox.resal.me/api/v1/"
RESAL_BEARER_TOKEN="your-resal-bearer-token"

# JWT Configuration (32+ characters each)
JWT_SECRET="your-super-secret-jwt-key-min-32-chars-long"
JWT_REFRESH_SECRET="your-super-secret-refresh-key-min-32-chars-long"
```

### 3. Create Resource Group

```bash
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

**Expected Output**:
```json
{
  "id": "/subscriptions/.../resourceGroups/kaman_group",
  "location": "eastus",
  "name": "kaman_group",
  "properties": {
    "provisioningState": "Succeeded"
  }
}
```

### 4. Create Storage Account

Azure Functions requires a storage account for internal operations:

```bash
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2
```

**Note**: Storage account names must be:
- 3-24 characters
- Lowercase letters and numbers only
- Globally unique across all Azure

### 5. Create Function App

```bash
az functionapp create \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --storage-account $STORAGE_ACCOUNT \
  --consumption-plan-location $LOCATION \
  --runtime dotnet-isolated \
  --runtime-version 8 \
  --functions-version 4 \
  --os-type Windows
```

**Note**: Function app names must be:
- Globally unique across all Azure
- DNS-compatible (letters, numbers, hyphens)

### 6. Configure Application Settings

Build the connection string:

```bash
DB_CONNECTION_STRING="Server=$SQL_SERVER;Database=$SQL_DATABASE;User Id=$SQL_USER;Password=$SQL_PASSWORD;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;"
```

Set all application settings:

```bash
az functionapp config appsettings set \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --settings \
    "DbConnectionString=$DB_CONNECTION_STRING" \
    "JwtSecret=$JWT_SECRET" \
    "JwtRefreshSecret=$JWT_REFRESH_SECRET" \
    "JwtExpiresInMinutes=60" \
    "JwtRefreshExpiresInDays=7" \
    "DefaultPassword=Kaman@2025" \
    "ResalApiBaseUrl=$RESAL_API_URL" \
    "ResalApiBearerToken=$RESAL_BEARER_TOKEN"
```

### 7. Enable CORS (Optional)

If you'll be calling the API from a web browser:

```bash
# Allow all origins (development only)
az functionapp cors add \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --allowed-origins "*"

# For production, specify exact origins:
az functionapp cors add \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --allowed-origins "https://yourdomain.com"
```

### 8. Deploy the Code

Navigate to the project directory and deploy:

```bash
cd ../azure-functions-csharp
func azure functionapp publish $FUNCTION_APP --force
```

**Expected Output**:
```
Getting site publishing info...
Creating archive for current directory...
Uploading X.XX MB
Upload completed successfully.
Deployment completed successfully.
Syncing triggers...

Functions in kaman-prod:
    Bootstrap - [httpTrigger]
        Invoke url: https://kaman-prod.azurewebsites.net/api/bootstrap/super-admin
    CreateCompany - [httpTrigger]
        Invoke url: https://kaman-prod.azurewebsites.net/api/company/create
    ...
```

---

## Configuration

### Required App Settings

| Setting | Description | Example |
|---------|-------------|---------|
| `DbConnectionString` | SQL Server connection string | `Server=...;Database=...` |
| `JwtSecret` | Secret for signing access tokens (32+ chars) | `your-secret-key-32-chars-min` |
| `JwtRefreshSecret` | Secret for signing refresh tokens (32+ chars) | `your-refresh-secret-32-chars` |
| `JwtExpiresInMinutes` | Access token lifetime in minutes | `60` |
| `JwtRefreshExpiresInDays` | Refresh token lifetime in days | `7` |
| `DefaultPassword` | Default password for new users | `Kaman@2025` |
| `ResalApiBaseUrl` | Resal API base URL | `https://glee-sandbox.resal.me/api/v1/` |
| `ResalApiBearerToken` | Resal API authentication token | `your-bearer-token` |

### Viewing Current Settings

```bash
az functionapp config appsettings list \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --output table
```

### Updating a Single Setting

```bash
az functionapp config appsettings set \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --settings "SettingName=NewValue"
```

---

## Verification

### 1. List Deployed Functions

```bash
az functionapp function list \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --output table
```

### 2. Get Function App URL

```bash
az functionapp show \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --query defaultHostName \
  --output tsv
```

### 3. Test the API

```bash
# Get the URL
FUNCTION_URL="https://$(az functionapp show --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --query defaultHostName --output tsv)"

# Test bootstrap endpoint
curl -X POST "$FUNCTION_URL/api/bootstrap/super-admin" \
  -H "Content-Type: application/json" \
  -d '{"password":"YourSuperAdminPassword123!"}'
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "message": "Super Admin account created successfully"
  }
}
```

### 4. View Live Logs

```bash
func azure functionapp logstream $FUNCTION_APP
```

Or using Azure CLI:

```bash
az webapp log tail \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP
```

---

## Troubleshooting

### Issue: "0 functions found" after deployment

**Cause**: Incompatible `extensionBundle` in `host.json` (already fixed in this repo)

**Solution**: Ensure `host.json` does not contain `extensionBundle` section. .NET isolated worker functions get extensions from NuGet packages.

### Issue: "Website with given name already exists"

**Cause**: Function app name is globally reserved or in soft-delete state

**Solutions**:
1. Use a different name:
   ```bash
   FUNCTION_APP="kaman-prod-$(date +%s)"
   ```

2. Delete existing app:
   ```bash
   az functionapp delete --name kaman --resource-group old-resource-group
   ```

### Issue: Database connection errors

**Check**:
1. SQL Server firewall rules allow Azure services
2. Database credentials are correct
3. Connection string is properly formatted

**Test connection**:
```bash
# Install sqlcmd if not available
# Test connection
sqlcmd -S $SQL_SERVER -d $SQL_DATABASE -U $SQL_USER -P $SQL_PASSWORD -Q "SELECT @@VERSION"
```

### Issue: Sync triggers error

**Solutions**:
1. Restart the function app:
   ```bash
   az functionapp restart --name $FUNCTION_APP --resource-group $RESOURCE_GROUP
   ```

2. Manually sync triggers:
   ```bash
   az rest --method post --uri "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/sites/$FUNCTION_APP/syncfunctiontriggers?api-version=2022-03-01"
   ```

### Issue: 500 Internal Server Error

**Check logs**:
```bash
func azure functionapp logstream $FUNCTION_APP
```

**Common causes**:
- Missing app settings
- Database connection failure
- Invalid JWT secrets
- Resal API credentials incorrect

---

## Cleanup

### Delete Everything

```bash
# Delete the entire resource group (this deletes everything inside)
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

### Delete Only Function App

```bash
# Keep resource group and storage, delete only function app
az functionapp delete \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP
```

---

## API Endpoints

After successful deployment, your API will have these endpoints:

### Bootstrap
- `POST /api/bootstrap/super-admin` - Create super admin account

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/reset-superadmin-password` - Reset super admin password

### Company Management
- `POST /api/company/create` - Create new company (Super Admin only)
- `GET /api/company/list` - List all companies (Super Admin only)

### User Management
- `POST /api/user/create` - Create new user
- `POST /api/user/set-password` - Set/reset user password

### Gifts & Categories
- `GET /api/gifts/categories` - List all gift categories
- `GET /api/gifts?page=1&per_page=10&countries=1&all=false` - List gifts with pagination

---

## Additional Resources

- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [.NET Isolated Worker Guide](https://docs.microsoft.com/en-us/azure/azure-functions/dotnet-isolated-process-guide)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [Postman Collection](../azure-functions-csharp/Kaman_API_Collection.postman_collection.json)

---

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review Azure Function logs: `func azure functionapp logstream $FUNCTION_APP`
3. Check Azure Portal for detailed error messages

---

**Last Updated**: 2025-11-01
