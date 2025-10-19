/* =========================================================
   Kaman Gift Cards – SQL Server Schema (FIXED)
   - Replace CHECK-subqueries with FOREIGN KEYs
   - Separate batches for CREATE VIEW
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

/* 2) REFERENCE / LOOKUP TABLES */
CREATE TABLE [ref].[Currency](
  [CurrencyCode]  CHAR(3)      NOT NULL PRIMARY KEY,  -- 'EGP','SAR','USD'
  [Name]          NVARCHAR(64) NOT NULL
);
INSERT INTO [ref].[Currency] (CurrencyCode, Name)
VALUES ('EGP','Egyptian Pound'), ('SAR','Saudi Riyal'), ('USD','US Dollar');

CREATE TABLE [ref].[OrderStatus](
  [StatusCode] VARCHAR(24) NOT NULL PRIMARY KEY,
  [Description] NVARCHAR(128) NOT NULL
);
INSERT INTO [ref].[OrderStatus] (StatusCode, Description) VALUES
('PENDING','Created, awaiting processing'),
('ON_HOLD','Funds held, awaiting vendor purchase'),
('CONFIRMED','Purchase confirmed, assigning codes'),
('PARTIALLY_FULFILLED','Some codes assigned'),
('FULFILLED','All codes assigned'),
('CANCELLED','Cancelled, holds released'),
('FAILED','Failed, holds released');

CREATE TABLE [ref].[TxnType](
  [TypeCode] VARCHAR(24) NOT NULL PRIMARY KEY, -- 'TOP_UP','HOLD','PURCHASE','REFUND','HOLD_RELEASE'
  [Description] NVARCHAR(128) NOT NULL
);
INSERT INTO [ref].[TxnType] (TypeCode, Description) VALUES
('TOP_UP','Credit from admin approved top up'),
('HOLD','Order placement hold'),
('PURCHASE','Captured spend after fulfillment'),
('REFUND','Refund credit'),
('HOLD_RELEASE','Release hold back to balance');

CREATE TABLE [ref].[TxnStatus](
  [StatusCode] VARCHAR(24) NOT NULL PRIMARY KEY, -- 'PENDING','POSTED','CANCELLED'
  [Description] NVARCHAR(128) NOT NULL
);
INSERT INTO [ref].[TxnStatus] (StatusCode, Description) VALUES
('PENDING','Awaiting posting'),
('POSTED','Effective on balance'),
('CANCELLED','Voided / not effective');

/* 3) CORE */
CREATE TABLE [core].[Companies](
  [CompanyId]        BIGINT       IDENTITY(1,1) PRIMARY KEY,
  [CompanyCode]      VARCHAR(32)  NOT NULL UNIQUE,
  [Name]             NVARCHAR(200) NOT NULL,
  [Email]            NVARCHAR(256) NULL,
  [Phone]            NVARCHAR(64)  NULL,
  [Country]          NVARCHAR(64)  NULL,
  [DefaultCurrency]  CHAR(3)       NOT NULL DEFAULT 'EGP',
  [IsActive]         BIT           NOT NULL DEFAULT (1),
  [CreatedAtUtc]     DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
  [UpdatedAtUtc]     DATETIME2(3)  NULL,
  CONSTRAINT FK_Companies_Currency FOREIGN KEY ([DefaultCurrency]) REFERENCES [ref].[Currency]([CurrencyCode])
);
CREATE UNIQUE INDEX IX_Companies_Name ON [core].[Companies]([Name]);

/* 4) AUTH */
CREATE TABLE [auth].[Roles](
  [RoleId]   INT IDENTITY(1,1) PRIMARY KEY,
  [Name]     VARCHAR(50) NOT NULL UNIQUE -- 'SUPER_ADMIN','COMPANY_ADMIN'
);
INSERT INTO [auth].[Roles] (Name) VALUES ('SUPER_ADMIN'), ('COMPANY_ADMIN');

