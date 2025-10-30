# Quick Start Guide - Kaman Azure Functions API

## 🆕 New Laptop Setup (Fresh Installation)

If you're setting up on a new laptop without any development tools installed, follow this section first. Otherwise, skip to [Prerequisites](#prerequisites).

### Step 1: Install .NET 8.0 SDK

#### Windows

1. **Download .NET 8.0 SDK**
   - Visit: https://dotnet.microsoft.com/download/dotnet/8.0
   - Click **Download .NET SDK x64** (or ARM64 for ARM processors)
   - Run the downloaded installer (e.g., `dotnet-sdk-8.0.xxx-win-x64.exe`)
   - Follow the installation wizard (default settings are fine)

2. **Verify Installation**
   ```powershell
   # Open PowerShell or Command Prompt
   dotnet --version
   ```
   Expected output: `8.0.xxx`

#### macOS

1. **Option A: Using Homebrew (Recommended)**
   ```bash
   # Install Homebrew if not installed
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

   # Install .NET SDK
   brew install --cask dotnet-sdk
   ```

2. **Option B: Direct Download**
   - Visit: https://dotnet.microsoft.com/download/dotnet/8.0
   - Download **.NET SDK** for macOS (choose Intel or Apple Silicon)
   - Open the `.pkg` file and follow the installer

3. **Verify Installation**
   ```bash
   dotnet --version
   ```

#### Linux (Ubuntu/Debian)

```bash
# Add Microsoft package repository
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Update package list
sudo apt-get update

# Install .NET SDK
sudo apt-get install -y dotnet-sdk-8.0

# Verify installation
dotnet --version
```

For other Linux distributions, see: https://learn.microsoft.com/en-us/dotnet/core/install/linux

---

### Step 2: Install Azure Functions Core Tools

#### Windows

**Option A: Using Windows Package Manager (winget)**
```powershell
winget install Microsoft.Azure.FunctionsCoreTools
```

**Option B: Using Chocolatey**
```powershell
# Install Chocolatey if not installed
# See: https://chocolatey.org/install

# Install Azure Functions Core Tools
choco install azure-functions-core-tools
```

**Option C: Using npm (Node.js required)**
```powershell
npm install -g azure-functions-core-tools@4 --unsafe-perm true
```

**Option D: Direct Download**
- Download from: https://github.com/Azure/azure-functions-core-tools/releases
- Extract and add to PATH

#### macOS

**Option A: Using Homebrew (Recommended)**
```bash
brew tap azure/functions
brew install azure-functions-core-tools@4
```

**Option B: Using npm**
```bash
npm install -g azure-functions-core-tools@4 --unsafe-perm true
```

#### Linux

**Using npm (Recommended)**
```bash
# Install Node.js and npm if not installed
sudo apt-get install -y nodejs npm

# Install Azure Functions Core Tools
sudo npm install -g azure-functions-core-tools@4 --unsafe-perm true
```

**Verify Installation (All Platforms)**
```bash
func --version
```
Expected output: `4.x.xxxx`

---

### Step 3: Install Postman

#### Windows

1. **Download Postman**
   - Visit: https://www.postman.com/downloads/
   - Click **Download** for Windows (64-bit)
   - Run the installer: `Postman-win64-Setup.exe`

2. **Alternative: Using winget**
   ```powershell
   winget install Postman.Postman
   ```

#### macOS

1. **Download Postman**
   - Visit: https://www.postman.com/downloads/
   - Download for macOS (Intel or Apple Silicon)
   - Open the `.zip` file and drag Postman to Applications

2. **Alternative: Using Homebrew**
   ```bash
   brew install --cask postman
   ```

#### Linux

```bash
# Download and install
wget https://dl.pstmn.io/download/latest/linux64 -O postman-linux-x64.tar.gz
sudo tar -xzf postman-linux-x64.tar.gz -C /opt
sudo ln -s /opt/Postman/Postman /usr/bin/postman

# Create desktop entry
cat > ~/.local/share/applications/postman.desktop <<EOL
[Desktop Entry]
Name=Postman
Exec=/opt/Postman/Postman
Icon=/opt/Postman/app/resources/app/assets/icon.png
Type=Application
Categories=Development;
EOL
```

