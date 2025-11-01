# Azure Function Keys Guide

This document explains how to obtain and use Azure Function keys for the Kaman API.

## Overview

All API endpoints in the Kaman system now require an **Azure Function key** sent in the `x-functions-key` header. This provides an additional security layer beyond JWT authentication.

### Security Layers

The API now has two layers of security:

1. **Function Key** (`x-functions-key` header) - Validates the request is from an authorized client
2. **JWT Token** (`Authorization: Bearer` header) - Identifies and authorizes the specific user

## Getting Function Keys

### For Local Development

When running locally with `func start`, Azure Functions runs in development mode:

#### Option 1: No Key Required (Default for Local)

By default, local development doesn't require function keys. However, if you've configured it to require keys:

#### Option 2: Get Key from Local Admin API

1. Start your function app: `func start`
2. Open your browser to: `http://localhost:7071/admin/functions/{function-name}/keys`
3. Or use the Azure Functions Core Tools:
   ```bash
   func keys list
   ```

#### Option 3: Check Local Storage

Function keys for local development are stored in:
```
azure-functions-csharp/azure-functions-csharp.csproj.user
```

### For Azure Deployment

#### Method 1: Using Azure Portal

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your Function App
3. In the left menu, click on **"Functions"**
4. Click on **"App keys"** (under Function App settings)
5. Under **"Host keys"**, you'll see the **default** key
6. Click **"Show"** to reveal the key
7. Copy the key value

**Alternative - Function-Specific Keys:**
1. In your Function App, click on **"Functions"** in the left menu
2. Select any function (e.g., "Login")
3. Click on **"Function Keys"**
4. Copy the **default** key or create a new one

#### Method 2: Using Azure CLI

```bash
# Get the default host key (works for all functions)
az functionapp keys list \
  --name your-function-app-name \
  --resource-group kaman_group \
  --query masterKey \
  --output tsv

# Or get function-specific key
az functionapp function keys list \
  --name your-function-app-name \
  --resource-group kaman_group \
  --function-name Login \
  --query default \
  --output tsv
```

#### Method 3: Using Functions Core Tools

```bash
func azure functionapp list-functions your-function-app-name --show-keys
```

## Using Function Keys

### In Postman

The Postman collection automatically handles function keys:

1. **Import the collection** if you haven't already
2. **Edit the collection variables**:
   - Click on the collection name
   - Go to the **"Variables"** tab
   - Set `functionKey` to your actual function key

3. **Or edit environment variables**:
   - Click the environment dropdown (top right)
   - Click the eye icon
   - Click **"Edit"**
   - Set `functionKey` value
   - Click **"Save"**

The collection's pre-request script will automatically add the `x-functions-key` header to all requests.

### In curl

```bash
curl -X POST "https://your-app.azurewebsites.net/api/auth/login" \
  -H "Content-Type: application/json" \
  -H "x-functions-key: your-function-key-here" \
  -d '{"email":"user@example.com","password":"password123"}'
```

### In Code

#### JavaScript/TypeScript

```javascript
const response = await fetch('https://your-app.azurewebsites.net/api/auth/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'x-functions-key': 'your-function-key-here'
  },
  body: JSON.stringify({
    email: 'user@example.com',
    password: 'password123'
  })
});
```

#### C#

```csharp
using var client = new HttpClient();
client.DefaultRequestHeaders.Add("x-functions-key", "your-function-key-here");

var response = await client.PostAsJsonAsync(
    "https://your-app.azurewebsites.net/api/auth/login",
    new { email = "user@example.com", password = "password123" }
);
```

#### Python

```python
import requests

headers = {
    'Content-Type': 'application/json',
    'x-functions-key': 'your-function-key-here'
}

response = requests.post(
    'https://your-app.azurewebsites.net/api/auth/login',
    headers=headers,
    json={'email': 'user@example.com', 'password': 'password123'}
)
```

## Key Types

Azure Functions supports different types of keys:

### Host Keys (Recommended)

- **Master Key**: Full access to all functions (use with caution)
- **Function Keys**: Can access all functions in the app
- Located in: Function App → App keys → Host keys

### Function-Specific Keys

- Only work for a specific function
- More restrictive but requires managing multiple keys
- Located in: Function App → Functions → [Function Name] → Function Keys

**Recommendation**: Use a **Host-level function key** (not the master key) for your API clients. This allows access to all endpoints with a single key while maintaining security.

## Best Practices

### 1. Key Rotation

