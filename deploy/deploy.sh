#!/bin/bash

################################################################################
# Kaman Azure Functions Deployment Script
################################################################################
#
# This script automates the deployment of Kaman Gift Card System to Azure.
#
# Usage:
#   1. Copy this file: cp deploy.sh my-deploy.sh
#   2. Edit my-deploy.sh and update the configuration section
#   3. Make it executable: chmod +x my-deploy.sh
#   4. Run it: ./my-deploy.sh
#
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# CONFIGURATION SECTION - UPDATE THESE VALUES
################################################################################

# Azure Configuration
RESOURCE_GROUP="kaman_group"
LOCATION="eastus"  # Options: eastus, westus, westeurope, etc.
FUNCTION_APP="kaman-prod"  # Must be globally unique! Consider: kaman-$(date +%s)
STORAGE_ACCOUNT="kamanstorage$(date +%s)"  # Auto-generates unique name

# SQL Server Configuration
SQL_SERVER="your-sql-server.database.windows.net"
SQL_DATABASE="KamanDB"
SQL_USER="your-sql-username"
SQL_PASSWORD="your-sql-password"

# Resal API Configuration
RESAL_API_URL="https://glee-sandbox.resal.me/api/v1/"
RESAL_BEARER_TOKEN="your-resal-bearer-token-here"

# JWT Configuration (MUST be 32+ characters each)
JWT_SECRET="your-super-secret-jwt-key-min-32-chars-long-change-this"
JWT_REFRESH_SECRET="your-super-secret-refresh-key-min-32-chars-long-change-this"

# Optional Configuration
JWT_EXPIRES_IN_MINUTES="60"
JWT_REFRESH_EXPIRES_IN_DAYS="7"
DEFAULT_PASSWORD="Kaman@2025"

# Enable CORS (set to "true" to enable, "false" to skip)
ENABLE_CORS="true"
CORS_ORIGINS="*"  # For production, use specific domain: "https://yourdomain.com"

################################################################################
# END CONFIGURATION SECTION
################################################################################

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ ${1}${NC}"
}

print_success() {
    echo -e "${GREEN}✓ ${1}${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ ${1}${NC}"
}

