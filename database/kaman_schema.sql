/* =========================================================
   Kaman Gift Cards – Enhanced SQL Server Schema

   ENHANCEMENTS:
   - Shopping cart functionality
   - Excel upload tracking for recipients
   - Comprehensive audit logging
   - Password reset system
   - Email templates
   - System configuration
   - Fee management
   - API request logging
   - Performance indexes
   - Data integrity improvements
   - Security features
   ========================================================= */

-- 0) Create database (optional; comment out if you already created it)
-- CREATE DATABASE [KamanDb];
-- GO
-- USE [KamanDb];
-- GO

/* 1) SCHEMAS */
CREATE SCHEMA [auth];
GO
CREATE SCHEMA [core];
GO
CREATE SCHEMA [wallet];
GO
CREATE SCHEMA [orders];
GO
CREATE SCHEMA [vendor];
GO
CREATE SCHEMA [ref];
GO
CREATE SCHEMA [audit];
GO

/* =========================================================
   2) REFERENCE / LOOKUP TABLES
   ========================================================= */

CREATE TABLE [ref].[Currency](
  [CurrencyCode]  CHAR(3)      NOT NULL PRIMARY KEY,  -- 'EGP','SAR','USD'
  [Name]          NVARCHAR(64) NOT NULL,
  [Symbol]        NVARCHAR(10) NULL,
  [IsActive]      BIT          NOT NULL DEFAULT (1)
);
INSERT INTO [ref].[Currency] (CurrencyCode, Name, Symbol) VALUES
  ('EGP','Egyptian Pound','E£'),
  ('SAR','Saudi Riyal','﷼'),
  ('USD','US Dollar','$');

CREATE TABLE [ref].[OrderStatus](
  [StatusCode]   VARCHAR(24)   NOT NULL PRIMARY KEY,
  [Description]  NVARCHAR(128) NOT NULL,
  [DisplayOrder] INT           NOT NULL DEFAULT (0)
);
INSERT INTO [ref].[OrderStatus] (StatusCode, Description, DisplayOrder) VALUES
  ('PENDING','Created, awaiting processing', 1),
  ('ON_HOLD','Funds held, awaiting vendor purchase', 2),
  ('CONFIRMED','Purchase confirmed, assigning codes', 3),
  ('PARTIALLY_FULFILLED','Some codes assigned', 4),
  ('FULFILLED','All codes assigned', 5),
  ('CANCELLED','Cancelled, holds released', 6),
  ('FAILED','Failed, holds released', 7);

CREATE TABLE [ref].[TxnType](
  [TypeCode]     VARCHAR(24)   NOT NULL PRIMARY KEY,
  [Description]  NVARCHAR(128) NOT NULL,
  [IsCredit]     BIT           NOT NULL  -- 1 = increases balance, 0 = decreases
);
INSERT INTO [ref].[TxnType] (TypeCode, Description, IsCredit) VALUES
  ('TOP_UP','Credit from admin approved top up', 1),
  ('HOLD','Order placement hold', 0),
  ('PURCHASE','Captured spend after fulfillment', 0),
  ('REFUND','Refund credit', 1),
  ('HOLD_RELEASE','Release hold back to balance', 1);

CREATE TABLE [ref].[TxnStatus](
  [StatusCode]   VARCHAR(24)   NOT NULL PRIMARY KEY,
  [Description]  NVARCHAR(128) NOT NULL
);
INSERT INTO [ref].[TxnStatus] (StatusCode, Description) VALUES
  ('PENDING','Awaiting posting'),
  ('POSTED','Effective on balance'),
  ('CANCELLED','Voided / not effective');

/* =========================================================
   3) CORE TABLES
   ========================================================= */

CREATE TABLE [core].[Companies](
  [CompanyId]             BIGINT        IDENTITY(1,1) PRIMARY KEY,
  [CompanyCode]           VARCHAR(32)   NOT NULL UNIQUE,
  [Name]                  NVARCHAR(200) NOT NULL,
  [Email]                 NVARCHAR(256) NULL,
  [Phone]                 NVARCHAR(64)  NULL,
  [Country]               NVARCHAR(64)  NULL,
  [Address]               NVARCHAR(512) NULL,
  [DefaultCurrency]       CHAR(3)       NOT NULL DEFAULT 'EGP',
  [MinimumBalance]        DECIMAL(18,2) NOT NULL DEFAULT (0),  -- Minimum allowed balance
  [IsActive]              BIT           NOT NULL DEFAULT (1),
  [CreatedAtUtc]          DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  [UpdatedAtUtc]          DATETIME2(3)  NULL,
  [DeletedAtUtc]          DATETIME2(3)  NULL,  -- Soft delete
  CONSTRAINT FK_Companies_Currency FOREIGN KEY ([DefaultCurrency])
    REFERENCES [ref].[Currency]([CurrencyCode])
);
CREATE UNIQUE INDEX IX_Companies_Name ON [core].[Companies]([Name]) WHERE DeletedAtUtc IS NULL;
CREATE INDEX IX_Companies_Active ON [core].[Companies]([IsActive], [DeletedAtUtc]);

CREATE TABLE [core].[EmailTemplates](
  [TemplateId]    INT            IDENTITY(1,1) PRIMARY KEY,
  [TemplateCode]  VARCHAR(50)    NOT NULL UNIQUE,
  [Name]          NVARCHAR(128)  NOT NULL,
  [Subject]       NVARCHAR(256)  NOT NULL,
  [BodyHtml]      NVARCHAR(MAX)  NOT NULL,
  [BodyText]      NVARCHAR(MAX)  NULL,
  [Variables]     NVARCHAR(MAX)  NULL,  -- JSON array of available placeholders
  [IsActive]      BIT            NOT NULL DEFAULT (1),
  [CreatedAtUtc]  DATETIME2(3)   NOT NULL DEFAULT SYSUTCDATETIME(),
  [UpdatedAtUtc]  DATETIME2(3)   NULL
);

