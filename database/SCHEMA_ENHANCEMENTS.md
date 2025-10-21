# Kaman Database Schema - Enhancement Guide

## Overview

This document outlines all enhancements made to the Kaman gift card platform database schema. The enhanced schema addresses critical missing features, improves performance, and adds robust security and audit capabilities.

---

## Critical Enhancements

### 1. Shopping Cart System (NEW)

**Tables Added:**
- `orders.ShoppingCart` - Manages active shopping carts
- `orders.CartItems` - Stores items in shopping carts

**Features:**
- Cart expiration tracking
- Multiple cart statuses (ACTIVE, CHECKED_OUT, ABANDONED, EXPIRED)
- Automatic cart-to-order conversion workflow
- Cascade delete on cart items when cart is deleted

**Usage:**
```sql
-- Create a new cart for a company
INSERT INTO orders.ShoppingCart (CompanyId, CreatedByUserId, ExpiresAtUtc)
VALUES (@CompanyId, @UserId, DATEADD(HOUR, 24, SYSUTCDATETIME()));

-- Add items to cart
INSERT INTO orders.CartItems (CartId, VendorProductId, ProductName, Denomination, Quantity, Currency, UnitPrice, TotalPrice)
VALUES (@CartId, 'PROD_123', 'Amazon Gift Card', 50.00, 10, 'EGP', 50.00, 500.00);
```

### 2. Excel Upload Tracking (NEW)

**Table Added:**
- `orders.RecipientUploads` - Tracks Excel file uploads containing recipient emails

**Features:**
- File metadata tracking (name, size, path)
- Processing status tracking
- Success/failure counters
- Error logging
- Links to both carts and orders

**Usage:**
```sql
-- Track an uploaded file
INSERT INTO orders.RecipientUploads (CartId, FileName, FileSize, RecipientCount, UploadedByUserId, Status)
VALUES (@CartId, 'recipients.xlsx', 15360, 150, @UserId, 'UPLOADED');
```

### 3. Audit Logging System (NEW)

**Schema Added:** `audit`

**Table Added:**
- `audit.AuditLog` - Comprehensive audit trail for all critical operations

**Features:**
- Track INSERT, UPDATE, DELETE operations
- Store before/after values
- IP address and user agent tracking
- Company-level filtering
- Optimized indexes for reporting

**Usage:**
```sql
-- View all changes to a specific order
SELECT * FROM audit.AuditLog
WHERE TableName = 'Orders' AND RecordId = @OrderId
ORDER BY Timestamp DESC;
```

### 4. Password Reset System (NEW)

**Table Added:**
- `auth.PasswordResetTokens` - Manages password reset tokens

**Features:**
- GUID-based tokens
- Expiration tracking
- One-time use enforcement
- Automatic cleanup of used/expired tokens

**Usage:**
```sql
-- Generate reset token
INSERT INTO auth.PasswordResetTokens (UserId, ExpiresAtUtc)
VALUES (@UserId, DATEADD(HOUR, 24, SYSUTCDATETIME()));

-- Validate and use token
SELECT UserId FROM auth.PasswordResetTokens
WHERE Token = @Token
  AND ExpiresAtUtc > SYSUTCDATETIME()
  AND UsedAtUtc IS NULL;
```

### 5. Email Templates (NEW)

**Table Added:**
- `core.EmailTemplates` - Reusable email templates with variable substitution

**Pre-configured Templates:**
- ORDER_CONFIRMATION
- TOP_UP_APPROVED
- GIFT_CARD_DELIVERY

**Features:**
- HTML and plain text versions
- Variable placeholders (e.g., {{OrderNumber}}, {{Amount}})
- Template versioning support

### 6. System Configuration (NEW)

**Table Added:**
- `core.SystemConfig` - Centralized system-wide settings

**Pre-configured Settings:**
- MIN_TOP_UP_AMOUNT: Minimum top-up amount
- MAX_ORDER_ITEMS: Maximum items per order
- RESAL_API_TIMEOUT: API timeout in milliseconds
- CART_EXPIRY_HOURS: Cart expiration time
- MAX_RECIPIENTS_PER_UPLOAD: Upload limit

