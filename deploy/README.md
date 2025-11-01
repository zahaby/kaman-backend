# Deployment Scripts

This folder contains deployment scripts and documentation for the Kaman Azure Functions API.

## Files

- **deploy.md** - Complete deployment documentation and guide
- **deploy.sh** - Automated deployment script for Azure
- **.gitignore** - Protects your customized scripts from being committed

## Quick Start

### 1. Copy the Deployment Script

```bash
cp deploy.sh my-deploy.sh
chmod +x my-deploy.sh
```

### 2. Configure Your Deployment

Edit `my-deploy.sh` and update the configuration section with your actual values:

```bash
nano my-deploy.sh
```

Update these values:
- Azure subscription and resource group details
- SQL Server credentials
- Resal API credentials
- JWT secrets (must be 32+ characters each)

### 3. Run the Deployment

```bash
./my-deploy.sh
```

## Documentation

For detailed step-by-step instructions, see [deploy.md](./deploy.md).

## Security Note

⚠️ **IMPORTANT**: Never commit `my-deploy.sh` or any customized deployment scripts that contain your credentials. The `.gitignore` file is configured to protect these files.

## Support

If you encounter any issues during deployment, refer to the [Troubleshooting](./deploy.md#troubleshooting) section in `deploy.md`.