CREATE TABLE [auth].[Users](
  [UserId]        BIGINT IDENTITY(1,1) PRIMARY KEY,
  [CompanyId]     BIGINT NULL,  -- NULL for Super Admins
  [Email]         NVARCHAR(256) NOT NULL UNIQUE,
  [DisplayName]   NVARCHAR(128) NOT NULL,
  [PasswordHash]  VARBINARY(256) NOT NULL,  -- store hash only
  [PasswordSalt]  VARBINARY(128) NULL,
  [IsActive]      BIT NOT NULL DEFAULT (1),
  [CreatedAtUtc]  DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  [LastLoginUtc]  DATETIME2(3) NULL,
  CONSTRAINT FK_Users_Companies FOREIGN KEY (CompanyId) REFERENCES [core].[Companies](CompanyId)
);

CREATE TABLE [auth].[UserRoles](
  [UserId] BIGINT NOT NULL,
  [RoleId] INT NOT NULL,
  CONSTRAINT PK_UserRoles PRIMARY KEY (UserId, RoleId),
  CONSTRAINT FK_UserRoles_Users FOREIGN KEY (UserId) REFERENCES [auth].[Users](UserId),
  CONSTRAINT FK_UserRoles_Roles FOREIGN KEY (RoleId) REFERENCES [auth].[Roles](RoleId)
);

/* 5) WALLETS */
CREATE TABLE [wallet].[Wallets](
  [WalletId]      BIGINT IDENTITY(1,1) PRIMARY KEY,
  [CompanyId]     BIGINT  NOT NULL,
  [Currency]      CHAR(3) NOT NULL,
  [CreatedAtUtc]  DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_Wallets UNIQUE (CompanyId, Currency),
  CONSTRAINT FK_Wallets_Company FOREIGN KEY (CompanyId) REFERENCES [core].[Companies](CompanyId),
  CONSTRAINT FK_Wallets_Currency FOREIGN KEY ([Currency]) REFERENCES [ref].[Currency]([CurrencyCode])
);

CREATE TABLE [wallet].[Transactions](
  [TransactionId]       BIGINT IDENTITY(1,1) PRIMARY KEY,
  [WalletId]            BIGINT  NOT NULL,
  [Type]                VARCHAR(24) NOT NULL
      CONSTRAINT CK_Txn_Type CHECK (Type IN ('TOP_UP','HOLD','PURCHASE','REFUND','HOLD_RELEASE')),
  [Status]              VARCHAR(24) NOT NULL
      CONSTRAINT CK_Txn_Status CHECK (Status IN ('PENDING','POSTED','CANCELLED')),
  [Amount]              DECIMAL(18,2) NOT NULL,  -- positive; semantic sign by Type
  [Currency]            CHAR(3) NOT NULL,
  [ReferenceType]       VARCHAR(32) NULL,  -- 'TOPUP','ORDER'
  [ReferenceId]         BIGINT NULL,       -- TopUpRequestId or OrderId
  [Description]         NVARCHAR(256) NULL,
  [PostedAtUtc]         DATETIME2(3) NULL, -- when Status becomes POSTED
  [CreatedAtUtc]        DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_Txn_Wallet FOREIGN KEY (WalletId) REFERENCES [wallet].[Wallets](WalletId),
  CONSTRAINT FK_Txn_Currency FOREIGN KEY ([Currency]) REFERENCES [ref].[Currency]([CurrencyCode])
);
CREATE INDEX IX_Txn_Wallet ON [wallet].[Transactions](WalletId, Status, Type);
CREATE INDEX IX_Txn_Ref ON [wallet].[Transactions](ReferenceType, ReferenceId);