**Usage:**
```sql
-- Get config value
SELECT ConfigValue FROM core.SystemConfig WHERE ConfigKey = 'MIN_TOP_UP_AMOUNT';

-- Update config
UPDATE core.SystemConfig
SET ConfigValue = '200.00', UpdatedAtUtc = SYSUTCDATETIME(), UpdatedBy = @UserId
WHERE ConfigKey = 'MIN_TOP_UP_AMOUNT';
```

### 7. Fee Management (NEW)

**Table Added:**
- `core.FeeConfig` - Configurable fee structure

**Features:**
- Fixed and percentage-based fees
- Currency-specific fees
- Min/max amount limits
- Active/inactive status

**Usage:**
```sql
-- Get active order fees
SELECT * FROM core.FeeConfig
WHERE FeeType = 'ORDER_FEE' AND IsActive = 1;
```

### 8. API Request Logging (NEW)

**Table Added:**
- `vendor.ApiRequestLog` - Complete API request/response logging

**Features:**
- Request/response headers and body
- Duration tracking
- Success/failure status
- Performance monitoring

**Usage:**
```sql
-- Log API request
INSERT INTO vendor.ApiRequestLog (Endpoint, Method, RequestBody, ResponseStatus, DurationMs, Success)
VALUES ('/api/v1/purchase', 'POST', @RequestJson, 200, 1523, 1);
```

### 9. Login Security (NEW)

**Table Added:**
- `auth.LoginAttempts` - Track all login attempts for security

**Features:**
- Failed login tracking
- IP address logging
- User agent tracking
- Account lockout support (via Users.IsLocked and FailedLoginAttempts)

**Enhanced Users Table:**
- `IsLocked` - Lock account after too many failed attempts
- `FailedLoginAttempts` - Counter for failed logins
- `LastFailedLoginUtc` - Timestamp of last failure

---

## Data Integrity Improvements

### 1. Unique Constraints
- **Gift Card Codes**: Added unique constraint on `GiftCardAssignments.Code` to prevent duplicate codes
- **Company Names**: Filtered unique index excluding soft-deleted records
- **User Emails**: Filtered unique index excluding soft-deleted records

### 2. Soft Deletes
Added `DeletedAtUtc` columns to:
- `core.Companies`
- `auth.Users`

**Benefits:**
- Data recovery capability
- Audit trail preservation
- Referential integrity maintenance

### 3. Foreign Key Improvements
- Added FK from `Transactions.Type` to `ref.TxnType`
- Added FK from `Transactions.Status` to `ref.TxnStatus`
- Added FK from `Orders.Status` to `ref.OrderStatus`
- Added FK from `EmailNotifications.TemplateCode` to `EmailTemplates`

### 4. Cascade Operations
- `CartItems` cascade delete when cart is deleted
- `OrderItems` cascade delete when order is deleted
- `OrderRecipients` cascade delete when order is deleted

### 5. Data Validation
- `CK_Txn_Amount_Positive`: Ensure transaction amounts are positive
- `CK_TopUp_Amount_Positive`: Ensure top-up amounts are positive
- `CK_OrderItems_Fulfilled`: Ensure fulfilled quantity doesn't exceed total

---

## Performance Enhancements

### New Indexes

#### User Management
```sql
IX_Users_CompanyId           -- Fast company user lookups
IX_Users_Active              -- Active user queries
IX_Users_Active_NotDeleted   -- Filtered index for active users
```

#### Orders
```sql
IX_Orders_PlacedAt              -- Date-based order queries
IX_Orders_User                  -- User order history
IX_Orders_Company_Status_Date   -- Composite for company dashboards
```

#### Transactions
```sql
IX_Txn_PostedAt                 -- Transaction history queries
IX_Txn_Created                  -- Recent transactions
IX_Txn_Wallet_Status_Type       -- Composite with INCLUDE for balance calculations
```

#### Wallet
```sql
IX_TopUp_Status                 -- Top-up request filtering
IX_TopUp_RequestedBy            -- User top-up history
```

#### Audit
```sql
IX_Audit_Table                  -- Audit by entity
IX_Audit_User                   -- User activity tracking
IX_Audit_Company                -- Company-level auditing
IX_Audit_Timestamp              -- Recent activity queries
```

---

## Enhanced Views