**Alternative: Using Snap**
```bash
sudo snap install postman
```

---

### Step 4: Install Git (if not installed)

#### Windows
```powershell
winget install Git.Git
```
Or download from: https://git-scm.com/download/win

#### macOS
```bash
# Git is usually pre-installed, but you can update via Homebrew
brew install git
```

#### Linux
```bash
sudo apt-get install git
```

---

### Step 5: Install Code Editor (Optional but Recommended)

#### Visual Studio Code

**Windows**
```powershell
winget install Microsoft.VisualStudioCode
```

**macOS**
```bash
brew install --cask visual-studio-code
```

**Linux**
```bash
sudo snap install code --classic
```

**Recommended Extensions for VS Code:**
- C# (Microsoft)
- Azure Functions
- REST Client
- GitLens

#### Visual Studio 2022 (Windows - Full IDE)
- Download from: https://visualstudio.microsoft.com/downloads/
- Install **ASP.NET and web development** workload
- Install **Azure development** workload

#### JetBrains Rider (Cross-platform, Paid)
- Download from: https://www.jetbrains.com/rider/

---

### Step 6: Install Database Tools (Optional)

#### Azure Data Studio (Cross-platform, Free)
- Download from: https://docs.microsoft.com/en-us/sql/azure-data-studio/download
- Useful for querying the SQL Server database

#### SQL Server Management Studio (Windows only)
- Download from: https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms

---

### Step 7: Clone the Repository

```bash
# Navigate to your projects directory
cd ~/projects  # or C:\projects on Windows

# Clone the repository
git clone https://github.com/zahaby/kaman-backend.git

# Navigate to the project
cd kaman-backend/azure-functions-csharp
```

---

### Step 8: Verify All Installations

```bash
# Check .NET
dotnet --version
# Expected: 8.0.xxx

# Check Azure Functions Core Tools
func --version
# Expected: 4.x.xxxx

# Check Git
git --version
# Expected: git version 2.x.x

# Check Node.js (if you installed via npm)
node --version
# Expected: v18.x.x or higher
```

---

### ✅ Installation Complete!

