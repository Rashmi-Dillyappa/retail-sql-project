💡 Goal

👉 Find why those 'Y' customers are churning and how to bring them back.

We’ll handle this in 3 parts:

① Churn Root Cause Analysis
② Customer Segmentation for Retention
③ Reactivation Strategy Suggestions
① CHURN ROOT CAUSE ANALYSIS

Objective: find key drivers (e.g., high bills, change in tariff plan, delayed payments, or service type).

🧠 SQL Example — Analyze churn by category
SELECT 
    c.tariff_plan,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN cf.churn_flag = 'Y' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN cf.churn_flag = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct
FROM dw.customer_info c
JOIN dw.customer_churn_flag cf ON c.customer_id = cf.customer_id
GROUP BY c.tariff_plan
ORDER BY churn_rate_pct DESC;


👉 Insight: Shows which tariff plan has the highest churn — maybe “Flexible Saver Plan” customers are leaving more due to high unit cost.

🧩 Another: Find churn by region or billing issues
SELECT 
    c.region,
    AVG(b.amount) AS avg_bill,
    AVG(p.amount) AS avg_payment,
    ROUND(100.0 * SUM(CASE WHEN cf.churn_flag = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
FROM dw.customer_info c
JOIN dw.billing b ON c.customer_id = b.customer_id
JOIN dw.payments p ON c.customer_id = p.customer_id
JOIN dw.customer_churn_flag cf ON c.customer_id = cf.customer_id
GROUP BY c.region
ORDER BY churn_rate DESC;


👉 Insight: Certain regions (maybe rural or low-income areas) show low payment-to-bill ratio.

② CUSTOMER SEGMENTATION FOR RETENTION

Now identify who we can win back — customers with:

High value (paid large amounts before)

Recently churned (<3 months)

Certain plans or regions

🧮 SQL — “Recoverable churn” candidates
SELECT 
    c.customer_id,
    c.customer_name,
    c.tariff_plan,
    MAX(b.bill_date) AS last_bill_date,
    SUM(p.amount) AS total_paid,
    ROUND(AVG(b.amount),2) AS avg_monthly_bill,
    CASE 
       WHEN MAX(b.bill_date) BETWEEN CURRENT_DATE - INTERVAL '180 days' AND CURRENT_DATE - INTERVAL '30 days'
            THEN 'High Recovery Chance'
       ELSE 'Low Recovery Chance'
    END AS recovery_segment
FROM dw.customer_info c
JOIN dw.billing b ON c.customer_id = b.customer_id
JOIN dw.payments p ON c.customer_id = p.customer_id
JOIN dw.customer_churn_flag cf ON c.customer_id = cf.customer_id
WHERE cf.churn_flag = 'Y'
GROUP BY c.customer_id, c.customer_name, c.tariff_plan;


👉 Insight: Customers with recent churn (within 3–6 months) are easier to win back through loyalty offers or discounts.

③ REACTIVATION STRATEGIES (Business Actions)
Strategy	SQL/BI Insight Used	Action Example
Discount Campaigns	High bill → payment gap	Send targeted 10% off reactivation emails
Tariff Optimization	High churn in certain plans	Recommend switching to cheaper plan
Feedback Loop	Long inactive but high payer	Call/email survey to understand dissatisfaction
Auto Payment Offers	Low payment consistency	Offer bonus credit for enabling auto-pay
⚡ Bonus: CHURN DASHBOARD IDEAS (Power BI)

Churn Rate Trend: Monthly churn %

Churn by Tariff Plan

Payment-to-Bill Ratio Heatmap

Recoverable Customers Segment


💡 1️⃣ Discount Campaigns — High bill → low payment gap

Goal: Identify customers whose average bill is much higher than their average payment.

-- Discount Campaign Target List
SELECT 
    c.customer_id,
    c.customer_name,
    c.tariff_plan,
    ROUND(AVG(b.amount),2) AS avg_bill,
    ROUND(AVG(p.amount),2) AS avg_payment,
    ROUND(AVG(b.amount) - AVG(p.amount),2) AS payment_gap,
    'Send targeted 10% off reactivation email' AS action
FROM dw.customer_info c
JOIN dw.billing b ON c.customer_id = b.customer_id
JOIN dw.payments p ON c.customer_id = p.customer_id
JOIN dw.customer_churn_flag cf ON c.customer_id = cf.customer_id
WHERE cf.churn_flag = 'Y'
GROUP BY c.customer_id, c.customer_name, c.tariff_plan
HAVING AVG(b.amount) - AVG(p.amount) > 50  -- payment gap threshold
ORDER BY payment_gap DESC;


🟢 Insight: These are churned customers with high unpaid bills → send discount or bill adjustment offer.

💡 2️⃣ Tariff Optimization — High churn in specific plans

Goal: Identify plans with churn > 20% and recommend migration.

-- Tariff Optimization Target Plans
WITH plan_churn AS (
  SELECT 
      tariff_plan,
      COUNT(*) AS total_customers,
      SUM(CASE WHEN churn_flag = 'Y' THEN 1 ELSE 0 END) AS churned,
      ROUND(100.0 * SUM(CASE WHEN churn_flag = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
  FROM dw.customer_churn_flag
  GROUP BY tariff_plan
)
SELECT 
    tariff_plan,
    churn_rate,
    CASE 
       WHEN churn_rate > 20 THEN 'Recommend switching customers to cheaper/loyalty plan'
       ELSE 'Plan performing well'
    END AS action
FROM plan_churn
ORDER BY churn_rate DESC;


🟢 Insight: Use Power BI to highlight top 3 high-churn plans → target for plan redesign or migration.

💡 3️⃣ Feedback Loop — Long inactive but high payer

Goal: Customers who paid well earlier but have been inactive recently.

-- Feedback Loop Target List
SELECT 
    c.customer_id,
    c.customer_name,
    c.tariff_plan,
    MAX(b.bill_date) AS last_bill_date,
    SUM(p.amount) AS total_paid,
    'Call/email survey to understand dissatisfaction' AS action
FROM dw.customer_info c
JOIN dw.billing b ON c.customer_id = b.customer_id
JOIN dw.payments p ON c.customer_id = p.customer_id
JOIN dw.customer_churn_flag cf ON c.customer_id = cf.customer_id
WHERE cf.churn_flag = 'Y'
GROUP BY c.customer_id, c.customer_name, c.tariff_plan
HAVING MAX(b.bill_date) < CURRENT_DATE - INTERVAL '120 days'
   AND SUM(p.amount) > 1000
ORDER BY total_paid DESC;


🟢 Insight: These are valuable churned customers → best to call personally or send survey link.

💡 4️⃣ Auto-Payment Offers — Low payment consistency

Goal: Customers who often delay or skip payments.

-- Auto Payment Offer Target List
SELECT 
    c.customer_id,
    c.customer_name,
    c.tariff_plan,
    COUNT(DISTINCT b.bill_date) AS total_bills,
    COUNT(DISTINCT p.payment_date) AS total_payments,
    (COUNT(DISTINCT p.payment_date)::float / COUNT(DISTINCT b.bill_date)) AS payment_ratio,
    'Offer bonus credit for enabling auto-pay' AS action
FROM dw.customer_info c
JOIN dw.billing b ON c.customer_id = b.customer_id
LEFT JOIN dw.payments p ON c.customer_id = p.customer_id
JOIN dw.customer_churn_flag cf ON c.customer_id = cf.customer_id
WHERE cf.churn_flag = 'Y'
GROUP BY c.customer_id, c.customer_name, c.tariff_plan
HAVING (COUNT(DISTINCT p.payment_date)::float / COUNT(DISTINCT b.bill_date)) < 0.8
ORDER BY payment_ratio ASC;


🟢 Insight: Customers who miss or delay payments → target for auto-pay campaigns.

🧾 Combined View (Optional)

You can even union all of them to create a Retention Action Table 👇

CREATE TABLE dw.customer_retention_action AS
SELECT * FROM ( 
  -- combine all strategies
  SELECT c.customer_id, c.customer_name, 'Discount Campaign' AS strategy, 'Send targeted 10% off reactivation email' AS action
  FROM (...) discount_query
  UNION ALL
  SELECT ... tariff_query
  UNION ALL
  SELECT ... feedback_query
  UNION ALL
  SELECT ... autopay_query
);


Then visualize it in Power BI by:

Strategy Type

Number of Target Customers

Expected Retention Rate Improvement
