Step 1: Incremental Load into Staging
CREATE TEMP TABLE stg_customer AS
SELECT *
FROM source_customer s
WHERE s.last_updated_at > (
    SELECT COALESCE(MAX(last_updated_at), '1900-01-01'::timestamp)
    FROM dim_customer
);


✅ 1900-01-01 ensures first load works if dim table is empty.

🔹 Step 2A: SCD Type 1 – Overwrite Latest Values
-- 1. Update existing records if changed
UPDATE dim_customer t
SET name = s.name,
    email = s.email,
    plan_type = s.plan_type,
    address = s.address,
    last_updated_at = s.last_updated_at,
    inserted_at = GETDATE()
FROM stg_customer s
WHERE t.customer_id = s.customer_id
  AND s.last_updated_at > t.last_updated_at;

-- 2. Insert new customers not yet in dim
INSERT INTO dim_customer (
    customer_id, name, email, plan_type, address, start_date, end_date, is_current, last_updated_at
)
SELECT 
    s.customer_id, s.name, s.email, s.plan_type, s.address,
    CURRENT_DATE, NULL, 'Y', s.last_updated_at
FROM stg_customer s
LEFT JOIN dim_customer t
  ON s.customer_id = t.customer_id
WHERE t.customer_id IS NULL;


✅ Result: Always only the latest info per customer. No history is kept.

🔹 Step 2B: SCD Type 2 – Maintain Historical Versions
-- 1. Close old versions if changes detected
UPDATE dim_customer t
SET end_date = CURRENT_DATE - 1,
    is_current = 'N'
FROM stg_customer s
WHERE t.customer_id = s.customer_id
  AND t.is_current = 'Y'
  AND (
      t.name      <> s.name OR
      t.email     <> s.email OR
      t.plan_type <> s.plan_type OR
      t.address   <> s.address
  );

-- 2. Insert new version for changed or new customers
INSERT INTO dim_customer (
    customer_id, name, email, plan_type, address, start_date, end_date, is_current, last_updated_at
)
SELECT 
    s.customer_id, s.name, s.email, s.plan_type, s.address,
    CURRENT_DATE, NULL, 'Y', s.last_updated_at
FROM stg_customer s
LEFT JOIN dim_customer t
  ON s.customer_id = t.customer_id
 AND t.is_current = 'Y'
WHERE t.customer_id IS NULL
   OR t.name      <> s.name
   OR t.email     <> s.email
   OR t.plan_type <> s.plan_type
   OR t.address   <> s.address;


✅ Result:

Historical versions preserved.

Active record has is_current = 'Y' and end_date = NULL.

Previous version has is_current = 'N' and proper end_date.
