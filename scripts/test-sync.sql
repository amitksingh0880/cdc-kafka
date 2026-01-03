-- =====================================================
-- Test Script: CDC Synchronization Verification
-- Run this script to test data changes are captured
-- =====================================================

USE PolicyServiceDB;
GO

-- Insert a new policy
PRINT 'Inserting new AUTO policy...';
INSERT INTO Policies (customer_id, policy_number, policy_type, start_date, end_date, status, premium_amount)
VALUES (1, 'POL-TEST-' + CONVERT(VARCHAR, GETDATE(), 112) + '-' + CONVERT(VARCHAR, DATEPART(MS, GETDATE())), 
        'AUTO', GETDATE(), DATEADD(YEAR, 1, GETDATE()), 'ACTIVE', 850.00);

DECLARE @newPolicyId INT = SCOPE_IDENTITY();
PRINT 'Created Policy ID: ' + CAST(@newPolicyId AS VARCHAR);

-- Add coverage for the policy
PRINT 'Adding coverage...';
INSERT INTO Coverage (policy_id, coverage_type, coverage_limit, deductible)
VALUES (@newPolicyId, 'LIABILITY', 50000.00, 500.00);

-- Add premium payment record
PRINT 'Adding premium record...';
INSERT INTO Premiums (policy_id, amount, due_date, payment_status)
VALUES (@newPolicyId, 70.83, DATEADD(MONTH, 1, GETDATE()), 'PENDING');

GO

-- Update an existing policy
PRINT 'Updating policy status...';
UPDATE Policies 
SET status = 'RENEWED', updated_at = GETDATE()
WHERE policy_number = 'POL-AUTO-001';
GO

-- Test Claims
USE ClaimsServiceDB;
GO

PRINT 'Creating new claim...';
INSERT INTO Claims (policy_id, customer_id, claim_number, claim_date, incident_date, description, status, amount_claimed)
VALUES (1, 1, 'CLM-TEST-' + CONVERT(VARCHAR, GETDATE(), 112), GETDATE(), DATEADD(DAY, -1, GETDATE()), 
        'Test claim for CDC verification - minor damage', 'SUBMITTED', 1500.00);

DECLARE @newClaimId INT = SCOPE_IDENTITY();

-- Add document to claim
INSERT INTO ClaimDocuments (claim_id, document_type, file_path)
VALUES (@newClaimId, 'PHOTO', '/uploads/claims/test-photo.jpg');
GO

-- Test Customers
USE CustomerServiceDB;
GO

PRINT 'Adding new customer...';
INSERT INTO Customers (first_name, last_name, email, phone, date_of_birth, ssn_last4)
VALUES ('Test', 'Customer', 'test.customer.' + CONVERT(VARCHAR, GETDATE(), 112) + '@email.com', 
        '555-9999', '1990-01-15', '0000');

DECLARE @newCustomerId INT = SCOPE_IDENTITY();

INSERT INTO Addresses (customer_id, address_type, street, city, state, postal_code)
VALUES (@newCustomerId, 'HOME', '999 Test Street', 'Test City', 'TX', '75001');
GO

PRINT '';
PRINT '============================================';
PRINT 'Test data inserted successfully!';
PRINT '============================================';
PRINT '';
PRINT 'Check Kafka UI at http://localhost:8080 to see CDC events';
PRINT 'Or run: docker exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic insurance.PolicyServiceDB.dbo.Policies --from-beginning';
GO