### 1. `wallet.vwCompanyWalletBalances` (ENHANCED)
**New Columns:**
- `CompanyCode` - Quick company identification
- `CompanyName` - Display name
- `TotalTopUps` - Sum of all top-ups
- `TotalRefunds` - Sum of all refunds

**Improvements:**
- Uses `IsCredit` flag from `ref.TxnType` for cleaner balance calculation
- Excludes soft-deleted companies

### 2. `orders.vwOrderSummary` (NEW)
**Purpose:** Comprehensive order overview for dashboards

**Columns:**
- Order details (number, status, amounts)
- Company information
- User information
- Item and recipient counts
- Fulfillment statistics
- Timestamps

**Usage:**
```sql
-- Get order summary for a company
SELECT * FROM orders.vwOrderSummary
WHERE CompanyId = @CompanyId
ORDER BY PlacedAtUtc DESC;
```

### 3. `wallet.vwTopUpRequestSummary` (NEW)
**Purpose:** Top-up request tracking and reporting

**Columns:**
- Request details and status
- Requester and approver information
- Pending time calculation
- Rejection reason tracking

**Usage:**
```sql
-- Get pending top-up requests
SELECT * FROM wallet.vwTopUpRequestSummary
WHERE Status = 'REQUESTED'
ORDER BY DaysPending DESC;
```

---

## Stored Procedures

### 1. `wallet.sp_GetCompanyWalletDetails`
**Purpose:** Retrieve wallet balance for a company

**Parameters:**
- `@CompanyId` - Company ID
- `@Currency` - Optional currency filter

**Usage:**
```sql
EXEC wallet.sp_GetCompanyWalletDetails @CompanyId = 1, @Currency = 'EGP';
```

### 2. `wallet.sp_ApproveTopUpRequest`
**Purpose:** Approve and process a top-up request

**Features:**
- Transaction safety (BEGIN/COMMIT/ROLLBACK)
- Automatic wallet creation if needed
- Creates posted transaction
- Updates top-up status

**Parameters:**
- `@TopUpRequestId` - The request to approve
- `@ApprovedByUserId` - Super admin approving

**Usage:**
```sql
EXEC wallet.sp_ApproveTopUpRequest
  @TopUpRequestId = 123,
  @ApprovedByUserId = 1;
```

---

## Triggers

### 1. `core.trg_Companies_AfterInsert`
**Purpose:** Auto-create wallet when company is created

**Behavior:**
- Automatically creates a wallet with the company's default currency
- Ensures every company has a wallet immediately

---

## Reference Table Enhancements

### 1. `ref.Currency`
**New Columns:**
- `Symbol` - Currency symbol (e.g., $, £, ﷼)
- `IsActive` - Enable/disable currencies

### 2. `ref.OrderStatus`
**New Column:**
- `DisplayOrder` - Control status display order in UI

### 3. `ref.TxnType`
**New Column:**
- `IsCredit` - Indicates if transaction increases (1) or decreases (0) balance

---

## Enhanced Table Features

### Companies Table
**New Columns:**
- `Address` - Physical address
- `MinimumBalance` - Minimum allowed balance
- `DeletedAtUtc` - Soft delete support

### Users Table
**New Columns:**
- `IsLocked` - Account lockout flag
- `FailedLoginAttempts` - Failed login counter
- `LastFailedLoginUtc` - Last failed login timestamp
- `DeletedAtUtc` - Soft delete support

### Orders Table
**New Columns:**
- `CartId` - Reference to original shopping cart
- `RefundedAmount` - Track partial/full refunds
- `FulfilledAtUtc` - Fulfillment timestamp
- `CancelledAtUtc` - Cancellation timestamp

### OrderItems Table
**New Columns:**
- `UnitPrice` - Price per item
- `TotalPrice` - Total line item price
- `FulfilledQuantity` - Track partial fulfillment

### TopUpRequests Table
**New Columns:**
- `RejectedAtUtc` - Rejection timestamp
- `RejectionReason` - Why request was rejected

### EmailNotifications Table
**New Columns:**
- `OrderRecipientId` - Link to specific recipient
- `TemplateCode` - Reference to email template
- `RetryCount` - Email retry attempts
- `MaxRetries` - Maximum retry limit