INSERT INTO [core].[EmailTemplates] (TemplateCode, Name, Subject, BodyHtml, BodyText, Variables) VALUES
  ('ORDER_CONFIRMATION', 'Order Confirmation', 'Your Order #{{OrderNumber}} has been placed',
   '<h1>Order Confirmed</h1><p>Your order #{{OrderNumber}} for {{TotalAmount}} {{Currency}} has been placed successfully.</p>',
   'Order Confirmed - Your order #{{OrderNumber}} for {{TotalAmount}} {{Currency}} has been placed successfully.',
   '["OrderNumber","TotalAmount","Currency","CompanyName"]'),
  ('TOP_UP_APPROVED', 'Top-Up Approved', 'Your top-up request has been approved',
   '<h1>Top-Up Approved</h1><p>Your top-up request for {{Amount}} {{Currency}} has been approved.</p>',
   'Top-Up Approved - Your top-up request for {{Amount}} {{Currency}} has been approved.',
   '["Amount","Currency","CompanyName"]'),
  ('GIFT_CARD_DELIVERY', 'Gift Card Delivery', 'Your Gift Card from {{CompanyName}}',
   '<h1>Your Gift Card</h1><p>Code: {{Code}}</p><p>PIN: {{Pin}}</p><p>Redeem at: {{RedeemUrl}}</p>',
   'Your Gift Card - Code: {{Code}}, PIN: {{Pin}}, Redeem at: {{RedeemUrl}}',
   '["Code","Pin","RedeemUrl","ProductName","Denomination","Currency","CompanyName"]');

CREATE TABLE [core].[SystemConfig](
  [ConfigKey]     VARCHAR(100)  NOT NULL PRIMARY KEY,
  [ConfigValue]   NVARCHAR(MAX) NOT NULL,
  [DataType]      VARCHAR(20)   NOT NULL,  -- 'STRING','INT','DECIMAL','BOOL','JSON'
  [Description]   NVARCHAR(256) NULL,
  [IsEditable]    BIT           NOT NULL DEFAULT (1),
  [UpdatedAtUtc]  DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  [UpdatedBy]     BIGINT        NULL
);

INSERT INTO [core].[SystemConfig] (ConfigKey, ConfigValue, DataType, Description, IsEditable) VALUES
  ('MIN_TOP_UP_AMOUNT', '100.00', 'DECIMAL', 'Minimum top-up request amount', 1),
  ('MAX_ORDER_ITEMS', '100', 'INT', 'Maximum items per order', 1),
  ('RESAL_API_TIMEOUT', '30000', 'INT', 'Resal API timeout in milliseconds', 1),
  ('CART_EXPIRY_HOURS', '24', 'INT', 'Hours before cart is considered abandoned', 1),
  ('MAX_RECIPIENTS_PER_UPLOAD', '1000', 'INT', 'Maximum recipients in Excel upload', 1);

CREATE TABLE [core].[FeeConfig](
  [FeeId]            INT           IDENTITY(1,1) PRIMARY KEY,
  [FeeType]          VARCHAR(50)   NOT NULL,  -- 'ORDER_FEE','TOP_UP_FEE','TRANSACTION_FEE'
  [FeeName]          NVARCHAR(128) NOT NULL,
  [CalculationType]  VARCHAR(20)   NOT NULL,  -- 'FIXED','PERCENTAGE'
  [Amount]           DECIMAL(18,4) NOT NULL,
  [Currency]         CHAR(3)       NULL,      -- NULL for percentage-based fees
  [MinAmount]        DECIMAL(18,2) NULL,
  [MaxAmount]        DECIMAL(18,2) NULL,
  [IsActive]         BIT           NOT NULL DEFAULT (1),
  [CreatedAtUtc]     DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  [UpdatedAtUtc]     DATETIME2(3)  NULL,
  CONSTRAINT CK_FeeCalcType CHECK (CalculationType IN ('FIXED','PERCENTAGE'))
);

INSERT INTO [core].[FeeConfig] (FeeType, FeeName, CalculationType, Amount, Currency) VALUES
  ('ORDER_FEE', 'Order Processing Fee', 'PERCENTAGE', 2.5, NULL),  -- 2.5%
  ('ORDER_FEE', 'Minimum Order Fee', 'FIXED', 5.00, 'EGP');

/* =========================================================
   4) AUTH TABLES
   ========================================================= */

CREATE TABLE [auth].[Roles](
  [RoleId]   INT         IDENTITY(1,1) PRIMARY KEY,
  [Name]     VARCHAR(50) NOT NULL UNIQUE,
  [Description] NVARCHAR(256) NULL
);
INSERT INTO [auth].[Roles] (Name, Description) VALUES
  ('SUPER_ADMIN', 'System administrator with full access'),
  ('COMPANY_ADMIN', 'Company administrator managing orders and users');

CREATE TABLE [auth].[Users](
  [UserId]        BIGINT        IDENTITY(1,1) PRIMARY KEY,
  [CompanyId]     BIGINT        NULL,  -- NULL for Super Admins
  [Email]         NVARCHAR(256) NOT NULL,
  [DisplayName]   NVARCHAR(128) NOT NULL,
  [PasswordHash]  VARBINARY(256) NOT NULL,
  [PasswordSalt]  VARBINARY(128) NULL,
  [IsActive]      BIT           NOT NULL DEFAULT (1),
  [IsLocked]      BIT           NOT NULL DEFAULT (0),
  [FailedLoginAttempts] INT     NOT NULL DEFAULT (0),
  [LastFailedLoginUtc] DATETIME2(3) NULL,
  [CreatedAtUtc]  DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  [LastLoginUtc]  DATETIME2(3)  NULL,
  [DeletedAtUtc]  DATETIME2(3)  NULL,  -- Soft delete
  CONSTRAINT FK_Users_Companies FOREIGN KEY (CompanyId)
    REFERENCES [core].[Companies](CompanyId)
);
CREATE UNIQUE INDEX IX_Users_Email ON [auth].[Users]([Email]) WHERE DeletedAtUtc IS NULL;
CREATE INDEX IX_Users_CompanyId ON [auth].[Users](CompanyId) WHERE CompanyId IS NOT NULL;
CREATE INDEX IX_Users_Active ON [auth].[Users](IsActive, IsLocked);