Regularly rotate your function keys:

```bash
# Create a new function key
az functionapp keys set \
  --name your-function-app-name \
  --resource-group kaman_group \
  --key-name new-client-key \
  --key-value "your-secure-random-key"

# After updating clients, delete the old key
az functionapp keys delete \
  --name your-function-app-name \
  --resource-group kaman_group \
  --key-name old-client-key
```

### 2. Different Keys for Different Clients

Create separate function keys for different clients:

```bash
az functionapp keys set \
  --name your-function-app-name \
  --resource-group kaman_group \
  --key-name mobile-app-key \
  --key-value "random-secure-key-1"

az functionapp keys set \
  --name your-function-app-name \
  --resource-group kaman_group \
  --key-name web-app-key \
  --key-value "random-secure-key-2"
```

This allows you to revoke access for specific clients without affecting others.

### 3. Never Commit Keys to Source Control

- ❌ Don't hardcode keys in your code
- ❌ Don't commit keys to Git repositories
- ✅ Use environment variables
- ✅ Use Azure Key Vault for production
- ✅ Use Postman environment variables (don't export them)

### 4. Use HTTPS Only

Function keys provide authorization but not encryption. Always use HTTPS in production.

### 5. Monitor Key Usage

Monitor your function app logs to detect:
- Failed authentication attempts
- Unusual access patterns
- Potential key leaks

## Troubleshooting

### Issue: "Unauthorized" (401) Response

**Possible Causes**:
1. Function key is missing from request
2. Function key is incorrect
3. Function key has been deleted or expired

**Solutions**:
1. Verify the `x-functions-key` header is present
2. Get a fresh key from Azure Portal
3. Check Azure Function logs for details

### Issue: Key Not Working After Deployment

**Solution**:
After deploying, Azure may regenerate keys. Always retrieve the key from Azure Portal after deployment.

### Issue: Local Development Shows "Unauthorized"

**Solutions**:
1. For local development, you can disable function key requirements:
   - Set `AzureWebJobsSecretStorageType` to `files` in `local.settings.json`
   - Function keys are optional in local development by default

2. Or get the local function key:
   ```bash
   func keys list
   ```

## Security Considerations

### Advantages of Function Keys

1. **Defense in Depth**: Multiple layers of security
2. **Client Authentication**: Validates requests are from authorized applications
3. **Easy Rotation**: Can rotate keys without code changes
4. **Access Control**: Different keys for different clients

### Limitations

1. **Not User Authentication**: Function keys authenticate the client app, not individual users
2. **Shared Secret**: All clients with the same key have the same access
3. **No Expiration**: Keys don't expire automatically (must rotate manually)

### When to Use Each Auth Layer

| Scenario | Function Key | JWT Token |
|----------|--------------|-----------|
| Validate client app | ✅ Required | ❌ Not needed |
| Identify specific user | ❌ Can't identify users | ✅ Required |
| Protect against unauthorized apps | ✅ Yes | ❌ No |
| Protect against unauthorized users | ❌ No | ✅ Yes |
| Rate limiting per client | ✅ Can use different keys | ❌ No |
| Rate limiting per user | ❌ No | ✅ Can use user ID |

## FAQ

### Q: Do I need both function key and JWT token?

**A**: Yes, for authenticated endpoints:
- `x-functions-key` - Proves the request is from an authorized application
- `Authorization: Bearer {token}` - Proves which user is making the request

Endpoints like Bootstrap, Login, and Refresh Token only need the function key.

### Q: Can I use the same function key for local and Azure?

**A**: No, local and Azure have different keys. Use Postman environments to manage different keys for different deployments.

### Q: How long are function keys?

**A**: Function keys are typically 52 characters long and are securely generated by Azure.

### Q: Can I create custom function keys?

**A**: Yes, using Azure CLI or Portal you can create custom-named keys, but Azure generates the key value for security.

### Q: What happens if someone gets my function key?

**A**:
1. Immediately rotate the key in Azure Portal
2. Review access logs for suspicious activity
3. Update all legitimate clients with the new key
4. Consider using different keys for different clients

## Additional Resources

- [Azure Functions Security](https://docs.microsoft.com/en-us/azure/azure-functions/security-concepts)
- [Function Access Keys](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-http-webhook-trigger#authorization-keys)
- [Azure Key Vault Integration](https://docs.microsoft.com/en-us/azure/azure-functions/functions-identity-based-connections)

---

**Last Updated**: 2025-11-01
