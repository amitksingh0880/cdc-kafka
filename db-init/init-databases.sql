-- =====================================================
-- Insurance Microservices Database Initialization
-- Creates databases with CDC enabled for:
-- 1. PolicyServiceDB
-- 2. ClaimsServiceDB  
-- 3. CustomerServiceDB
-- =====================================================

USE master;
GO

-- Enable SQL Server Agent (required for CDC)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Agent XPs', 1;
RECONFIGURE;
GO

-- =====================================================
-- 1. POLICY SERVICE DATABASE
-- =====================================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'PolicyServiceDB')
BEGIN
    CREATE DATABASE PolicyServiceDB;
END
GO

USE PolicyServiceDB;
GO

-- Enable CDC on database
EXEC sys.sp_cdc_enable_db;
GO

-- Policies Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Policies')
BEGIN
    CREATE TABLE Policies (
        id INT IDENTITY(1,1) PRIMARY KEY,
        customer_id INT NOT NULL,
        policy_number NVARCHAR(50) NOT NULL UNIQUE,
        policy_type NVARCHAR(50) NOT NULL, -- AUTO, HOME, LIFE, HEALTH
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        status NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, EXPIRED, CANCELLED, PENDING
        premium_amount DECIMAL(10,2) NOT NULL,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE()
    );
    
    -- Enable CDC on Policies table
    EXEC sys.sp_cdc_enable_table
        @source_schema = 'dbo',
        @source_name = 'Policies',
        @role_name = NULL,
        @supports_net_changes = 1;
END
GO

-- Coverage Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Coverage')
BEGIN
    CREATE TABLE Coverage (
        id INT IDENTITY(1,1) PRIMARY KEY,
        policy_id INT NOT NULL FOREIGN KEY REFERENCES Policies(id),
        coverage_type NVARCHAR(100) NOT NULL, -- LIABILITY, COLLISION, COMPREHENSIVE, etc.
        coverage_limit DECIMAL(12,2) NOT NULL,
        deductible DECIMAL(10,2) NOT NULL,
        created_at DATETIME2 DEFAULT GETDATE()
    );
    
    EXEC sys.sp_cdc_enable_table
        @source_schema = 'dbo',
        @source_name = 'Coverage',
        @role_name = NULL,
        @supports_net_changes = 1;
END
GO

-- Premiums Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Premiums')
BEGIN
    CREATE TABLE Premiums (
        id INT IDENTITY(1,1) PRIMARY KEY,
        policy_id INT NOT NULL FOREIGN KEY REFERENCES Policies(id),
        amount DECIMAL(10,2) NOT NULL,
        due_date DATE NOT NULL,
        paid_date DATE NULL,
        payment_status NVARCHAR(20) NOT NULL DEFAULT 'PENDING', -- PENDING, PAID, OVERDUE
        created_at DATETIME2 DEFAULT GETDATE()
    );
    
    EXEC sys.sp_cdc_enable_table
        @source_schema = 'dbo',
        @source_name = 'Premiums',
        @role_name = NULL,
        @supports_net_changes = 1;
END
GO

-- =====================================================
-- 2. CLAIMS SERVICE DATABASE
-- =====================================================
USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ClaimsServiceDB')
BEGIN
    CREATE DATABASE ClaimsServiceDB;
END
GO

USE ClaimsServiceDB;
GO

EXEC sys.sp_cdc_enable_db;
GO

-- Claims Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Claims')
BEGIN
    CREATE TABLE Claims (
        id INT IDENTITY(1,1) PRIMARY KEY,
        policy_id INT NOT NULL,
        customer_id INT NOT NULL,
        claim_number NVARCHAR(50) NOT NULL UNIQUE,
        claim_date DATE NOT NULL,
        incident_date DATE NOT NULL,
        description NVARCHAR(MAX),
        status NVARCHAR(30) NOT NULL DEFAULT 'SUBMITTED', -- SUBMITTED, UNDER_REVIEW, APPROVED, DENIED, PAID
        amount_claimed DECIMAL(12,2) NOT NULL,
        amount_approved DECIMAL(12,2) NULL,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE()
    );
    
    EXEC sys.sp_cdc_enable_table
        @source_schema = 'dbo',
        @source_name = 'Claims',
        @role_name = NULL,
        @supports_net_changes = 1;