CREATE TABLE [auth].[UserRoles](
  [UserId]        BIGINT        NOT NULL,
  [RoleId]        INT           NOT NULL,
  [AssignedAtUtc] DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  [AssignedBy]    BIGINT        NULL,
  CONSTRAINT PK_UserRoles PRIMARY KEY (UserId, RoleId),
  CONSTRAINT FK_UserRoles_Users FOREIGN KEY (UserId)
    REFERENCES [auth].[Users](UserId),
  CONSTRAINT FK_UserRoles_Roles FOREIGN KEY (RoleId)
    REFERENCES [auth].[Roles](RoleId)
);

CREATE TABLE [auth].[PasswordResetTokens](
  [TokenId]       BIGINT           IDENTITY(1,1) PRIMARY KEY,
  [UserId]        BIGINT           NOT NULL,
  [Token]         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
  [ExpiresAtUtc]  DATETIME2(3)     NOT NULL,
  [UsedAtUtc]     DATETIME2(3)     NULL,
  [CreatedAtUtc]  DATETIME2(3)     NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_ResetToken_User FOREIGN KEY (UserId)
    REFERENCES [auth].[Users](UserId)
);
CREATE UNIQUE INDEX IX_ResetToken ON [auth].[PasswordResetTokens]([Token]);
CREATE INDEX IX_ResetToken_User ON [auth].[PasswordResetTokens](UserId, ExpiresAtUtc);

CREATE TABLE [auth].[LoginAttempts](
  [AttemptId]     BIGINT        IDENTITY(1,1) PRIMARY KEY,
  [Email]         NVARCHAR(256) NOT NULL,
  [UserId]        BIGINT        NULL,
  [IpAddress]     VARCHAR(45)   NULL,
  [UserAgent]     NVARCHAR(512) NULL,
  [Success]       BIT           NOT NULL,
  [FailureReason] NVARCHAR(256) NULL,
  [AttemptedAtUtc] DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_LoginAttempts_User FOREIGN KEY (UserId)
    REFERENCES [auth].[Users](UserId)
);
CREATE INDEX IX_LoginAttempts_Email ON [auth].[LoginAttempts](Email, AttemptedAtUtc DESC);
CREATE INDEX IX_LoginAttempts_User ON [auth].[LoginAttempts](UserId, AttemptedAtUtc DESC);

/* =========================================================
   5) WALLET TABLES
   ========================================================= */

CREATE TABLE [wallet].[Wallets](
  [WalletId]      BIGINT        IDENTITY(1,1) PRIMARY KEY,
  [CompanyId]     BIGINT        NOT NULL,
  [Currency]      CHAR(3)       NOT NULL,
  [CreatedAtUtc]  DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_Wallets UNIQUE (CompanyId, Currency),
  CONSTRAINT FK_Wallets_Company FOREIGN KEY (CompanyId)
    REFERENCES [core].[Companies](CompanyId),
  CONSTRAINT FK_Wallets_Currency FOREIGN KEY ([Currency])
    REFERENCES [ref].[Currency]([CurrencyCode])
);
CREATE INDEX IX_Wallets_Company ON [wallet].[Wallets](CompanyId);

CREATE TABLE [wallet].[Transactions](
  [TransactionId]       BIGINT        IDENTITY(1,1) PRIMARY KEY,
  [WalletId]            BIGINT        NOT NULL,
  [Type]                VARCHAR(24)   NOT NULL,
  [Status]              VARCHAR(24)   NOT NULL,
  [Amount]              DECIMAL(18,2) NOT NULL,  -- Always positive
  [Currency]            CHAR(3)       NOT NULL,
  [ReferenceType]       VARCHAR(32)   NULL,  -- 'TOPUP','ORDER','REFUND'
  [ReferenceId]         BIGINT        NULL,
  [Description]         NVARCHAR(256) NULL,
  [PostedAtUtc]         DATETIME2(3)  NULL,
  [CreatedAtUtc]        DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  [CreatedBy]           BIGINT        NULL,
  CONSTRAINT FK_Txn_Wallet FOREIGN KEY (WalletId)
    REFERENCES [wallet].[Wallets](WalletId),
  CONSTRAINT FK_Txn_Currency FOREIGN KEY ([Currency])
    REFERENCES [ref].[Currency]([CurrencyCode]),
  CONSTRAINT FK_Txn_Type FOREIGN KEY ([Type])
    REFERENCES [ref].[TxnType]([TypeCode]),
  CONSTRAINT FK_Txn_Status FOREIGN KEY ([Status])
    REFERENCES [ref].[TxnStatus]([StatusCode]),
  CONSTRAINT CK_Txn_Amount_Positive CHECK (Amount >= 0)
);
CREATE INDEX IX_Txn_Wallet ON [wallet].[Transactions](WalletId, Status, Type);
CREATE INDEX IX_Txn_Ref ON [wallet].[Transactions](ReferenceType, ReferenceId);
CREATE INDEX IX_Txn_PostedAt ON [wallet].[Transactions](PostedAtUtc DESC) WHERE Status='POSTED';
CREATE INDEX IX_Txn_Created ON [wallet].[Transactions](CreatedAtUtc DESC);

