#!/bin/bash

################################################################################
# Quick Fix: Update SQL Connection String to Trust Server Certificate
################################################################################
#
# This script updates the Azure Function App connection string to trust
# the SQL Server certificate, fixing the SSL certificate error.
#
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ ${1}${NC}"
}

print_success() {
    echo -e "${GREEN}✓ ${1}${NC}"
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

# Configuration
FUNCTION_APP="${1}"
RESOURCE_GROUP="${2:-kaman_group}"

if [ -z "$FUNCTION_APP" ]; then
    print_error "Usage: $0 <function-app-name> [resource-group]"
    print_info "Example: $0 kaman-prod kaman_group"
    exit 1
fi

print_header "Fixing SQL Server Connection String"

print_info "Function App: $FUNCTION_APP"
print_info "Resource Group: $RESOURCE_GROUP"
echo ""

# Get current connection string
print_info "Retrieving current connection string..."
CURRENT_CONNECTION=$(az functionapp config appsettings list \
    --name "$FUNCTION_APP" \
    --resource-group "$RESOURCE_GROUP" \
    --query "[?name=='DbConnectionString'].value" \
    --output tsv)

if [ -z "$CURRENT_CONNECTION" ]; then
    print_error "Could not retrieve DbConnectionString setting"
    exit 1
fi

print_success "Current connection string retrieved"

# Update TrustServerCertificate=False to TrustServerCertificate=True
NEW_CONNECTION="${CURRENT_CONNECTION//TrustServerCertificate=False/TrustServerCertificate=True}"

if [ "$CURRENT_CONNECTION" == "$NEW_CONNECTION" ]; then
    print_info "Connection string already has TrustServerCertificate=True"
    print_success "No changes needed!"
    exit 0
fi

# Apply the fix
print_info "Updating connection string..."
az functionapp config appsettings set \
    --name "$FUNCTION_APP" \
    --resource-group "$RESOURCE_GROUP" \
    --settings "DbConnectionString=$NEW_CONNECTION" \
    --output none

print_success "Connection string updated successfully!"

# Restart the function app
print_info "Restarting function app to apply changes..."
az functionapp restart \
    --name "$FUNCTION_APP" \
    --resource-group "$RESOURCE_GROUP" \
    --output none

print_success "Function app restarted"

print_header "✅ Fix Applied Successfully"

echo "The SQL connection string has been updated to trust the server certificate."
echo ""
echo "Change made:"
echo "  TrustServerCertificate=False  →  TrustServerCertificate=True"
echo ""
echo "Your function app should now be able to connect to the database."
echo ""
print_info "Test your login endpoint to verify the fix:"
echo ""
FUNCTION_URL="https://$(az functionapp show --name "$FUNCTION_APP" --resource-group "$RESOURCE_GROUP" --query defaultHostName --output tsv)"
echo "curl -X POST \"$FUNCTION_URL/api/auth/login\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"email\":\"superadmin@kaman.local\",\"password\":\"YourPassword123!\"}'"
echo ""