END
GO

-- Claim Documents Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ClaimDocuments')
BEGIN
    CREATE TABLE ClaimDocuments (
        id INT IDENTITY(1,1) PRIMARY KEY,
        claim_id INT NOT NULL FOREIGN KEY REFERENCES Claims(id),
        document_type NVARCHAR(50) NOT NULL, -- POLICE_REPORT, PHOTO, INVOICE, MEDICAL_RECORD
        file_path NVARCHAR(500) NOT NULL,
        uploaded_at DATETIME2 DEFAULT GETDATE()
    );
    
    EXEC sys.sp_cdc_enable_table
        @source_schema = 'dbo',
        @source_name = 'ClaimDocuments',
        @role_name = NULL,
        @supports_net_changes = 1;
END
GO

-- Claim Payments Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ClaimPayments')
BEGIN
    CREATE TABLE ClaimPayments (
        id INT IDENTITY(1,1) PRIMARY KEY,
        claim_id INT NOT NULL FOREIGN KEY REFERENCES Claims(id),
        amount DECIMAL(12,2) NOT NULL,
        payment_date DATE NOT NULL,
        payment_method NVARCHAR(50) NOT NULL, -- CHECK, BANK_TRANSFER, DIRECT_DEPOSIT
        reference_number NVARCHAR(100),
        created_at DATETIME2 DEFAULT GETDATE()
    );
    
    EXEC sys.sp_cdc_enable_table
        @source_schema = 'dbo',
        @source_name = 'ClaimPayments',
        @role_name = NULL,
        @supports_net_changes = 1;
END
GO

-- =====================================================
-- 3. CUSTOMER SERVICE DATABASE
-- =====================================================
USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'CustomerServiceDB')
BEGIN
    CREATE DATABASE CustomerServiceDB;
END
GO

USE CustomerServiceDB;
GO

EXEC sys.sp_cdc_enable_db;
GO

-- Customers Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Customers')
BEGIN
    CREATE TABLE Customers (
        id INT IDENTITY(1,1) PRIMARY KEY,
        first_name NVARCHAR(100) NOT NULL,
        last_name NVARCHAR(100) NOT NULL,
        email NVARCHAR(255) NOT NULL UNIQUE,
        phone NVARCHAR(20),
        date_of_birth DATE,
        ssn_last4 NVARCHAR(4),
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE()
    );
    
    EXEC sys.sp_cdc_enable_table
        @source_schema = 'dbo',
        @source_name = 'Customers',
        @role_name = NULL,
        @supports_net_changes = 1;
END
GO

-- Addresses Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Addresses')
BEGIN
    CREATE TABLE Addresses (
        id INT IDENTITY(1,1) PRIMARY KEY,
        customer_id INT NOT NULL FOREIGN KEY REFERENCES Customers(id),
        address_type NVARCHAR(20) NOT NULL, -- HOME, MAILING, WORK
        street NVARCHAR(255) NOT NULL,
        city NVARCHAR(100) NOT NULL,
        state NVARCHAR(50) NOT NULL,
        postal_code NVARCHAR(20) NOT NULL,
        created_at DATETIME2 DEFAULT GETDATE()
    );
    
    EXEC sys.sp_cdc_enable_table
        @source_schema = 'dbo',
        @source_name = 'Addresses',
        @role_name = NULL,
        @supports_net_changes = 1;
END
GO