### ResalPurchases Table
**New Columns:**
- `RetryCount` - API retry counter
- `ErrorMessage` - Detailed error information

### OrderRecipients Table
**New Column:**
- `PhoneNumber` - Optional phone for SMS notifications

---

## Migration Path

### For Existing Databases

If you already have the old schema, follow these steps:

1. **Backup your database**
```sql
BACKUP DATABASE KamanDb TO DISK = 'C:\Backups\KamanDb_Before_Enhancement.bak';
```

2. **Add new schemas**
```sql
CREATE SCHEMA [audit];
```

3. **Add new reference data**
```sql
-- Update existing tables with new columns
ALTER TABLE [ref].[Currency] ADD [Symbol] NVARCHAR(10) NULL, [IsActive] BIT NOT NULL DEFAULT 1;
ALTER TABLE [ref].[OrderStatus] ADD [DisplayOrder] INT NOT NULL DEFAULT 0;
ALTER TABLE [ref].[TxnType] ADD [IsCredit] BIT NOT NULL DEFAULT 1;
```

4. **Create new tables** (follow order in schema)

5. **Add missing columns to existing tables**

6. **Create indexes and views**

7. **Test the migration**

### For New Installations

Simply run the complete `kaman_schema.sql` file:

```sql
sqlcmd -S localhost -d KamanDb -i database/kaman_schema.sql
```

---

## Security Best Practices

### Password Handling
- **NEVER** store plain text passwords
- Use strong hashing algorithms (bcrypt, Argon2, PBKDF2)
- Replace placeholder hashes (`0x01020304`) in production
- Implement password complexity requirements

### Sample Password Hashing (Application Level)
```csharp
// C# example using BCrypt
string passwordHash = BCrypt.Net.BCrypt.HashPassword(plainPassword);
bool isValid = BCrypt.Net.BCrypt.Verify(plainPassword, passwordHash);
```

### Account Lockout Policy
Recommended implementation:
- Lock account after 5 failed attempts
- Unlock automatically after 30 minutes
- Send notification email on lockout
- Allow admin manual unlock

### API Security
- Log all Resal API calls to `vendor.ApiRequestLog`
- Implement request signing
- Use HTTPS only
- Store API keys securely (not in database)

---

## Testing Recommendations

### 1. Unit Tests
- Test stored procedures with various inputs
- Verify constraint enforcement
- Test cascade deletes
- Validate view calculations

### 2. Integration Tests
- Complete order workflow (cart → order → fulfillment)
- Top-up request lifecycle
- Wallet balance calculations
- Email notification flow

### 3. Performance Tests
- Load test with 10,000+ companies
- Stress test cart-to-order conversion
- Query performance on views with large datasets
- Index effectiveness analysis

### 4. Security Tests
- SQL injection attempts
- Account lockout functionality
- Soft delete effectiveness
- Audit log completeness

---

## Maintenance Tasks

### Regular Cleanup

#### Old Password Reset Tokens
```sql
-- Delete expired and used tokens older than 30 days
DELETE FROM auth.PasswordResetTokens
WHERE CreatedAtUtc < DATEADD(DAY, -30, SYSUTCDATETIME())
  AND (UsedAtUtc IS NOT NULL OR ExpiresAtUtc < SYSUTCDATETIME());
```

#### Old Login Attempts
```sql
-- Archive login attempts older than 90 days
DELETE FROM auth.LoginAttempts
WHERE AttemptedAtUtc < DATEADD(DAY, -90, SYSUTCDATETIME());
```

#### Abandoned Carts
```sql
-- Clean up carts abandoned for more than 30 days
UPDATE orders.ShoppingCart
SET Status = 'ABANDONED'
WHERE Status = 'ACTIVE'
  AND CreatedAtUtc < DATEADD(DAY, -30, SYSUTCDATETIME());
```

#### API Logs
```sql
-- Archive old API logs (keep 60 days)
DELETE FROM vendor.ApiRequestLog
WHERE CreatedAtUtc < DATEADD(DAY, -60, SYSUTCDATETIME());
```

