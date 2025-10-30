# Database Connection Configuration

## Connection String Format

The application uses SQL Server with the following connection string format:

```
Server=15.237.228.106;Database=KamanDb;User Id=sa;Password=YOUR_PASSWORD;Encrypt=True;TrustServerCertificate=True;
```

## Configuration Files

### local.settings.json
This file contains your actual database credentials and is **NOT committed to git** (it's in .gitignore).

**Location**: `azure-functions-csharp/local.settings.json`

**Update the following settings**:
```json
{
  "Values": {
    "DbConnectionString": "Server=15.237.228.106;Database=KamanDb;User Id=sa;Password=$G@hez@2030$;Encrypt=True;TrustServerCertificate=True;",
    "JwtSecret": "your-super-secret-jwt-key-change-this-in-production-minimum-32-characters",
    "JwtRefreshSecret": "your-super-secret-refresh-token-key-change-this-in-production",
    "DefaultPassword": "Kaman@2025"
  }
}
```

### Connection String Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| Server | 15.237.228.106 | SQL Server IP address |
| Database | KamanDb | Database name |
| User Id | sa | SQL Server username |
| Password | $G@hez@2030$ | SQL Server password |
| Encrypt | True | Enable encryption |
| TrustServerCertificate | True | Trust self-signed certificates |

## Security Notes

1. **Never commit** `local.settings.json` to git
2. The connection string contains sensitive credentials
3. For production, use Azure Key Vault or Managed Identity
4. Change default JWT secrets before deployment

## Testing Connection

After configuring, test the connection by:

1. Start the Azure Functions:
   ```bash
   cd azure-functions-csharp
   func start
   ```

2. Use Postman to test the Login endpoint:
   ```
   POST http://localhost:7071/api/auth/login
   ```

If you see connection errors, check:
- SQL Server is accessible from your machine
- Firewall rules allow connections to port 1433
- Credentials are correct
- Database exists

## Azure Deployment

For Azure deployment, configure application settings in Azure Portal:

1. Go to your Function App
2. Navigate to Configuration > Application Settings
3. Add the connection string as `DbConnectionString`
4. Add JWT secrets
5. Save and restart the function app

## Environment Variables for Postman

Update Postman environment variables to match your super admin credentials:

```json
{
  "userEmail": "superadmin@kaman.local",
  "userPassword": "your-actual-password"
}
```

See `POSTMAN_GUIDE.md` for more details on configuring Postman.