-- Beneficiaries Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Beneficiaries')
BEGIN
    CREATE TABLE Beneficiaries (
        id INT IDENTITY(1,1) PRIMARY KEY,
        customer_id INT NOT NULL FOREIGN KEY REFERENCES Customers(id),
        policy_id INT NOT NULL,
        name NVARCHAR(200) NOT NULL,
        relationship NVARCHAR(50) NOT NULL, -- SPOUSE, CHILD, PARENT, SIBLING, OTHER
        percentage DECIMAL(5,2) NOT NULL CHECK (percentage > 0 AND percentage <= 100),
        created_at DATETIME2 DEFAULT GETDATE()
    );
    
    EXEC sys.sp_cdc_enable_table
        @source_schema = 'dbo',
        @source_name = 'Beneficiaries',
        @role_name = NULL,
        @supports_net_changes = 1;
END
GO

-- =====================================================
-- INSERT SAMPLE DATA
-- =====================================================

-- Sample Customers
USE CustomerServiceDB;
GO

INSERT INTO Customers (first_name, last_name, email, phone, date_of_birth, ssn_last4)
VALUES 
    ('John', 'Smith', 'john.smith@email.com', '555-0101', '1985-03-15', '1234'),
    ('Sarah', 'Johnson', 'sarah.johnson@email.com', '555-0102', '1990-07-22', '5678'),
    ('Michael', 'Williams', 'michael.williams@email.com', '555-0103', '1978-11-08', '9012');

INSERT INTO Addresses (customer_id, address_type, street, city, state, postal_code)
VALUES 
    (1, 'HOME', '123 Main Street', 'New York', 'NY', '10001'),
    (2, 'HOME', '456 Oak Avenue', 'Los Angeles', 'CA', '90001'),
    (3, 'HOME', '789 Pine Road', 'Chicago', 'IL', '60601');

-- Sample Policies
USE PolicyServiceDB;
GO

INSERT INTO Policies (customer_id, policy_number, policy_type, start_date, end_date, status, premium_amount)
VALUES 
    (1, 'POL-AUTO-001', 'AUTO', '2026-01-01', '2027-01-01', 'ACTIVE', 1200.00),
    (1, 'POL-HOME-001', 'HOME', '2026-01-01', '2027-01-01', 'ACTIVE', 1800.00),
    (2, 'POL-LIFE-001', 'LIFE', '2026-01-01', '2046-01-01', 'ACTIVE', 600.00),
    (3, 'POL-HEALTH-001', 'HEALTH', '2026-01-01', '2027-01-01', 'ACTIVE', 4800.00);

INSERT INTO Coverage (policy_id, coverage_type, coverage_limit, deductible)
VALUES 
    (1, 'LIABILITY', 100000.00, 500.00),
    (1, 'COLLISION', 50000.00, 1000.00),
    (2, 'DWELLING', 300000.00, 2500.00),
    (3, 'DEATH_BENEFIT', 500000.00, 0.00);

INSERT INTO Premiums (policy_id, amount, due_date, payment_status)
VALUES 
    (1, 100.00, '2026-02-01', 'PENDING'),
    (2, 150.00, '2026-02-01', 'PENDING'),
    (3, 50.00, '2026-02-01', 'PENDING'),
    (4, 400.00, '2026-02-01', 'PENDING');

-- Sample Beneficiaries
USE CustomerServiceDB;
GO

INSERT INTO Beneficiaries (customer_id, policy_id, name, relationship, percentage)
VALUES 
    (2, 3, 'David Johnson', 'SPOUSE', 50.00),
    (2, 3, 'Emily Johnson', 'CHILD', 50.00);

-- Sample Claims
USE ClaimsServiceDB;
GO

INSERT INTO Claims (policy_id, customer_id, claim_number, claim_date, incident_date, description, status, amount_claimed)
VALUES 
    (1, 1, 'CLM-2026-001', '2026-01-02', '2026-01-01', 'Minor fender bender in parking lot', 'UNDER_REVIEW', 2500.00);

PRINT 'Database initialization complete. All CDC-enabled tables created.';
GO