### Index Maintenance
```sql
-- Rebuild fragmented indexes (run weekly)
ALTER INDEX ALL ON [orders].[Orders] REBUILD;
ALTER INDEX ALL ON [wallet].[Transactions] REBUILD;
ALTER INDEX ALL ON [audit].[AuditLog] REBUILD;
```

### Statistics Update
```sql
-- Update statistics for better query plans
UPDATE STATISTICS [orders].[Orders];
UPDATE STATISTICS [wallet].[Transactions];
UPDATE STATISTICS [orders].[OrderRecipients];
```

---

## Monitoring Queries

### System Health

#### Wallet Balance Check
```sql
-- Verify wallet balances are correct
SELECT * FROM wallet.vwCompanyWalletBalances;
```

#### Pending Operations
```sql
-- Check pending top-ups
SELECT COUNT(*) as PendingTopUps
FROM wallet.TopUpRequests
WHERE Status = 'REQUESTED';

-- Check pending orders
SELECT COUNT(*) as PendingOrders
FROM orders.Orders
WHERE Status IN ('PENDING', 'ON_HOLD');
```

#### Failed Operations
```sql
-- Recent failed email notifications
SELECT * FROM orders.EmailNotifications
WHERE Status = 'FAILED'
  AND CreatedAtUtc > DATEADD(HOUR, -24, SYSUTCDATETIME());
```

#### API Performance
```sql
-- Average API response times
SELECT
  Endpoint,
  AVG(DurationMs) as AvgDurationMs,
  MAX(DurationMs) as MaxDurationMs,
  COUNT(*) as RequestCount,
  SUM(CASE WHEN Success = 0 THEN 1 ELSE 0 END) as FailureCount
FROM vendor.ApiRequestLog
WHERE CreatedAtUtc > DATEADD(DAY, -7, SYSUTCDATETIME())
GROUP BY Endpoint;
```

---

## Sample Workflows

### Complete Order Flow

```sql
-- 1. Create shopping cart
DECLARE @CartId BIGINT;
INSERT INTO orders.ShoppingCart (CompanyId, CreatedByUserId, ExpiresAtUtc)
VALUES (1, 2, DATEADD(HOUR, 24, SYSUTCDATETIME()));
SET @CartId = SCOPE_IDENTITY();

-- 2. Add items to cart
INSERT INTO orders.CartItems (CartId, VendorProductId, ProductName, Denomination, Quantity, Currency, UnitPrice, TotalPrice)
VALUES (@CartId, 'AMZ_50', 'Amazon $50', 50.00, 10, 'USD', 50.00, 500.00);

-- 3. Upload recipients
DECLARE @UploadId BIGINT;
INSERT INTO orders.RecipientUploads (CartId, FileName, RecipientCount, UploadedByUserId)
VALUES (@CartId, 'recipients.xlsx', 10, 2);
SET @UploadId = SCOPE_IDENTITY();

-- 4. Convert cart to order
DECLARE @OrderId BIGINT;
INSERT INTO orders.Orders (CompanyId, CreatedByUserId, CartId, Currency, TotalAmount, Status)
VALUES (1, 2, @CartId, 'USD', 500.00, 'PENDING');
SET @OrderId = SCOPE_IDENTITY();

-- 5. Mark cart as checked out
UPDATE orders.ShoppingCart
SET Status = 'CHECKED_OUT', CheckedOutAtUtc = SYSUTCDATETIME()
WHERE CartId = @CartId;
```

---

## Future Enhancements

### Potential Additions

1. **Multi-currency Exchange Rates**
   - Table for storing exchange rates
   - Automatic conversion support

2. **Company Credit Limits**
   - Max credit allowed per company
   - Auto-reject orders exceeding limit

3. **Scheduled Reports**
   - Automated daily/weekly reports
   - Email delivery

4. **Webhook Integration**
   - Real-time order status notifications
   - Third-party integrations

5. **Gift Card Inventory**
   - Pre-purchased card pool
   - Instant fulfillment

6. **Company Hierarchy**
   - Parent/child company relationships
   - Consolidated billing

---

## Support

For questions or issues with the schema:
1. Review this documentation
2. Check table comments in schema
3. Review stored procedures for business logic examples
4. Contact the development team

---

**Schema Version:** 2.0 Enhanced
**Last Updated:** 2025-10-21
**Compatibility:** SQL Server 2016+
