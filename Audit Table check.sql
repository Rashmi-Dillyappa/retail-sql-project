🧭 Step 1: Load Raw Data (temporary / landing zone)

Let’s assume data lands in:

staging.customer_usage_raw


Fields:

(customer_id, meter_reading_date, usage_kwh, meter_id, updated_timestamp)

✅ Step 2: Data Validation (before loading into staging_main)

We perform validation checks — this ensures only clean data goes into the main staging.

Here’s the sequence and reasoning 👇

1️⃣ Null Checks

Make sure essential columns are not null (these are critical for analytics and joins later).

-- Check for nulls in key columns
SELECT *
FROM staging.customer_usage_raw
WHERE customer_id IS NULL
   OR meter_reading_date IS NULL
   OR usage_kwh IS NULL;


Action if found:

Send these rows to the audit/error table for investigation.

Do not load into staging.customer_usage_main.

INSERT INTO audit.error_log
(batch_id, record_id, issue_type, issue_description, created_at)
SELECT
    current_batch_id,
    customer_id,
    'NULL_CHECK_FAILED',
    'Essential field missing',
    CURRENT_TIMESTAMP
FROM staging.customer_usage_raw
WHERE customer_id IS NULL
   OR meter_reading_date IS NULL
   OR usage_kwh IS NULL;

2️⃣ Duplicate Check

Duplicates = same customer_id + meter_reading_date.

SELECT customer_id, meter_reading_date, COUNT(*) AS duplicate_count
FROM staging.customer_usage_raw
GROUP BY customer_id, meter_reading_date
HAVING COUNT(*) > 1;


Action if found:

Send all duplicate records to audit.duplicate_log.

Keep only the latest record based on updated_timestamp.

-- Log duplicates
INSERT INTO audit.duplicate_log
(batch_id, customer_id, meter_reading_date, issue_type, created_at)
SELECT current_batch_id, customer_id, meter_reading_date, 'DUPLICATE_RECORD', CURRENT_TIMESTAMP
FROM (
    SELECT customer_id, meter_reading_date
    FROM staging.customer_usage_raw
    GROUP BY customer_id, meter_reading_date
    HAVING COUNT(*) > 1
) dup;


Then, select only the latest record for staging:

-- Keep only the latest record per customer per date
WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id, meter_reading_date ORDER BY updated_timestamp DESC) AS rn
    FROM staging.customer_usage_raw
)
INSERT INTO staging.customer_usage_main
SELECT customer_id, meter_reading_date, usage_kwh, meter_id, updated_timestamp
FROM ranked
WHERE rn = 1
  AND customer_id IS NOT NULL
  AND meter_reading_date IS NOT NULL
  AND usage_kwh IS NOT NULL;

3️⃣ (Optional but Practical) – Format / Data Type Validation

Check for invalid values — e.g., usage can’t be negative or too high.

-- Validate realistic usage range (e.g., 0–2000 kWh per day)
SELECT *
FROM staging.customer_usage_raw
WHERE usage_kwh < 0 OR usage_kwh > 2000;


Action:

Move invalid rows to audit.invalid_data_log.

4️⃣ (Optional) Date Validation

Ensure meter_reading_date is within a valid period (e.g., not future-dated).

SELECT *
FROM staging.customer_usage_raw
WHERE meter_reading_date > CURRENT_DATE;

🧩 Step 3: Load Clean Data

Now only validated records are inserted into the main staging table:

INSERT INTO staging.customer_usage_main (customer_id, meter_reading_date, usage_kwh, meter_id, updated_timestamp)
SELECT customer_id, meter_reading_date, usage_kwh, meter_id, updated_timestamp
FROM staging.customer_usage_raw r
WHERE r.customer_id IS NOT NULL
  AND r.meter_reading_date IS NOT NULL
  AND r.usage_kwh IS NOT NULL
  AND NOT EXISTS (
       SELECT 1
       FROM audit.duplicate_log d
       WHERE d.customer_id = r.customer_id
         AND d.meter_reading_date = r.meter_reading_date
  )
  AND usage_kwh BETWEEN 0 AND 2000
  AND meter_reading_date <= CURRENT_DATE;

🧾 Step 4: Summary Audit Log

After processing, record validation stats for transparency:

INSERT INTO audit.batch_summary_log
(batch_id, total_records, null_count, duplicate_count, invalid_count, loaded_count, processed_at)
SELECT
    current_batch_id,
    (SELECT COUNT(*) FROM staging.customer_usage_raw),
    (SELECT COUNT(*) FROM audit.error_log WHERE batch_id = current_batch_id),
    (SELECT COUNT(*) FROM audit.duplicate_log WHERE batch_id = current_batch_id),
    (SELECT COUNT(*) FROM audit.invalid_data_log WHERE batch_id = current_batch_id),
    (SELECT COUNT(*) FROM staging.customer_usage_main),
    CURRENT_TIMESTAMP;

⚡ Summary of Validations (for Origin Energy data)
Validation Type	Why it’s needed	Action Taken
Null Checks	Missing key IDs or usage cause join/aggregation errors	Move to audit
Duplicates	Prevent double-counting energy usage	Keep latest record
Range/Format	Catch outliers or bad readings	Move to invalid log
Date Check	Prevent future or unrealistic readings	Move to invalid log