/* 6) TOP-UP REQUESTS */
CREATE TABLE [wallet].[TopUpRequests](
  [TopUpRequestId]    BIGINT IDENTITY(1,1) PRIMARY KEY,
  [CompanyId]         BIGINT NOT NULL,
  [RequestedByUserId] BIGINT NOT NULL,
  [ApprovedByUserId]  BIGINT NULL,
  [Amount]            DECIMAL(18,2) NOT NULL,
  [Currency]          CHAR(3) NOT NULL,
  [Status]            VARCHAR(24) NOT NULL  -- 'REQUESTED','APPROVED','REJECTED','CANCELLED','POSTED'
      CONSTRAINT CK_TopUp_Status CHECK (Status IN ('REQUESTED','APPROVED','REJECTED','CANCELLED','POSTED')),
  [RequestedAtUtc]    DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  [ApprovedAtUtc]     DATETIME2(3) NULL,
  [Notes]             NVARCHAR(256) NULL,
  CONSTRAINT FK_TopUp_Company FOREIGN KEY (CompanyId) REFERENCES [core].[Companies](CompanyId),
  CONSTRAINT FK_TopUp_ReqUser FOREIGN KEY (RequestedByUserId) REFERENCES [auth].[Users](UserId),
  CONSTRAINT FK_TopUp_AppUser FOREIGN KEY (ApprovedByUserId) REFERENCES [auth].[Users](UserId),
  CONSTRAINT FK_TopUp_Currency FOREIGN KEY ([Currency]) REFERENCES [ref].[Currency]([CurrencyCode])
);
CREATE INDEX IX_TopUp_Company ON [wallet].[TopUpRequests](CompanyId, Status);

/* 7) ORDERS */
CREATE SEQUENCE [orders].[SeqOrderNumber] AS BIGINT START WITH 100000 INCREMENT BY 1;
GO

CREATE TABLE [orders].[Orders](
  [OrderId]           BIGINT IDENTITY(1,1) PRIMARY KEY,
  [OrderNumber]       BIGINT NOT NULL DEFAULT (NEXT VALUE FOR [orders].[SeqOrderNumber]),
  [CompanyId]         BIGINT NOT NULL,
  [CreatedByUserId]   BIGINT NOT NULL,
  [Status]            VARCHAR(24) NOT NULL 
      CONSTRAINT CK_Orders_Status CHECK (Status IN ('PENDING','ON_HOLD','CONFIRMED','PARTIALLY_FULFILLED','FULFILLED','CANCELLED','FAILED')),
  [Vendor]            VARCHAR(50) NOT NULL DEFAULT 'RESAL',
  [Currency]          CHAR(3) NOT NULL,
  [SubtotalAmount]    DECIMAL(18,2) NOT NULL DEFAULT (0),
  [FeesAmount]        DECIMAL(18,2) NOT NULL DEFAULT (0),
  [TotalAmount]       DECIMAL(18,2) NOT NULL,
  [HoldAmount]        DECIMAL(18,2) NOT NULL DEFAULT (0),
  [RecipientCount]    INT NOT NULL DEFAULT (0),
  [PlacedAtUtc]       DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  [UpdatedAtUtc]      DATETIME2(3) NULL,
  [Notes]             NVARCHAR(512) NULL,
  CONSTRAINT UQ_Orders_OrderNumber UNIQUE ([OrderNumber]),
  CONSTRAINT FK_Orders_Company FOREIGN KEY (CompanyId) REFERENCES [core].[Companies](CompanyId),
  CONSTRAINT FK_Orders_User FOREIGN KEY (CreatedByUserId) REFERENCES [auth].[Users](UserId),
  CONSTRAINT FK_Orders_Currency FOREIGN KEY ([Currency]) REFERENCES [ref].[Currency]([CurrencyCode])
);
CREATE INDEX IX_Orders_CompanyStatus ON [orders].[Orders](CompanyId, Status);

CREATE TABLE [orders].[OrderItems](
  [OrderItemId]       BIGINT IDENTITY(1,1) PRIMARY KEY,
  [OrderId]           BIGINT NOT NULL,
  [VendorProductId]   NVARCHAR(100) NOT NULL,
  [ProductName]       NVARCHAR(200) NOT NULL,
  [Denomination]      DECIMAL(18,2) NOT NULL,
  [Quantity]          INT NOT NULL CHECK (Quantity > 0),
  [Currency]          CHAR(3) NOT NULL,
  [CreatedAtUtc]      DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_OrderItems_Order FOREIGN KEY (OrderId) REFERENCES [orders].[Orders](OrderId),
  CONSTRAINT FK_OrderItems_Currency FOREIGN KEY ([Currency]) REFERENCES [ref].[Currency]([CurrencyCode])
);
CREATE INDEX IX_OrderItems_Order ON [orders].[OrderItems](OrderId);