print_error() {
    echo -e "${RED}✗ ${1}${NC}"
}

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  ${1}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate configuration
validate_config() {
    print_header "Validating Configuration"

    local errors=0

    # Check if placeholder values are still present
    if [[ "$SQL_SERVER" == "your-sql-server.database.windows.net" ]]; then
        print_error "SQL_SERVER is not configured. Please update the configuration section."
        errors=$((errors + 1))
    fi

    if [[ "$SQL_USER" == "your-sql-username" ]]; then
        print_error "SQL_USER is not configured. Please update the configuration section."
        errors=$((errors + 1))
    fi

    if [[ "$SQL_PASSWORD" == "your-sql-password" ]]; then
        print_error "SQL_PASSWORD is not configured. Please update the configuration section."
        errors=$((errors + 1))
    fi

    if [[ "$RESAL_BEARER_TOKEN" == "your-resal-bearer-token-here" ]]; then
        print_error "RESAL_BEARER_TOKEN is not configured. Please update the configuration section."
        errors=$((errors + 1))
    fi

    if [[ "$JWT_SECRET" == "your-super-secret-jwt-key-min-32-chars-long-change-this" ]]; then
        print_error "JWT_SECRET is not configured. Please update the configuration section."
        errors=$((errors + 1))
    fi

    if [[ "$JWT_REFRESH_SECRET" == "your-super-secret-refresh-key-min-32-chars-long-change-this" ]]; then
        print_error "JWT_REFRESH_SECRET is not configured. Please update the configuration section."
        errors=$((errors + 1))
    fi

    # Check JWT secret lengths
    if [[ ${#JWT_SECRET} -lt 32 ]]; then
        print_error "JWT_SECRET must be at least 32 characters long (current: ${#JWT_SECRET})"
        errors=$((errors + 1))
    fi

    if [[ ${#JWT_REFRESH_SECRET} -lt 32 ]]; then
        print_error "JWT_REFRESH_SECRET must be at least 32 characters long (current: ${#JWT_REFRESH_SECRET})"
        errors=$((errors + 1))
    fi

    if [[ $errors -gt 0 ]]; then
        print_error "Configuration validation failed with $errors error(s)."
        print_warning "Please update the configuration section in this script and try again."
        exit 1
    fi

    print_success "Configuration validation passed"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    local missing=0

    if ! command_exists az; then
        print_error "Azure CLI is not installed. Please install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        missing=$((missing + 1))
    else
        print_success "Azure CLI found: $(az --version | head -n 1)"
    fi

    if ! command_exists func; then
        print_error "Azure Functions Core Tools is not installed. Please install it from: https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local"
        missing=$((missing + 1))
    else
        print_success "Azure Functions Core Tools found: $(func --version)"
    fi

    if ! command_exists dotnet; then
        print_error ".NET SDK is not installed. Please install it from: https://dotnet.microsoft.com/download"
        missing=$((missing + 1))
    else
        print_success ".NET SDK found: $(dotnet --version)"
    fi

    if [[ $missing -gt 0 ]]; then
        print_error "Missing $missing required tool(s). Please install them and try again."
        exit 1
    fi

    print_success "All prerequisites are installed"
}

# Display deployment configuration
display_config() {
    print_header "Deployment Configuration"

    echo "Azure Settings:"
    echo "  Resource Group:    $RESOURCE_GROUP"
    echo "  Location:          $LOCATION"
    echo "  Function App:      $FUNCTION_APP"
    echo "  Storage Account:   $STORAGE_ACCOUNT"
    echo ""
    echo "Database Settings:"
    echo "  Server:            $SQL_SERVER"
    echo "  Database:          $SQL_DATABASE"
    echo "  Username:          $SQL_USER"
    echo ""
    echo "API Settings:"
    echo "  Resal API URL:     $RESAL_API_URL"
    echo ""

    print_warning "Please verify the configuration above is correct."
    read -p "Do you want to continue? (yes/no): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
        print_info "Deployment cancelled by user."
        exit 0
    fi
}

# Main deployment function
deploy() {
    print_header "🚀 Starting Azure Functions Deployment"

    # Step 1: Login to Azure
    print_info "Step 1/8: Azure Login"
    if ! az account show &>/dev/null; then
        print_warning "Not logged in to Azure. Please login..."
        az login
    else
        print_success "Already logged in to Azure"
        CURRENT_SUBSCRIPTION=$(az account show --query name -o tsv)
        print_info "Current subscription: $CURRENT_SUBSCRIPTION"
    fi

    # Step 2: Create Resource Group
    print_info "Step 2/8: Creating Resource Group"
    if az group show --name "$RESOURCE_GROUP" &>/dev/null; then
        print_warning "Resource group '$RESOURCE_GROUP' already exists. Using existing group."
    else
        az group create \
            --name "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --output none
        print_success "Resource group created: $RESOURCE_GROUP"
    fi

    # Step 3: Create Storage Account
    print_info "Step 3/8: Creating Storage Account"
    if az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
        print_warning "Storage account '$STORAGE_ACCOUNT' already exists. Using existing account."
    else
        az storage account create \
            --name "$STORAGE_ACCOUNT" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --sku Standard_LRS \
            --kind StorageV2 \
            --output none
        print_success "Storage account created: $STORAGE_ACCOUNT"
    fi

    # Step 4: Create Function App
    print_info "Step 4/8: Creating Function App"
    if az functionapp show --name "$FUNCTION_APP" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
        print_warning "Function app '$FUNCTION_APP' already exists. Skipping creation."
    else
        az functionapp create \
            --name "$FUNCTION_APP" \
            --resource-group "$RESOURCE_GROUP" \
            --storage-account "$STORAGE_ACCOUNT" \
            --consumption-plan-location "$LOCATION" \
            --runtime dotnet-isolated \
            --runtime-version 8 \
            --functions-version 4 \
            --os-type Windows \
            --output none
        print_success "Function app created: $FUNCTION_APP"
    fi

    # Step 5: Configure App Settings
    print_info "Step 5/8: Configuring Application Settings"

    DB_CONNECTION_STRING="Server=$SQL_SERVER;Database=$SQL_DATABASE;User Id=$SQL_USER;Password=$SQL_PASSWORD;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;"

    az functionapp config appsettings set \
        --name "$FUNCTION_APP" \
        --resource-group "$RESOURCE_GROUP" \
        --settings \
            "DbConnectionString=$DB_CONNECTION_STRING" \
            "JwtSecret=$JWT_SECRET" \
            "JwtRefreshSecret=$JWT_REFRESH_SECRET" \
            "JwtExpiresInMinutes=$JWT_EXPIRES_IN_MINUTES" \
            "JwtRefreshExpiresInDays=$JWT_REFRESH_EXPIRES_IN_DAYS" \
            "DefaultPassword=$DEFAULT_PASSWORD" \
            "ResalApiBaseUrl=$RESAL_API_URL" \
            "ResalApiBearerToken=$RESAL_BEARER_TOKEN" \
        --output none

    print_success "Application settings configured"

    # Step 6: Enable CORS (Optional)
    if [[ "$ENABLE_CORS" == "true" ]]; then
        print_info "Step 6/8: Enabling CORS"

        # Remove all existing CORS origins first
        az functionapp cors remove \
            --name "$FUNCTION_APP" \
            --resource-group "$RESOURCE_GROUP" \
            --allowed-origins "*" \
            --output none 2>/dev/null || true

        # Add new CORS origin
        az functionapp cors add \
            --name "$FUNCTION_APP" \
            --resource-group "$RESOURCE_GROUP" \
            --allowed-origins "$CORS_ORIGINS" \
            --output none

        print_success "CORS enabled for: $CORS_ORIGINS"
    else
        print_info "Step 6/8: Skipping CORS configuration"
    fi

    # Step 7: Deploy Code
    print_info "Step 7/8: Deploying Code"

    # Get script directory and navigate to project
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    PROJECT_DIR="$SCRIPT_DIR/../azure-functions-csharp"

    if [[ ! -d "$PROJECT_DIR" ]]; then
        print_error "Project directory not found: $PROJECT_DIR"
        exit 1
    fi

    cd "$PROJECT_DIR"

    print_info "Building and publishing functions..."
    func azure functionapp publish "$FUNCTION_APP" --force

    print_success "Code deployed successfully"

    # Step 8: Verification
    print_info "Step 8/8: Verifying Deployment"

    sleep 5  # Wait for deployment to settle

    FUNCTION_URL="https://$(az functionapp show --name "$FUNCTION_APP" --resource-group "$RESOURCE_GROUP" --query defaultHostName --output tsv)"

    print_success "Deployment completed successfully!"

    # Display summary
    print_header "📋 Deployment Summary"

    echo "Function App URL:  $FUNCTION_URL"
    echo ""
    echo "API Endpoints:"
    echo "  Bootstrap:       POST   $FUNCTION_URL/api/bootstrap/super-admin"
    echo "  Login:           POST   $FUNCTION_URL/api/auth/login"
    echo "  Refresh Token:   POST   $FUNCTION_URL/api/auth/refresh"
    echo "  Create Company:  POST   $FUNCTION_URL/api/company/create"
    echo "  List Companies:  GET    $FUNCTION_URL/api/company/list"
    echo "  Create User:     POST   $FUNCTION_URL/api/user/create"
    echo "  Set Password:    POST   $FUNCTION_URL/api/user/set-password"
    echo "  List Categories: GET    $FUNCTION_URL/api/gifts/categories"
    echo "  List Gifts:      GET    $FUNCTION_URL/api/gifts?page=1&per_page=10"
    echo ""

    print_header "🧪 Test Your Deployment"

    echo "Test the bootstrap endpoint:"
    echo ""
    echo "curl -X POST \"$FUNCTION_URL/api/bootstrap/super-admin\" \\"
    echo "  -H \"Content-Type: application/json\" \\"
    echo "  -d '{\"password\":\"YourSuperAdminPassword123!\"}'"
    echo ""

    print_header "📊 View Live Logs"

    echo "To view live logs, run:"
    echo ""
    echo "  func azure functionapp logstream $FUNCTION_APP"
    echo ""
    echo "Or using Azure CLI:"
    echo ""
    echo "  az webapp log tail --name $FUNCTION_APP --resource-group $RESOURCE_GROUP"
    echo ""

    print_header "✅ Deployment Complete"

    print_success "Your Kaman API is now live at: $FUNCTION_URL"
}

# Main execution
main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║          Kaman Azure Functions Deployment Script               ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    validate_config
    check_prerequisites
    display_config
    deploy
}

# Run main function
main "$@"
