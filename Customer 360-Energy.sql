⚡ 1. Business Context (Energy – Retail Division)

Objective:
To analyze customer behavior (electricity/gas users) using:

RFM Analysis (Recency, Frequency, Monetary)

Campaign segmentation for targeted marketing (e.g., retention, upsell, churn prevention).

Data sourced from billing, payments, and usage systems.

🧱 2. Source Tables
source_customer
CREATE TABLE source_customer (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    join_date DATE,
    email VARCHAR(100),
    state VARCHAR(20),
    status VARCHAR(20)  -- 'Active', 'Inactive', 'Churned'
);

source_billing
CREATE TABLE source_billing (
    bill_id SERIAL PRIMARY KEY,
    customer_id INT,
    billing_date DATE,
    bill_amount NUMERIC(10,2),
    energy_type VARCHAR(20), -- 'Electricity' or 'Gas'
    usage_kwh NUMERIC(10,2),
    paid BOOLEAN DEFAULT FALSE
);

🧪 3. Staging Layer (Data Validation & Cleansing)
stg_billing
CREATE TEMP TABLE stg_billing AS
SELECT 
    bill_id,
    customer_id,
    billing_date,
    COALESCE(bill_amount, 0) AS bill_amount,
    UPPER(energy_type) AS energy_type,
    NULLIF(TRIM(state), '') AS state,
    CASE WHEN usage_kwh < 0 THEN NULL ELSE usage_kwh END AS usage_kwh
FROM source_billing b
JOIN source_customer c USING (customer_id)
WHERE billing_date IS NOT NULL;


🧹 Cleansing done:

Null or negative usage_kwh handled.

Converted energy types to uppercase.

Removed empty states.

Ensured billing_date exists.

⚙️ 4. Transformation Layer

Aggregate monthly spend, usage, and recency per customer

CREATE TEMP TABLE trf_customer_monthly AS
SELECT
    c.customer_id,
    DATE_TRUNC('month', b.billing_date) AS month_start,
    SUM(b.bill_amount) AS total_spent,
    COUNT(DISTINCT b.bill_id) AS bill_count,
    SUM(b.usage_kwh) AS total_usage,
    MAX(b.billing_date) AS last_bill_date
FROM stg_billing b
JOIN source_customer c ON b.customer_id = c.customer_id
GROUP BY c.customer_id, DATE_TRUNC('month', b.billing_date);

📊 5. RFM Calculation (as of current date)
WITH customer_latest AS (
    SELECT 
        customer_id,
        MAX(last_bill_date) AS recent_date,
        SUM(total_spent) AS monetary_value,
        SUM(bill_count) AS frequency
    FROM trf_customer_monthly
    GROUP BY customer_id
),
rfm_base AS (
    SELECT
        c.customer_id,
        EXTRACT(DAY FROM (CURRENT_DATE - MAX(recent_date))) AS recency,
        frequency,
        monetary_value
    FROM customer_latest c
)
SELECT
    customer_id,
    recency,
    frequency,
    monetary_value,
    NTILE(5) OVER (ORDER BY recency ASC) AS r_score,  -- 1=worst, 5=best (recent)
    NTILE(5) OVER (ORDER BY frequency DESC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary_value DESC) AS m_score,
    (NTILE(5) OVER (ORDER BY recency ASC) +
     NTILE(5) OVER (ORDER BY frequency DESC) +
     NTILE(5) OVER (ORDER BY monetary_value DESC)) AS total_rfm_score
INTO rfm_customer_score
FROM rfm_base;

🧩 6. Campaign Segmentation Logic
SELECT 
    customer_id,
    total_rfm_score,
    CASE
        WHEN total_rfm_score BETWEEN 13 AND 15 THEN 'VIP Loyalist'
        WHEN total_rfm_score BETWEEN 10 AND 12 THEN 'Potential Loyalist'
        WHEN total_rfm_score BETWEEN 7 AND 9 THEN 'At Risk'
        WHEN total_rfm_score BETWEEN 4 AND 6 THEN 'Need Attention'
        ELSE 'Churned / Lost'
    END AS segment
FROM rfm_customer_score;

🎯 7. Campaign Use-Cases
Segment	Campaign Action	Example
VIP Loyalist	Offer bundle deals (Gas + Electricity)	Cross-sell Green energy plans
Potential Loyalist	Give reward points for early bill payment	Loyalty promotion
At Risk	Send retention offers	Discount for next billing cycle
Need Attention	Reminders for payment	Payment reminder SMS
Churned/Lost	Win-back campaign	“Come Back & Save” offer
🧠 8. Bonus Time Intelligence Queries (for Origin Energy)

Here’s how you can integrate RFM with time-based metrics:

-- Month-over-Month Revenue Growth
SELECT
    DATE_TRUNC('month', billing_date) AS month_start,
    SUM(bill_amount) AS current_month_revenue,
    LAG(SUM(bill_amount)) OVER (ORDER BY DATE_TRUNC('month', billing_date)) AS prev_month_revenue,
    ROUND( (SUM(bill_amount) - LAG(SUM(bill_amount)) OVER (ORDER BY DATE_TRUNC('month', billing_date))) 
           / NULLIF(LAG(SUM(bill_amount)) OVER (ORDER BY DATE_TRUNC('month', billing_date)), 0) * 100, 2) 
           AS mom_growth_percent
FROM source_billing
GROUP BY DATE_TRUNC('month', billing_date)
ORDER BY month_start;