CREATE TABLE [orders].[OrderRecipients](
  [OrderRecipientId]  BIGINT IDENTITY(1,1) PRIMARY KEY,
  [OrderId]           BIGINT NOT NULL,
  [OrderItemId]       BIGINT NULL,
  [Email]             NVARCHAR(256) NOT NULL,
  [DisplayName]       NVARCHAR(128) NULL,
  [Status]            VARCHAR(24) NOT NULL DEFAULT 'PENDING' -- 'PENDING','ASSIGNED','SENT','DELIVERED','FAILED'
      CONSTRAINT CK_Recipients_Status CHECK (Status IN ('PENDING','ASSIGNED','SENT','DELIVERED','FAILED')),
  [CreatedAtUtc]      DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  [UpdatedAtUtc]      DATETIME2(3) NULL,
  CONSTRAINT FK_Recipients_Order FOREIGN KEY (OrderId) REFERENCES [orders].[Orders](OrderId),
  CONSTRAINT FK_Recipients_OrderItem FOREIGN KEY (OrderItemId) REFERENCES [orders].[OrderItems](OrderItemId)
);
CREATE INDEX IX_Recipients_Order ON [orders].[OrderRecipients](OrderId);

CREATE TABLE [orders].[GiftCardAssignments](
  [AssignmentId]      BIGINT IDENTITY(1,1) PRIMARY KEY,
  [OrderId]           BIGINT NOT NULL,
  [OrderItemId]       BIGINT NOT NULL,
  [OrderRecipientId]  BIGINT NOT NULL,
  [Code]              NVARCHAR(200) NOT NULL,
  [Pin]               NVARCHAR(200) NULL,
  [RedeemUrl]         NVARCHAR(500) NULL,
  [ExpiryDateUtc]     DATETIME2(3) NULL,
  [AssignedAtUtc]     DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  [DeliveredAtUtc]    DATETIME2(3) NULL,
  [DeliveryStatus]    VARCHAR(24) NOT NULL DEFAULT 'PENDING' -- 'PENDING','EMAIL_QUEUED','EMAIL_SENT','EMAIL_FAILED'
      CONSTRAINT CK_Assign_DeliveryStatus CHECK (DeliveryStatus IN ('PENDING','EMAIL_QUEUED','EMAIL_SENT','EMAIL_FAILED')),
  [VendorPayloadJson] NVARCHAR(MAX) NULL,
  CONSTRAINT UQ_Assignment_Recipient UNIQUE (OrderRecipientId),
  CONSTRAINT FK_Assign_Order FOREIGN KEY (OrderId) REFERENCES [orders].[Orders](OrderId),
  CONSTRAINT FK_Assign_Item FOREIGN KEY (OrderItemId) REFERENCES [orders].[OrderItems](OrderItemId),
  CONSTRAINT FK_Assign_Recipient FOREIGN KEY (OrderRecipientId) REFERENCES [orders].[OrderRecipients](OrderRecipientId)
);
CREATE INDEX IX_Assign_Order ON [orders].[GiftCardAssignments](OrderId);

CREATE TABLE [orders].[EmailNotifications](
  [EmailNotificationId] BIGINT IDENTITY(1,1) PRIMARY KEY,
  [OrderId]             BIGINT NOT NULL,
  [ToEmail]             NVARCHAR(256) NOT NULL,
  [Subject]             NVARCHAR(256) NOT NULL,
  [Body]                NVARCHAR(MAX) NOT NULL,
  [Status]              VARCHAR(24) NOT NULL DEFAULT 'QUEUED' -- 'QUEUED','SENT','FAILED'
      CONSTRAINT CK_Email_Status CHECK (Status IN ('QUEUED','SENT','FAILED')),
  [CreatedAtUtc]        DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  [SentAtUtc]           DATETIME2(3) NULL,
  [ErrorMessage]        NVARCHAR(512) NULL,
  CONSTRAINT FK_Email_Order FOREIGN KEY (OrderId) REFERENCES [orders].[Orders](OrderId)
);
CREATE INDEX IX_Email_Order ON [orders].[EmailNotifications](OrderId);