CREATE TABLE [wallet].[TopUpRequests](
  [TopUpRequestId]    BIGINT        IDENTITY(1,1) PRIMARY KEY,
  [CompanyId]         BIGINT        NOT NULL,
  [RequestedByUserId] BIGINT        NOT NULL,
  [ApprovedByUserId]  BIGINT        NULL,
  [Amount]            DECIMAL(18,2) NOT NULL,
  [Currency]          CHAR(3)       NOT NULL,
  [Status]            VARCHAR(24)   NOT NULL DEFAULT 'REQUESTED',
  [RequestedAtUtc]    DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  [ApprovedAtUtc]     DATETIME2(3)  NULL,
  [RejectedAtUtc]     DATETIME2(3)  NULL,
  [Notes]             NVARCHAR(512) NULL,
  [RejectionReason]   NVARCHAR(512) NULL,
  CONSTRAINT FK_TopUp_Company FOREIGN KEY (CompanyId)
    REFERENCES [core].[Companies](CompanyId),
  CONSTRAINT FK_TopUp_ReqUser FOREIGN KEY (RequestedByUserId)
    REFERENCES [auth].[Users](UserId),
  CONSTRAINT FK_TopUp_AppUser FOREIGN KEY (ApprovedByUserId)
    REFERENCES [auth].[Users](UserId),
  CONSTRAINT FK_TopUp_Currency FOREIGN KEY ([Currency])
    REFERENCES [ref].[Currency]([CurrencyCode]),
  CONSTRAINT CK_TopUp_Status CHECK (Status IN ('REQUESTED','APPROVED','REJECTED','CANCELLED','POSTED')),
  CONSTRAINT CK_TopUp_Amount_Positive CHECK (Amount > 0)
);
CREATE INDEX IX_TopUp_Company ON [wallet].[TopUpRequests](CompanyId, Status);
CREATE INDEX IX_TopUp_Status ON [wallet].[TopUpRequests](Status, RequestedAtUtc DESC);
CREATE INDEX IX_TopUp_RequestedBy ON [wallet].[TopUpRequests](RequestedByUserId, RequestedAtUtc DESC);

/* =========================================================
   6) ORDERS & SHOPPING CART TABLES
   ========================================================= */

CREATE SEQUENCE [orders].[SeqOrderNumber] AS BIGINT START WITH 100000 INCREMENT BY 1;
GO

CREATE TABLE [orders].[ShoppingCart](
  [CartId]            BIGINT        IDENTITY(1,1) PRIMARY KEY,
  [CompanyId]         BIGINT        NOT NULL,
  [CreatedByUserId]   BIGINT        NOT NULL,
  [Status]            VARCHAR(24)   NOT NULL DEFAULT 'ACTIVE',
  [ExpiresAtUtc]      DATETIME2(3)  NULL,
  [CreatedAtUtc]      DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  [UpdatedAtUtc]      DATETIME2(3)  NULL,
  [CheckedOutAtUtc]   DATETIME2(3)  NULL,
  CONSTRAINT FK_Cart_Company FOREIGN KEY (CompanyId)
    REFERENCES [core].[Companies](CompanyId),
  CONSTRAINT FK_Cart_User FOREIGN KEY (CreatedByUserId)
    REFERENCES [auth].[Users](UserId),
  CONSTRAINT CK_Cart_Status CHECK (Status IN ('ACTIVE','CHECKED_OUT','ABANDONED','EXPIRED'))
);
CREATE INDEX IX_Cart_Company ON [orders].[ShoppingCart](CompanyId, Status);
CREATE INDEX IX_Cart_User ON [orders].[ShoppingCart](CreatedByUserId, Status);

CREATE TABLE [orders].[CartItems](
  [CartItemId]        BIGINT        IDENTITY(1,1) PRIMARY KEY,
  [CartId]            BIGINT        NOT NULL,
  [VendorProductId]   NVARCHAR(100) NOT NULL,
  [ProductName]       NVARCHAR(200) NOT NULL,
  [Denomination]      DECIMAL(18,2) NOT NULL,
  [Quantity]          INT           NOT NULL CHECK (Quantity > 0),
  [Currency]          CHAR(3)       NOT NULL,
  [UnitPrice]         DECIMAL(18,2) NOT NULL,
  [TotalPrice]        DECIMAL(18,2) NOT NULL,
  [CreatedAtUtc]      DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_CartItems_Cart FOREIGN KEY (CartId)
    REFERENCES [orders].[ShoppingCart](CartId) ON DELETE CASCADE,
  CONSTRAINT FK_CartItems_Currency FOREIGN KEY ([Currency])
    REFERENCES [ref].[Currency]([CurrencyCode])
);
CREATE INDEX IX_CartItems_Cart ON [orders].[CartItems](CartId);

CREATE TABLE [orders].[Orders](
  [OrderId]           BIGINT        IDENTITY(1,1) PRIMARY KEY,
  [OrderNumber]       BIGINT        NOT NULL DEFAULT (NEXT VALUE FOR [orders].[SeqOrderNumber]),
  [CompanyId]         BIGINT        NOT NULL,
  [CreatedByUserId]   BIGINT        NOT NULL,
  [CartId]            BIGINT        NULL,  -- Reference to original cart
  [Status]            VARCHAR(24)   NOT NULL DEFAULT 'PENDING',
  [Vendor]            VARCHAR(50)   NOT NULL DEFAULT 'RESAL',
  [Currency]          CHAR(3)       NOT NULL,
  [SubtotalAmount]    DECIMAL(18,2) NOT NULL DEFAULT (0),
  [FeesAmount]        DECIMAL(18,2) NOT NULL DEFAULT (0),
  [TotalAmount]       DECIMAL(18,2) NOT NULL,
  [HoldAmount]        DECIMAL(18,2) NOT NULL DEFAULT (0),
  [RefundedAmount]    DECIMAL(18,2) NOT NULL DEFAULT (0),
  [RecipientCount]    INT           NOT NULL DEFAULT (0),
  [PlacedAtUtc]       DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  [UpdatedAtUtc]      DATETIME2(3)  NULL,
  [FulfilledAtUtc]    DATETIME2(3)  NULL,
  [CancelledAtUtc]    DATETIME2(3)  NULL,
  [Notes]             NVARCHAR(512) NULL,
  CONSTRAINT UQ_Orders_OrderNumber UNIQUE ([OrderNumber]),
  CONSTRAINT FK_Orders_Company FOREIGN KEY (CompanyId)
    REFERENCES [core].[Companies](CompanyId),
  CONSTRAINT FK_Orders_User FOREIGN KEY (CreatedByUserId)
    REFERENCES [auth].[Users](UserId),
  CONSTRAINT FK_Orders_Cart FOREIGN KEY (CartId)
    REFERENCES [orders].[ShoppingCart](CartId),
  CONSTRAINT FK_Orders_Currency FOREIGN KEY ([Currency])
    REFERENCES [ref].[Currency]([CurrencyCode]),
  CONSTRAINT FK_Orders_Status FOREIGN KEY ([Status])
    REFERENCES [ref].[OrderStatus]([StatusCode])
);
CREATE INDEX IX_Orders_CompanyStatus ON [orders].[Orders](CompanyId, Status);
CREATE INDEX IX_Orders_OrderNumber ON [orders].[Orders]([OrderNumber]);
CREATE INDEX IX_Orders_PlacedAt ON [orders].[Orders](PlacedAtUtc DESC);
CREATE INDEX IX_Orders_User ON [orders].[Orders](CreatedByUserId, PlacedAtUtc DESC);

