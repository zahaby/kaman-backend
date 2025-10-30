# Troubleshooting: "Generating 0 job function(s)"

This guide helps resolve the common issue where Azure Functions doesn't detect any functions.

## Quick Fix

Try these steps in order:

### 1. Clean and Rebuild

```bash
cd C:\projects\kaman-backend\azure-functions-csharp

# Clean previous build artifacts
dotnet clean

# Restore packages
dotnet restore

# Rebuild
dotnet build
```

### 2. Check Build Output

After running `dotnet build`, you should see:
```
Build succeeded.
    0 Warning(s)
    0 Error(s)
```

### 3. Start Azure Functions

```bash
func start
```

You should now see:
```
Functions:

  CreateCompany: [POST] http://localhost:7071/api/company/create
  CreateUserAndLogin: [POST] http://localhost:7071/api/user/create
  Login: [POST] http://localhost:7071/api/auth/login
  RefreshToken: [POST] http://localhost:7071/api/auth/refresh
  SetPassword: [POST] http://localhost:7071/api/user/set-password
```

## If Still Not Working

### Check 1: Verify .NET SDK Version

```bash
dotnet --version
```

Should be `8.0.x` or higher.

### Check 2: Verify Azure Functions Core Tools

```bash
func --version
```

Should be `4.x.x` or higher.

### Check 3: Delete bin and obj Folders

```bash
# Windows PowerShell
Remove-Item -Recurse -Force bin,obj

# Then rebuild
dotnet restore
dotnet build
```

### Check 4: Verify Function Files Exist

```bash
dir Functions
```

You should see:
- CreateCompanyFunction.cs
- CreateUserAndLoginFunction.cs
- LoginFunction.cs
- RefreshTokenFunction.cs
- SetPasswordFunction.cs

### Check 5: Check local.settings.json Exists

```bash
type local.settings.json
```

This file should exist and contain your configuration. If missing, copy from `local.settings.json.example`.

## Common Causes

### Cause 1: Missing ASP.NET Core Framework Reference

**Fixed in latest commit**. The .csproj now includes:
```xml
<FrameworkReference Include="Microsoft.AspNetCore.App" />
```

### Cause 2: Build Artifacts from Previous Builds

**Solution**: Clean and rebuild as shown above.

### Cause 3: Functions Not Public

All function classes and methods must be `public`. Verify:
```csharp
public class LoginFunction  // Must be public
{
    [Function("Login")]
    public async Task<HttpResponseData> Run(...)  // Must be public
    {
        // ...
    }
}
```

### Cause 4: Missing [Function] Attribute

Each function method must have the `[Function("Name")]` attribute.

### Cause 5: Wrong Worker Runtime

Check `local.settings.json`:
```json
{
  "Values": {
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated"
  }
}
```

Must be `dotnet-isolated`, NOT `dotnet`.

## Detailed Diagnostics

### Enable Verbose Logging

Start with verbose output:
```bash
func start --verbose
```

This shows detailed information about function discovery.

### Check Build Output Directory

```bash
dir bin\Debug\net8.0
```

You should see:
- `KamanAzureFunctions.dll`
- `host.json`
- `local.settings.json`
- All your function DLLs

### Verify Package Versions

Check `KamanAzureFunctions.csproj` has correct versions:
```xml
<PackageReference Include="Microsoft.Azure.Functions.Worker" Version="1.21.0" />
<PackageReference Include="Microsoft.Azure.Functions.Worker.Extensions.Http" Version="3.1.0" />
<PackageReference Include="Microsoft.Azure.Functions.Worker.Sdk" Version="1.17.0" />
```

## Still Having Issues?

### Try Creating a Test Function

Create a simple test function to verify basic setup:

**Functions/TestFunction.cs**:
```csharp
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace KamanAzureFunctions.Functions;

public class TestFunction
{
    private readonly ILogger<TestFunction> _logger;

    public TestFunction(ILogger<TestFunction> logger)
    {
        _logger = logger;
    }

    [Function("Test")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "test")] HttpRequestData req)
    {
        _logger.LogInformation("Test function called");

        var response = req.CreateResponse(System.Net.HttpStatusCode.OK);
        await response.WriteAsJsonAsync(new { message = "Test successful!" });

        return response;
    }
}
```

Rebuild and run:
```bash
dotnet build
func start
```

If this function appears, the issue is with the specific function implementations, not the overall setup.

### Check for Conflicting Ports

Make sure port 7071 isn't already in use:

**Windows PowerShell**:
```powershell
Get-NetTCPConnection -LocalPort 7071
```

If something is using it, either:
- Stop that process
- Or change the port in `host.json`

## Contact Support

If none of these solutions work, provide:

1. Output of `dotnet build`
2. Output of `func start --verbose`
3. Content of `KamanAzureFunctions.csproj`
4. Content of `local.settings.json` (redact passwords)
5. List of files in `Functions/` directory

---

**Last Updated**: Based on commit fd9f250
