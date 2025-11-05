Churn prediction logic (SQL-based behavioural model)

Campaign performance tracking

End-to-end flow (ETL + RFM + Churn + Campaign results)

All built in PostgreSQL, realistic for Energy Retail (Electricity & Gas).

⚡ 1. Churn Prediction — SQL-based Behavioural Analysis

Here, “churn” = customer who hasn’t had billing activity in the last 90 days or has missed payments.

🧱 Create a view: vw_customer_activity
CREATE OR REPLACE VIEW vw_customer_activity AS
SELECT
    c.customer_id,
    MAX(b.billing_date) AS last_bill_date,
    COUNT(DISTINCT b.bill_id) AS total_bills,
    SUM(b.bill_amount) AS total_revenue,
    SUM(CASE WHEN b.paid = FALSE THEN 1 ELSE 0 END) AS missed_payments,
    AVG(b.bill_amount) AS avg_bill_amount,
    AVG(b.usage_kwh) AS avg_usage_kwh
FROM source_customer c
LEFT JOIN source_billing b ON c.customer_id = b.customer_id
GROUP BY c.customer_id;

🔍 Churn flag logic
CREATE OR REPLACE VIEW vw_churn_flag AS
SELECT
    customer_id,
    CASE 
        WHEN CURRENT_DATE - last_bill_date > 90 THEN 1  -- inactive for 3 months
        WHEN missed_payments >= 2 THEN 1                -- missed 2 or more payments
        ELSE 0
    END AS is_churned,
    total_bills,
    total_revenue,
    avg_bill_amount,
    avg_usage_kwh,
    last_bill_date
FROM vw_customer_activity;


🧠 Interpretation:

If customer hasn’t been billed in 90+ days → likely churned.

If multiple unpaid bills → at-risk.

💡 Combine with RFM for deeper insight
SELECT
    r.customer_id,
    r.total_rfm_score,
    c.is_churned,
    CASE 
        WHEN c.is_churned = 1 AND r.total_rfm_score <= 6 THEN 'High Churn Risk'
        WHEN c.is_churned = 1 AND r.total_rfm_score > 6 THEN 'Possible Retention'
        WHEN c.is_churned = 0 AND r.total_rfm_score >= 12 THEN 'Loyal Customer'
        ELSE 'Monitor Closely'
    END AS churn_segment
INTO churn_rfm_analysis
FROM rfm_customer_score r
JOIN vw_churn_flag c USING (customer_id);


🟢 This table identifies who’s at risk and how valuable they are.
This is exactly how energy retailers prioritize retention offers.

🎯 2. Campaign Tracking — Post-Campaign ETL

Assume you ran an email offer campaign for At-Risk Customers last month.

campaign_history
CREATE TABLE campaign_history (
    campaign_id SERIAL PRIMARY KEY,
    customer_id INT,
    campaign_name VARCHAR(100),
    offer_date DATE,
    offer_type VARCHAR(50),
    response VARCHAR(20), -- 'Accepted', 'Ignored', 'Rejected'
    new_bill_amount NUMERIC(10,2),
    new_billing_date DATE
);

🧮 Campaign success metric (Retention & Revenue Impact)
SELECT
    campaign_name,
    COUNT(DISTINCT customer_id) AS customers_targeted,
    SUM(CASE WHEN response = 'Accepted' THEN 1 ELSE 0 END) AS customers_retained,
    ROUND(SUM(CASE WHEN response = 'Accepted' THEN 1 ELSE 0 END)::NUMERIC 
          / COUNT(DISTINCT customer_id) * 100, 2) AS retention_rate,
    SUM(CASE WHEN response = 'Accepted' THEN new_bill_amount ELSE 0 END) AS revenue_from_campaign
FROM campaign_history
GROUP BY campaign_name
ORDER BY retention_rate DESC;


🧾 Outcome Example:

Campaign Name	Customers Targeted	Retained	Retention Rate	Revenue from Campaign
Winter Saver Offer	1200	360	30.0%	42,000
🧩 3. Post-Campaign Impact on Churn

You can evaluate how effective campaigns were in reducing churn.

SELECT
    c.campaign_name,
    COUNT(DISTINCT ch.customer_id) FILTER (WHERE ch.is_churned = 1) AS churned_customers,
    COUNT(DISTINCT ch.customer_id) FILTER (WHERE ch.is_churned = 0) AS active_customers,
    ROUND(COUNT(DISTINCT ch.customer_id) FILTER (WHERE ch.is_churned = 0)::NUMERIC 
          / COUNT(DISTINCT ch.customer_id) * 100, 2) AS post_campaign_retention_pct
FROM vw_churn_flag ch
JOIN campaign_history c USING (customer_id)
GROUP BY c.campaign_name;

🔁 4. Full ETL Flow Summary (for your interview)
Step	Table / Process	Purpose
Source	source_customer, source_billing	Raw billing & customer data
Staging	stg_billing	Data cleaning & validation
Transformation	trf_customer_monthly	Aggregations by month
Analysis 1	rfm_customer_score	Customer segmentation
Analysis 2	vw_churn_flag, churn_rfm_analysis	Churn risk detection
Campaign Data	campaign_history	Store campaign response
Analysis 3	Campaign metrics SQL	Evaluate retention performance