Your laptop is now ready for development. Proceed to the [Prerequisites](#prerequisites) section below to continue with project setup.

---

## Prerequisites

- [x] .NET 8.0 SDK installed
- [x] Azure Functions Core Tools v4
- [x] Database credentials provided
- [x] Postman installed (for testing)

## Step-by-Step Setup

### 1. Verify Prerequisites

```bash
# Check .NET version
dotnet --version
# Should show 8.0.x

# Check Azure Functions Core Tools
func --version
# Should show 4.x.x
```

### 2. Navigate to Project Directory

```bash
cd azure-functions-csharp
```

### 3. Configuration is Already Done! ✓

Your `local.settings.json` has been configured with:
- ✓ Database connection string (15.237.228.106)
- ✓ JWT secrets
- ✓ Default password (Kaman@2025)

**No additional configuration needed!**

### 4. Restore NuGet Packages

```bash
dotnet restore
```

Expected output:
```
Restoring packages for KamanAzureFunctions.csproj...
  Determining projects to restore...
  Restored KamanAzureFunctions.csproj (in X ms).
```

### 5. Build the Project

```bash
dotnet build
```

Expected output:
```
Build succeeded.
    0 Warning(s)
    0 Error(s)
```

### 6. Start Azure Functions

```bash
func start
```

Expected output:
```
Azure Functions Core Tools
Core Tools Version: 4.x.x
Function Runtime Version: 4.x.x

Functions:

  CreateCompany: [POST] http://localhost:7071/api/company/create
  CreateUserAndLogin: [POST] http://localhost:7071/api/user/create
  Login: [POST] http://localhost:7071/api/auth/login
  RefreshToken: [POST] http://localhost:7071/api/auth/refresh
  SetPassword: [POST] http://localhost:7071/api/user/set-password

For detailed output, run func with --verbose flag.
```

**✅ If you see this, your API is running!**

### 7. Test with Postman

#### Import Collection

1. Open Postman
2. Click **Import** button
3. Drag and drop these files:
   - `Kaman_API_Collection.postman_collection.json`
   - `Kaman_API_Environment_Local.postman_environment.json`

#### Configure Super Admin Credentials

1. Select **Kaman API - Local Development** environment (top-right dropdown)
2. Click the **eye icon** next to the environment
3. Click **Edit**
4. Update these values:
   - `userEmail`: Your super admin email (e.g., `superadmin@kaman.local`)
   - `userPassword`: Your super admin password
5. Click **Save**

#### Run First Test

1. Navigate to **Authentication > Login**
2. Click **Send**
3. ✅ You should see:
   ```json
   {
     "success": true,
     "message": "Login successful",
     "data": {
       "user": { ... },
       "authentication": {
         "accessToken": "eyJ...",
         "refreshToken": "eyJ...",
         ...
       }
     }
   }
   ```

#### Run Complete Workflow

1. Navigate to **Test Workflows** folder
2. Right-click the folder
3. Select **Run folder**
4. Click **Run Kaman API Collection**
5. Watch all 6 tests run automatically!

Expected results:
```
✓ 1. Login as Super Admin
✓ 2. Create New Company
✓ 3. Create Company User
✓ 4. Login as New User
✓ 5. Change User Password
✓ 6. Login with New Password

6/6 tests passed
```

## Troubleshooting

### Issue: "Cannot connect to SQL Server"

**Check:**
```bash
# Test if you can reach the server
ping 15.237.228.106

# Check if port 1433 is open
telnet 15.237.228.106 1433
```

**Solution:** Ensure your firewall allows outbound connections to SQL Server port 1433

### Issue: "Invalid email or password" when logging in

**Possible causes:**
1. Super admin user doesn't exist in database
2. Password is incorrect
3. User account is locked

**Solution:** Verify the super admin credentials in your database or create one using SQL:

```sql
-- Check if super admin exists
SELECT * FROM [auth].[Users]
WHERE Email = 'superadmin@kaman.local';

-- Check user roles
SELECT u.Email, r.Name as Role
FROM [auth].[Users] u
JOIN [auth].[UserRoles] ur ON u.UserId = ur.UserId
JOIN [auth].[Roles] r ON r.RoleId = ur.RoleId
WHERE u.Email = 'superadmin@kaman.local';
```

### Issue: "Tokens are null or undefined" in Postman

**Solution:**
1. Check the **Console** in Postman (View > Show Postman Console)
2. Verify the test scripts ran successfully
3. Manually check the environment variables (eye icon)

### Issue: Build errors

**Solution:**
```bash
# Clean and rebuild
dotnet clean
dotnet restore
dotnet build
```

## Quick Test Commands

### Test Login with cURL

```bash
curl -X POST http://localhost:7071/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "superadmin@kaman.local",
    "password": "YourPassword123!"
  }'
```

### Test Create Company (replace TOKEN)

```bash
curl -X POST http://localhost:7071/api/company/create \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "companyCode": "TEST001",
    "name": "Test Company",
    "email": "test@company.com",
    "defaultCurrency": "EGP"
  }'
```

## Next Steps

After successful setup:

1. ✅ **Test all endpoints** using Postman collection
2. ✅ **Create test companies and users** for development
3. ✅ **Review the API documentation** in README.md
4. ✅ **Integrate with Flutter app** using the base URL `http://localhost:7071/api`

## Connection Details Summary

| Setting | Value |
|---------|-------|
| API Base URL | http://localhost:7071/api |
| Database Server | 15.237.228.106 |
| Database Name | KamanDb |
| Default Password | Kaman@2025 |
| JWT Expiration | 60 minutes |
| Refresh Token Expiration | 7 days |

## Support Files

- `README.md` - Complete documentation
- `POSTMAN_GUIDE.md` - Detailed Postman usage guide
- `DATABASE_CONFIG.md` - Database configuration details
- `QUICK_START.md` - This file

## Getting Help

If you encounter issues:

1. Check the Azure Functions console output for errors
2. Review the Postman Console (View > Show Postman Console)
3. Check database connectivity
4. Verify all configuration values in `local.settings.json`

---

**You're all set!** 🚀 Start testing your API endpoints with Postman.