CREATE TABLE [orders].[OrderItems](
  [OrderItemId]       BIGINT        IDENTITY(1,1) PRIMARY KEY,
  [OrderId]           BIGINT        NOT NULL,
  [VendorProductId]   NVARCHAR(100) NOT NULL,
  [ProductName]       NVARCHAR(200) NOT NULL,
  [Denomination]      DECIMAL(18,2) NOT NULL,
  [Quantity]          INT           NOT NULL CHECK (Quantity > 0),
  [Currency]          CHAR(3)       NOT NULL,
  [UnitPrice]         DECIMAL(18,2) NOT NULL,
  [TotalPrice]        DECIMAL(18,2) NOT NULL,
  [FulfilledQuantity] INT           NOT NULL DEFAULT (0),
  [CreatedAtUtc]      DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_OrderItems_Order FOREIGN KEY (OrderId)
    REFERENCES [orders].[Orders](OrderId) ON DELETE CASCADE,
  CONSTRAINT FK_OrderItems_Currency FOREIGN KEY ([Currency])
    REFERENCES [ref].[Currency]([CurrencyCode]),
  CONSTRAINT CK_OrderItems_Fulfilled CHECK (FulfilledQuantity >= 0 AND FulfilledQuantity <= Quantity)
);
CREATE INDEX IX_OrderItems_Order ON [orders].[OrderItems](OrderId);
CREATE INDEX IX_OrderItems_Product ON [orders].[OrderItems](VendorProductId);

CREATE TABLE [orders].[RecipientUploads](
  [UploadId]          BIGINT        IDENTITY(1,1) PRIMARY KEY,
  [OrderId]           BIGINT        NULL,  -- NULL while in cart stage
  [CartId]            BIGINT        NULL,
  [FileName]          NVARCHAR(256) NOT NULL,
  [FileSize]          BIGINT        NULL,
  [FilePath]          NVARCHAR(512) NULL,
  [RecipientCount]    INT           NOT NULL,
  [ProcessedCount]    INT           NOT NULL DEFAULT (0),
  [FailedCount]       INT           NOT NULL DEFAULT (0),
  [UploadedByUserId]  BIGINT        NOT NULL,
  [Status]            VARCHAR(24)   NOT NULL DEFAULT 'UPLOADED',
  [UploadedAtUtc]     DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  [ProcessedAtUtc]    DATETIME2(3)  NULL,
  [ErrorLog]          NVARCHAR(MAX) NULL,
  CONSTRAINT FK_RecipientUpload_Order FOREIGN KEY (OrderId)
    REFERENCES [orders].[Orders](OrderId),
  CONSTRAINT FK_RecipientUpload_Cart FOREIGN KEY (CartId)
    REFERENCES [orders].[ShoppingCart](CartId),
  CONSTRAINT FK_RecipientUpload_User FOREIGN KEY (UploadedByUserId)
    REFERENCES [auth].[Users](UserId),
  CONSTRAINT CK_RecipientUpload_Status CHECK (Status IN ('UPLOADED','PROCESSING','PROCESSED','FAILED'))
);
CREATE INDEX IX_RecipientUpload_Order ON [orders].[RecipientUploads](OrderId);
CREATE INDEX IX_RecipientUpload_Cart ON [orders].[RecipientUploads](CartId);

CREATE TABLE [orders].[OrderRecipients](
  [OrderRecipientId]  BIGINT        IDENTITY(1,1) PRIMARY KEY,
  [OrderId]           BIGINT        NOT NULL,
  [OrderItemId]       BIGINT        NULL,
  [UploadId]          BIGINT        NULL,
  [Email]             NVARCHAR(256) NOT NULL,
  [DisplayName]       NVARCHAR(128) NULL,
  [PhoneNumber]       NVARCHAR(64)  NULL,
  [Status]            VARCHAR(24)   NOT NULL DEFAULT 'PENDING',
  [CreatedAtUtc]      DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  [UpdatedAtUtc]      DATETIME2(3)  NULL,
  CONSTRAINT FK_Recipients_Order FOREIGN KEY (OrderId)
    REFERENCES [orders].[Orders](OrderId) ON DELETE CASCADE,
  CONSTRAINT FK_Recipients_OrderItem FOREIGN KEY (OrderItemId)
    REFERENCES [orders].[OrderItems](OrderItemId),
  CONSTRAINT FK_Recipients_Upload FOREIGN KEY (UploadId)
    REFERENCES [orders].[RecipientUploads](UploadId),
  CONSTRAINT CK_Recipients_Status CHECK (Status IN ('PENDING','ASSIGNED','SENT','DELIVERED','FAILED'))
);
CREATE INDEX IX_Recipients_Order ON [orders].[OrderRecipients](OrderId);
CREATE INDEX IX_Recipients_Email ON [orders].[OrderRecipients]([Email]);
CREATE INDEX IX_Recipients_Status ON [orders].[OrderRecipients](Status);

