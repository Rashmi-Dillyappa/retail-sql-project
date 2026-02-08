1️⃣ Assessment & Planning – Analyze database size, schema, stored procedures, triggers, dependencies

In SQL Server, you can use system views to check database structure, table sizes, stored procedures, and triggers.

a) Database size per table:

-- Shows table name and size in MB
SELECT 
    t.NAME AS TableName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 / 1024 AS TotalSizeMB,
    SUM(a.used_pages) * 8 / 1024 AS UsedSizeMB,
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 / 1024 AS UnusedSizeMB
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY 
    t.NAME, p.rows
ORDER BY TotalSizeMB DESC;


b) List stored procedures and triggers

-- Stored procedures
SELECT name, create_date, modify_date
FROM sys.procedures;

-- Triggers
SELECT name, parent_class_desc, create_date
FROM sys.triggers;


c) Dependencies

-- Find dependencies of a specific table
SELECT 
    referencing_object_name = o.name,
    referencing_object_type_desc = o.type_desc
FROM sys.sql_expression_dependencies d
JOIN sys.objects o ON d.referencing_id = o.object_id
WHERE d.referenced_entity_name = 'Transactions';


✅ This helps you plan which tables and procedures are critical and which can migrate first.

2️⃣ Azure Data Migration Service (DMS)

Azure DMS is a tool in Azure that migrates SQL Server databases to Azure SQL with minimal downtime.

You don’t write code, you create a migration project in Azure Portal:

Source: On-Prem SQL Server

Target: Azure SQL Database / Managed Instance

Choose tables, schema, and business logic

Run online migration for live data or offline migration for non-critical data

💡 Think of DMS as a wizard tool that handles schema, data, and some logic migration automatically.

3️⃣ Bulk Copy for Large Transaction Tables

For millions of rows, you don’t insert all at once; use batch inserts. Example using T-SQL:

DECLARE @BatchSize INT = 10000;
DECLARE @MinID INT, @MaxID INT;

-- Get min and max TransactionID
SELECT @MinID = MIN(TransactionID), @MaxID = MAX(TransactionID)
FROM Transactions;

WHILE @MinID <= @MaxID
BEGIN
    -- Insert batch into Azure SQL table
    INSERT INTO AzureTransactions (TransactionID, BuyerID, VendorID, ProductID, Quantity, Timestamp)
    SELECT TOP (@BatchSize) TransactionID, BuyerID, VendorID, ProductID, Quantity, Timestamp
    FROM Transactions
    WHERE TransactionID >= @MinID
    ORDER BY TransactionID;

    -- Move to next batch
    SET @MinID = @MinID + @BatchSize;
END


Logic: Insert 10k rows at a time to reduce downtime and avoid locks.

You can also use bcp command-line tool or Azure Data Factory for large-scale parallel migration.

4️⃣ Testing & Validation

a) Row counts comparison

-- Compare number of rows between source and target
SELECT 
    (SELECT COUNT(*) FROM Transactions) AS SourceCount,
    (SELECT COUNT(*) FROM AzureTransactions) AS TargetCount;


b) Checksum validation

-- Generate a checksum for entire table
SELECT CHECKSUM_AGG(BINARY_CHECKSUM(*)) AS SourceChecksum FROM Transactions;
SELECT CHECKSUM_AGG(BINARY_CHECKSUM(*)) AS TargetChecksum FROM AzureTransactions;


✅ If checksums match → data migrated correctly.

c) Sample transaction reconciliation

-- Compare 5 sample transactions
SELECT TOP 5 * FROM Transactions
EXCEPT
SELECT TOP 5 * FROM AzureTransactions;


d) Validate relationships

-- Ensure every Transaction has a valid Buyer, Vendor, Store
SELECT * 
FROM AzureTransactions t
LEFT JOIN AzureBuyers b ON t.BuyerID = b.BuyerID
LEFT JOIN AzureVendors v ON t.VendorID = v.VendorID
LEFT JOIN AzureStores s ON t.StoreID = s.StoreID
WHERE b.BuyerID IS NULL OR v.VendorID IS NULL OR s.StoreID IS NULL;

5️⃣ Business Logic Compatibility (Stored Procedures)

Some on-prem T-SQL functions may not work in Azure SQL, e.g., linked server queries:

On-prem stored procedure using linked server:

CREATE PROCEDURE GetVendorSales
AS
SELECT v.VendorName, SUM(t.Quantity) AS TotalQty
FROM Transactions t
JOIN [OnPremServer].[DB].[dbo].Vendors v ON t.VendorID = v.VendorID
GROUP BY v.VendorName;


Azure SQL-compatible version:

Use temporary tables or import Vendors table into Azure SQL first.

CREATE PROCEDURE GetVendorSales
AS
BEGIN
    -- Use local Azure Vendors table
    SELECT v.VendorName, SUM(t.Quantity) AS TotalQty
    FROM AzureTransactions t
    JOIN AzureVendors v ON t.VendorID = v.VendorID
    GROUP BY v.VendorName;
END

6️⃣ Delta Migration / Minimal Downtime

For live systems, you migrate non-critical tables first (like master data: Buyers, Vendors).

Transactions table is active → final migration done overnight with only recent changes:

Delta logic example:

-- Only migrate transactions after last migrated timestamp
INSERT INTO AzureTransactions (TransactionID, BuyerID, VendorID, ProductID, Quantity, Timestamp)
SELECT TransactionID, BuyerID, VendorID, ProductID, Quantity, Timestamp
FROM Transactions
WHERE Timestamp > '2026-02-07 00:00:00'; -- last migration


✅ This ensures minimal downtime and live system keeps running.