CREATE TABLE [vendor].[ResalPurchases](
  [ResalPurchaseId]  BIGINT IDENTITY(1,1) PRIMARY KEY,
  [OrderId]          BIGINT NOT NULL,
  [RequestId]        NVARCHAR(100) NULL,
  [VendorOrderId]    NVARCHAR(100) NULL,
  [Status]           VARCHAR(24) NOT NULL DEFAULT 'REQUESTED' -- 'REQUESTED','SUCCESS','PARTIAL','FAILED'
      CONSTRAINT CK_Resal_Status CHECK (Status IN ('REQUESTED','SUCCESS','PARTIAL','FAILED')),
  [RequestedAtUtc]   DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  [RespondedAtUtc]   DATETIME2(3) NULL,
  [RequestJson]      NVARCHAR(MAX) NULL,
  [ResponseJson]     NVARCHAR(MAX) NULL,
  CONSTRAINT FK_Resal_Order FOREIGN KEY (OrderId) REFERENCES [orders].[Orders](OrderId)
);
CREATE INDEX IX_Resal_Order ON [vendor].[ResalPurchases](OrderId);

/* 8) VIEW – Wallet balances (separate batch required) */
GO
CREATE VIEW [wallet].[vwCompanyWalletBalances]
AS
SELECT
  c.CompanyId,
  w.WalletId,
  w.Currency,
  Available = 
      (  ISNULL(SUM(CASE WHEN t.Status='POSTED' AND t.Type IN ('TOP_UP','REFUND','HOLD_RELEASE') THEN t.Amount ELSE 0 END), 0)
       - ISNULL(SUM(CASE WHEN t.Status='POSTED' AND t.Type = 'PURCHASE' THEN t.Amount ELSE 0 END), 0)
       - ISNULL(SUM(CASE WHEN t.Status='POSTED' AND t.Type = 'HOLD' THEN t.Amount ELSE 0 END), 0)
      ),
  OnHold =
      ISNULL(SUM(CASE WHEN t.Status='POSTED' AND t.Type='HOLD' THEN t.Amount ELSE 0 END), 0),
  TotalSpendings =
      ISNULL(SUM(CASE WHEN t.Status='POSTED' AND t.Type='PURCHASE' THEN t.Amount ELSE 0 END), 0)
FROM core.Companies c
JOIN wallet.Wallets w ON w.CompanyId = c.CompanyId
LEFT JOIN wallet.Transactions t ON t.WalletId = w.WalletId
GROUP BY c.CompanyId, w.WalletId, w.Currency;
GO

/* 9) CONVENIENCE INDEXES (extra) */
CREATE INDEX IX_Orders_OrderNumber ON [orders].[Orders]([OrderNumber]);
CREATE INDEX IX_Recipients_Email ON [orders].[OrderRecipients]([Email]);

/* 10) SAMPLE ADMIN SEED (optional) */
/*
INSERT INTO core.Companies (CompanyCode, Name, DefaultCurrency) VALUES ('KAMAN','Kaman Super Admin Org','EGP');
DECLARE @companyId BIGINT = SCOPE_IDENTITY();

-- Password hash should be generated in application code; using 0x placeholder here.
INSERT INTO auth.Users (CompanyId, Email, DisplayName, PasswordHash)
VALUES (NULL, 'superadmin@kaman.local', N'Super Admin', 0x01020304);

DECLARE @userId BIGINT = SCOPE_IDENTITY();
INSERT INTO auth.UserRoles (UserId, RoleId) SELECT @userId, RoleId FROM auth.Roles WHERE Name='SUPER_ADMIN';
*/