CREATE TABLE [orders].[GiftCardAssignments](
  [AssignmentId]      BIGINT        IDENTITY(1,1) PRIMARY KEY,
  [OrderId]           BIGINT        NOT NULL,
  [OrderItemId]       BIGINT        NOT NULL,
  [OrderRecipientId]  BIGINT        NOT NULL,
  [Code]              NVARCHAR(200) NOT NULL,
  [Pin]               NVARCHAR(200) NULL,
  [RedeemUrl]         NVARCHAR(500) NULL,
  [ExpiryDateUtc]     DATETIME2(3)  NULL,
  [AssignedAtUtc]     DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  [DeliveredAtUtc]    DATETIME2(3)  NULL,
  [DeliveryStatus]    VARCHAR(24)   NOT NULL DEFAULT 'PENDING',
  [VendorPayloadJson] NVARCHAR(MAX) NULL,
  CONSTRAINT UQ_Assignment_Recipient UNIQUE (OrderRecipientId),
  CONSTRAINT UQ_Assignment_Code UNIQUE ([Code]),  -- Prevent duplicate gift card codes
  CONSTRAINT FK_Assign_Order FOREIGN KEY (OrderId)
    REFERENCES [orders].[Orders](OrderId),
  CONSTRAINT FK_Assign_Item FOREIGN KEY (OrderItemId)
    REFERENCES [orders].[OrderItems](OrderItemId),
  CONSTRAINT FK_Assign_Recipient FOREIGN KEY (OrderRecipientId)
    REFERENCES [orders].[OrderRecipients](OrderRecipientId),
  CONSTRAINT CK_Assign_DeliveryStatus CHECK (DeliveryStatus IN ('PENDING','EMAIL_QUEUED','EMAIL_SENT','EMAIL_FAILED','DELIVERED'))
);
CREATE INDEX IX_Assign_Order ON [orders].[GiftCardAssignments](OrderId);
CREATE INDEX IX_Assign_Item ON [orders].[GiftCardAssignments](OrderItemId);
CREATE INDEX IX_Assign_DeliveryStatus ON [orders].[GiftCardAssignments](DeliveryStatus);

CREATE TABLE [orders].[EmailNotifications](
  [EmailNotificationId] BIGINT        IDENTITY(1,1) PRIMARY KEY,
  [OrderId]             BIGINT        NOT NULL,
  [OrderRecipientId]    BIGINT        NULL,
  [TemplateCode]        VARCHAR(50)   NULL,
  [ToEmail]             NVARCHAR(256) NOT NULL,
  [Subject]             NVARCHAR(256) NOT NULL,
  [Body]                NVARCHAR(MAX) NOT NULL,
  [Status]              VARCHAR(24)   NOT NULL DEFAULT 'QUEUED',
  [RetryCount]          INT           NOT NULL DEFAULT (0),
  [MaxRetries]          INT           NOT NULL DEFAULT (3),
  [CreatedAtUtc]        DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  [SentAtUtc]           DATETIME2(3)  NULL,
  [ErrorMessage]        NVARCHAR(512) NULL,
  CONSTRAINT FK_Email_Order FOREIGN KEY (OrderId)
    REFERENCES [orders].[Orders](OrderId),
  CONSTRAINT FK_Email_Recipient FOREIGN KEY (OrderRecipientId)
    REFERENCES [orders].[OrderRecipients](OrderRecipientId),
  CONSTRAINT FK_Email_Template FOREIGN KEY (TemplateCode)
    REFERENCES [core].[EmailTemplates](TemplateCode),
  CONSTRAINT CK_Email_Status CHECK (Status IN ('QUEUED','SENDING','SENT','FAILED','CANCELLED'))
);
CREATE INDEX IX_Email_Order ON [orders].[EmailNotifications](OrderId);
CREATE INDEX IX_Email_Status ON [orders].[EmailNotifications](Status, CreatedAtUtc);

/* =========================================================
   7) VENDOR INTEGRATION TABLES
   ========================================================= */

CREATE TABLE [vendor].[ResalPurchases](
  [ResalPurchaseId]  BIGINT        IDENTITY(1,1) PRIMARY KEY,
  [OrderId]          BIGINT        NOT NULL,
  [RequestId]        NVARCHAR(100) NULL,
  [VendorOrderId]    NVARCHAR(100) NULL,
  [Status]           VARCHAR(24)   NOT NULL DEFAULT 'REQUESTED',
  [RetryCount]       INT           NOT NULL DEFAULT (0),
  [RequestedAtUtc]   DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  [RespondedAtUtc]   DATETIME2(3)  NULL,
  [RequestJson]      NVARCHAR(MAX) NULL,
  [ResponseJson]     NVARCHAR(MAX) NULL,
  [ErrorMessage]     NVARCHAR(MAX) NULL,
  CONSTRAINT FK_Resal_Order FOREIGN KEY (OrderId)
    REFERENCES [orders].[Orders](OrderId),
  CONSTRAINT CK_Resal_Status CHECK (Status IN ('REQUESTED','IN_PROGRESS','SUCCESS','PARTIAL','FAILED','TIMEOUT'))
);
CREATE INDEX IX_Resal_Order ON [vendor].[ResalPurchases](OrderId);
CREATE INDEX IX_Resal_Status ON [vendor].[ResalPurchases](Status, RequestedAtUtc DESC);

