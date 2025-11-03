🌏 Business Context
Source System: Operational DB (e.g., customer management system)

Target: Data Warehouse (DWH)
Tables involved:

stg_customer – staging data loaded daily from source
dim_customer – dimension table in DWH
fact_energy_usage – fact table for energy consumption
stg_energy_usage – staging table for incremental load

🧩 1. Incremental Load (Change Capture)

Goal: Load only new or updated rows from the source.

Let’s assume the source_customer table has a column last_updated_at.

🟢 Step 1: Extract to Staging
-- Load only changed/new customers from source to staging
INSERT INTO stg_customer
SELECT *
FROM source_customer s
WHERE s.last_updated_at > (
    SELECT COALESCE(MAX(last_updated_at), '1900-01-01')
    FROM dim_customer
);


🔍 This ensures only records updated after the last load are brought in.

🟢 Step 2: Incremental Load for Fact Table
-- Load only new consumption data
INSERT INTO fact_energy_usage (customer_id, billing_month, usage_kwh, cost, last_updated_at)
SELECT s.customer_id, s.billing_month, s.usage_kwh, s.cost, s.last_updated_at
FROM stg_energy_usage s
LEFT JOIN fact_energy_usage f
  ON s.customer_id = f.customer_id
 AND s.billing_month = f.billing_month
WHERE f.customer_id IS NULL 
   OR s.last_updated_at > f.last_updated_at;


⚡ This handles insert + update logic — new or changed usage data only.

🔍 2. Data Validation Queries
✅ a. Count Match
-- Compare source vs target row counts
SELECT 
  (SELECT COUNT(*) FROM stg_customer) AS staging_count,
  (SELECT COUNT(*) FROM dim_customer) AS dim_count;

✅ b. Null Check
-- Find records with null business keys
SELECT *
FROM dim_customer
WHERE customer_id IS NULL 
   OR customer_name IS NULL;

✅ c. Duplicate Check
-- Detect duplicate customer IDs in the dimension
SELECT customer_id, COUNT(*) 
FROM dim_customer
GROUP BY customer_id
HAVING COUNT(*) > 1;

🧱 3. Slowly Changing Dimension (SCD)

Let’s handle customer profile changes.

🧩 Example columns
dim_customer (
  customer_key SERIAL PRIMARY KEY,
  customer_id VARCHAR(20),
  customer_name VARCHAR(100),
  address VARCHAR(200),
  start_date DATE,
  end_date DATE,
  current_flag CHAR(1),
  last_updated_at TIMESTAMP
)

🟣 SCD Type 1 — Overwrite changes (no history)

Used for non-historical data (e.g., customer name correction).

-- Type 1: Update in place
UPDATE dim_customer d
SET
  customer_name = s.customer_name,
  address = s.address,
  last_updated_at = s.last_updated_at
FROM stg_customer s
WHERE d.customer_id = s.customer_id
  AND (
       d.customer_name <> s.customer_name
    OR d.address <> s.address
  );


✅ Overwrites existing values without keeping old versions.

🔵 SCD Type 2 — Track history with new version

Used for historical tracking (e.g., address changes).

-- 1️⃣ Expire old records
UPDATE dim_customer d
SET end_date = CURRENT_DATE - INTERVAL '1 day',
    current_flag = 'N'
FROM stg_customer s
WHERE d.customer_id = s.customer_id
  AND d.current_flag = 'Y'
  AND (d.address <> s.address OR d.customer_name <> s.customer_name);

-- 2️⃣ Insert new active record
INSERT INTO dim_customer (
  customer_id, customer_name, address,
  start_date, end_date, current_flag, last_updated_at
)
SELECT
  s.customer_id, s.customer_name, s.address,
  CURRENT_DATE, '9999-12-31', 'Y', s.last_updated_at
FROM stg_customer s
LEFT JOIN dim_customer d
  ON s.customer_id = d.customer_id
 AND d.current_flag = 'Y'
WHERE d.customer_id IS NULL
   OR (d.address <> s.address OR d.customer_name <> s.customer_name);


🔄 This keeps old records as historical (with end_date set) and inserts new active ones.

📊 Bonus: Validation after SCD Load
-- Check for overlapping active periods
SELECT customer_id
FROM dim_customer
GROUP BY customer_id
HAVING SUM(CASE WHEN current_flag = 'Y' THEN 1 ELSE 0 END) > 1;

✅ Summary ETL Flow for Origin Energy
Step	Process	SQL Object	Description
1	Extract	stg_customer, stg_energy_usage	Incremental extract using timestamp
2	Validate	COUNT, NULL, DUPLICATE	Quality checks before load
3	Load	dim_customer, fact_energy_usage	Incremental insert/update
4	Transform	SCD Type 1/2	Maintain dimension history
5	Validate	Reconciliation queries	Confirm data accuracy