CREATE TABLE [vendor].[ApiRequestLog](
  [LogId]            BIGINT        IDENTITY(1,1) PRIMARY KEY,
  [Endpoint]         NVARCHAR(256) NOT NULL,
  [Method]           VARCHAR(10)   NOT NULL,  -- 'GET','POST','PUT','DELETE'
  [RequestHeaders]   NVARCHAR(MAX) NULL,
  [RequestBody]      NVARCHAR(MAX) NULL,
  [ResponseStatus]   INT           NULL,
  [ResponseHeaders]  NVARCHAR(MAX) NULL,
  [ResponseBody]     NVARCHAR(MAX) NULL,
  [DurationMs]       INT           NULL,
  [Success]          BIT           NULL,
  [ErrorMessage]     NVARCHAR(MAX) NULL,
  [CreatedAtUtc]     DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX IX_ApiLog_Endpoint ON [vendor].[ApiRequestLog](Endpoint, CreatedAtUtc DESC);
CREATE INDEX IX_ApiLog_Created ON [vendor].[ApiRequestLog](CreatedAtUtc DESC);
CREATE INDEX IX_ApiLog_Success ON [vendor].[ApiRequestLog](Success, CreatedAtUtc DESC);

/* =========================================================
   8) AUDIT & LOGGING TABLES
   ========================================================= */

CREATE TABLE [audit].[AuditLog](
  [AuditId]       BIGINT        IDENTITY(1,1) PRIMARY KEY,
  [TableName]     NVARCHAR(128) NOT NULL,
  [RecordId]      BIGINT        NOT NULL,
  [Action]        VARCHAR(24)   NOT NULL,  -- 'INSERT','UPDATE','DELETE'
  [UserId]        BIGINT        NULL,
  [CompanyId]     BIGINT        NULL,
  [ColumnName]    NVARCHAR(128) NULL,
  [OldValue]      NVARCHAR(MAX) NULL,
  [NewValue]      NVARCHAR(MAX) NULL,
  [Changes]       NVARCHAR(MAX) NULL,  -- JSON of all changes
  [IpAddress]     VARCHAR(45)   NULL,
  [UserAgent]     NVARCHAR(512) NULL,
  [Timestamp]     DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT CK_Audit_Action CHECK (Action IN ('INSERT','UPDATE','DELETE'))
);
CREATE INDEX IX_Audit_Table ON [audit].[AuditLog](TableName, RecordId, Timestamp DESC);
CREATE INDEX IX_Audit_User ON [audit].[AuditLog](UserId, Timestamp DESC);
CREATE INDEX IX_Audit_Company ON [audit].[AuditLog](CompanyId, Timestamp DESC);
CREATE INDEX IX_Audit_Timestamp ON [audit].[AuditLog](Timestamp DESC);

/* =========================================================
   9) VIEWS
   ========================================================= */
GO

CREATE VIEW [wallet].[vwCompanyWalletBalances]
AS
SELECT
  c.CompanyId,
  c.CompanyCode,
  c.Name AS CompanyName,
  w.WalletId,
  w.Currency,
  Available =
      (  ISNULL(SUM(CASE WHEN t.Status='POSTED' AND rt.IsCredit = 1 THEN t.Amount ELSE 0 END), 0)
       - ISNULL(SUM(CASE WHEN t.Status='POSTED' AND rt.IsCredit = 0 THEN t.Amount ELSE 0 END), 0)
      ),
  OnHold =
      ISNULL(SUM(CASE WHEN t.Status='POSTED' AND t.Type='HOLD' THEN t.Amount ELSE 0 END), 0),
  TotalSpendings =
      ISNULL(SUM(CASE WHEN t.Status='POSTED' AND t.Type='PURCHASE' THEN t.Amount ELSE 0 END), 0),
  TotalTopUps =
      ISNULL(SUM(CASE WHEN t.Status='POSTED' AND t.Type='TOP_UP' THEN t.Amount ELSE 0 END), 0),
  TotalRefunds =
      ISNULL(SUM(CASE WHEN t.Status='POSTED' AND t.Type='REFUND' THEN t.Amount ELSE 0 END), 0)
FROM core.Companies c
JOIN wallet.Wallets w ON w.CompanyId = c.CompanyId
LEFT JOIN wallet.Transactions t ON t.WalletId = w.WalletId
LEFT JOIN ref.TxnType rt ON rt.TypeCode = t.Type
WHERE c.DeletedAtUtc IS NULL
GROUP BY c.CompanyId, c.CompanyCode, c.Name, w.WalletId, w.Currency;
GO

CREATE VIEW [orders].[vwOrderSummary]
AS
SELECT
  o.OrderId,
  o.OrderNumber,
  o.CompanyId,
  c.Name AS CompanyName,
  o.CreatedByUserId,
  u.DisplayName AS CreatedByUserName,
  o.Status,
  o.Currency,
  o.SubtotalAmount,
  o.FeesAmount,
  o.TotalAmount,
  o.HoldAmount,
  o.RefundedAmount,
  o.RecipientCount,
  ItemCount = COUNT(DISTINCT oi.OrderItemId),
  FulfilledRecipients = SUM(CASE WHEN r.Status = 'DELIVERED' THEN 1 ELSE 0 END),
  PendingRecipients = SUM(CASE WHEN r.Status = 'PENDING' THEN 1 ELSE 0 END),
  o.PlacedAtUtc,
  o.FulfilledAtUtc,
  o.UpdatedAtUtc
FROM orders.Orders o
JOIN core.Companies c ON c.CompanyId = o.CompanyId
JOIN auth.Users u ON u.UserId = o.CreatedByUserId
LEFT JOIN orders.OrderItems oi ON oi.OrderId = o.OrderId
LEFT JOIN orders.OrderRecipients r ON r.OrderId = o.OrderId
GROUP BY
  o.OrderId, o.OrderNumber, o.CompanyId, c.Name, o.CreatedByUserId, u.DisplayName,
  o.Status, o.Currency, o.SubtotalAmount, o.FeesAmount, o.TotalAmount,
  o.HoldAmount, o.RefundedAmount, o.RecipientCount, o.PlacedAtUtc,
  o.FulfilledAtUtc, o.UpdatedAtUtc;
GO

CREATE VIEW [wallet].[vwTopUpRequestSummary]
AS
SELECT
  t.TopUpRequestId,
  t.CompanyId,
  c.Name AS CompanyName,
  t.RequestedByUserId,
  ru.DisplayName AS RequestedByUserName,
  ru.Email AS RequestedByUserEmail,
  t.ApprovedByUserId,
  au.DisplayName AS ApprovedByUserName,
  t.Amount,
  t.Currency,
  t.Status,
  t.RequestedAtUtc,
  t.ApprovedAtUtc,
  t.RejectedAtUtc,
  DaysPending = DATEDIFF(DAY, t.RequestedAtUtc, COALESCE(t.ApprovedAtUtc, t.RejectedAtUtc, SYSUTCDATETIME())),
  t.Notes,
  t.RejectionReason
FROM wallet.TopUpRequests t
JOIN core.Companies c ON c.CompanyId = t.CompanyId
JOIN auth.Users ru ON ru.UserId = t.RequestedByUserId
LEFT JOIN auth.Users au ON au.UserId = t.ApprovedByUserId
WHERE c.DeletedAtUtc IS NULL;
GO

/* =========================================================
   10) STORED PROCEDURES (EXAMPLES)
   ========================================================= */

-- Procedure to get company wallet details
CREATE PROCEDURE [wallet].[sp_GetCompanyWalletDetails]
  @CompanyId BIGINT,
  @Currency CHAR(3) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SELECT * FROM wallet.vwCompanyWalletBalances
  WHERE CompanyId = @CompanyId
    AND (@Currency IS NULL OR Currency = @Currency);
END;
GO

-- Procedure to process top-up approval
CREATE PROCEDURE [wallet].[sp_ApproveTopUpRequest]
  @TopUpRequestId BIGINT,
  @ApprovedByUserId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRANSACTION;

  BEGIN TRY
    DECLARE @CompanyId BIGINT, @Amount DECIMAL(18,2), @Currency CHAR(3), @WalletId BIGINT;

    -- Get top-up details
    SELECT @CompanyId = CompanyId, @Amount = Amount, @Currency = Currency
    FROM wallet.TopUpRequests
    WHERE TopUpRequestId = @TopUpRequestId AND Status = 'REQUESTED';

    IF @CompanyId IS NULL
      THROW 50001, 'Top-up request not found or already processed', 1;

    -- Get or create wallet
    SELECT @WalletId = WalletId FROM wallet.Wallets
    WHERE CompanyId = @CompanyId AND Currency = @Currency;

    IF @WalletId IS NULL
    BEGIN
      INSERT INTO wallet.Wallets (CompanyId, Currency)
      VALUES (@CompanyId, @Currency);
      SET @WalletId = SCOPE_IDENTITY();
    END;

    -- Update top-up request
    UPDATE wallet.TopUpRequests
    SET Status = 'APPROVED',
        ApprovedByUserId = @ApprovedByUserId,
        ApprovedAtUtc = SYSUTCDATETIME()
    WHERE TopUpRequestId = @TopUpRequestId;

    -- Create transaction
    INSERT INTO wallet.Transactions (WalletId, Type, Status, Amount, Currency, ReferenceType, ReferenceId, Description, PostedAtUtc, CreatedBy)
    VALUES (@WalletId, 'TOP_UP', 'POSTED', @Amount, @Currency, 'TOPUP', @TopUpRequestId, 'Top-up credit', SYSUTCDATETIME(), @ApprovedByUserId);

    -- Update top-up status to POSTED
    UPDATE wallet.TopUpRequests
    SET Status = 'POSTED'
    WHERE TopUpRequestId = @TopUpRequestId;

    COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
  END CATCH;
END;
GO

/* =========================================================
   11) TRIGGERS (EXAMPLE - Auto-create wallet on company insert)
   ========================================================= */

CREATE TRIGGER [core].[trg_Companies_AfterInsert]
ON [core].[Companies]
AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;

  -- Auto-create wallet with default currency for new companies
  INSERT INTO wallet.Wallets (CompanyId, Currency)
  SELECT i.CompanyId, i.DefaultCurrency
  FROM inserted i;
END;
GO

/* =========================================================
   12) SAMPLE DATA SEED
   ========================================================= */

-- Create Super Admin company (for system use)
INSERT INTO core.Companies (CompanyCode, Name, Email, DefaultCurrency, IsActive)
VALUES ('SYSTEM', 'Kaman System', 'system@kaman.local', 'EGP', 1);

DECLARE @systemCompanyId BIGINT = SCOPE_IDENTITY();

-- Create Super Admin user (password should be hashed in application)
-- Using placeholder hash - REPLACE THIS IN PRODUCTION
INSERT INTO auth.Users (CompanyId, Email, DisplayName, PasswordHash, IsActive)
VALUES (NULL, 'superadmin@kaman.local', 'Super Administrator', 0x01020304, 1);

DECLARE @superAdminUserId BIGINT = SCOPE_IDENTITY();

-- Assign Super Admin role
INSERT INTO auth.UserRoles (UserId, RoleId)
SELECT @superAdminUserId, RoleId FROM auth.Roles WHERE Name = 'SUPER_ADMIN';

-- Create a demo company
INSERT INTO core.Companies (CompanyCode, Name, Email, Phone, Country, DefaultCurrency, MinimumBalance, IsActive)
VALUES ('DEMO001', 'Demo Corporation', 'admin@democorp.com', '+20123456789', 'Egypt', 'EGP', 0, 1);

DECLARE @demoCompanyId BIGINT = SCOPE_IDENTITY();

-- Create company admin for demo company
INSERT INTO auth.Users (CompanyId, Email, DisplayName, PasswordHash, IsActive)
VALUES (@demoCompanyId, 'admin@democorp.com', 'Demo Admin', 0x01020304, 1);

DECLARE @demoAdminUserId BIGINT = SCOPE_IDENTITY();

-- Assign Company Admin role
INSERT INTO auth.UserRoles (UserId, RoleId)
SELECT @demoAdminUserId, RoleId FROM auth.Roles WHERE Name = 'COMPANY_ADMIN';

GO

/* =========================================================
   13) ADDITIONAL INDEXES FOR PERFORMANCE
   ========================================================= */

-- Composite indexes for common queries
CREATE INDEX IX_Txn_Wallet_Status_Type ON [wallet].[Transactions](WalletId, Status, Type)
  INCLUDE (Amount, Currency, PostedAtUtc);

CREATE INDEX IX_Orders_Company_Status_Date ON [orders].[Orders](CompanyId, Status, PlacedAtUtc DESC)
  INCLUDE (OrderNumber, TotalAmount, Currency);

-- Filtered indexes for active records
CREATE INDEX IX_Companies_Active_NotDeleted ON [core].[Companies](IsActive)
  WHERE IsActive = 1 AND DeletedAtUtc IS NULL;

CREATE INDEX IX_Users_Active_NotDeleted ON [auth].[Users](IsActive, CompanyId)
  WHERE IsActive = 1 AND DeletedAtUtc IS NULL;

/* =========================================================
   END OF SCHEMA
   ========================================================= */
