⚡ Assumed Schema (Simplified)

We’ll base all queries on this:

dw.billing (
    bill_id INT,
    customer_id INT,
    bill_date DATE,
    energy_type VARCHAR(20),  -- 'Electricity' or 'Gas'
    usage_kwh NUMERIC(10,2),
    amount NUMERIC(10,2)
)

1️⃣ Month Start, Month End, and Monthly Revenue

👉 Used for dashboards tracking billing cycle or monthly revenue trend.

-- Monthly revenue with start & end dates
SELECT 
    DATE_TRUNC('month', bill_date) AS month_start,
    (DATE_TRUNC('month', bill_date) + INTERVAL '1 month - 1 day')::date AS month_end,
    SUM(amount) AS total_revenue
FROM dw.billing
GROUP BY 1, 2
ORDER BY month_start;

2️⃣ Previous Month Sales vs Current Month Sales

👉 Used for MoM (Month-over-Month) growth or decline tracking.

WITH monthly_sales AS (
    SELECT DATE_TRUNC('month', bill_date) AS month_start,
           SUM(amount) AS total_sales
    FROM dw.billing
    GROUP BY 1
)
SELECT 
    month_start,
    total_sales,
    LAG(total_sales) OVER (ORDER BY month_start) AS prev_month_sales,
    total_sales - LAG(total_sales) OVER (ORDER BY month_start) AS change_in_sales,
    ROUND(
        (total_sales - LAG(total_sales) OVER (ORDER BY month_start)) 
        / NULLIF(LAG(total_sales) OVER (ORDER BY month_start), 0) * 100, 2
    ) AS percent_change
FROM monthly_sales
ORDER BY month_start;

3️⃣ Year-to-Date (YTD) and Previous Year-to-Date (PYTD)

👉 Common for finance & retail energy performance dashboards.

WITH yearly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM bill_date) AS year,
        DATE_TRUNC('month', bill_date) AS month_start,
        SUM(amount) AS monthly_sales
    FROM dw.billing
    GROUP BY 1, 2
)
SELECT 
    year,
    month_start,
    SUM(monthly_sales) OVER (PARTITION BY year ORDER BY month_start) AS ytd_sales,
    LAG(SUM(monthly_sales) OVER (PARTITION BY year ORDER BY month_start)) 
      OVER (PARTITION BY year ORDER BY month_start) AS prev_ytd_sales
FROM yearly_sales
ORDER BY year, month_start;

4️⃣ Year-over-Year (YoY) Comparison

👉 Used to show how 2025 compares to 2024 in energy sales.

WITH yearly_sales AS (
    SELECT 
        DATE_TRUNC('month', bill_date) AS month_start,
        EXTRACT(YEAR FROM bill_date) AS year,
        SUM(amount) AS total_sales
    FROM dw.billing
    GROUP BY 1, 2
)
SELECT 
    a.month_start,
    a.year,
    a.total_sales AS current_year_sales,
    b.total_sales AS prev_year_sales,
    (a.total_sales - b.total_sales) AS yoy_change,
    ROUND((a.total_sales - b.total_sales) / NULLIF(b.total_sales, 0) * 100, 2) AS yoy_percent_change
FROM yearly_sales a
LEFT JOIN yearly_sales b
  ON a.month_start = b.month_start + INTERVAL '1 year'
ORDER BY a.month_start;

5️⃣ Opening and Closing Balance (Customer Account)

👉 Used for financial reconciliation or energy credit/debit tracking.

WITH balance AS (
    SELECT 
        customer_id,
        bill_date,
        SUM(amount) OVER (PARTITION BY customer_id ORDER BY bill_date 
                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS closing_balance
    FROM dw.billing
)
SELECT 
    customer_id,
    bill_date,
    LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY bill_date) AS opening_balance,
    closing_balance,
    closing_balance - COALESCE(LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY bill_date),0) AS balance_change
FROM balance
ORDER BY customer_id, bill_date;

6️⃣ Seasonal or Quarterly Energy Usage Trend

👉 Origin loves this because electricity & gas usage vary by season.

SELECT 
    DATE_TRUNC('quarter', bill_date) AS quarter_start,
    energy_type,
    SUM(usage_kwh) AS total_usage,
    SUM(amount) AS total_revenue
FROM dw.billing
GROUP BY 1, 2
ORDER BY quarter_start, energy_type;

7️⃣ Daily / Rolling 7-day Usage (Peak Load Trend)

👉 Useful for grid load forecasting & customer consumption pattern.

WITH daily_usage AS (
    SELECT bill_date,
           SUM(usage_kwh) AS total_usage
    FROM dw.billing
    GROUP BY bill_date
)
SELECT 
    bill_date,
    total_usage,
    AVG(total_usage) OVER (ORDER BY bill_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7day_avg
FROM daily_usage
ORDER BY bill_date;

8️⃣ Retention Rate & Churn Over Time

👉 Combine with churn flags to see retention trend month-by-month.

WITH churn_data AS (
    SELECT 
        DATE_TRUNC('month', bill_date) AS month_start,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM dw.billing
    GROUP BY 1
)
SELECT 
    month_start,
    active_customers,
    LAG(active_customers) OVER (ORDER BY month_start) AS prev_month_customers,
    ROUND(
        (active_customers - LAG(active_customers) OVER (ORDER BY month_start)) 
        / NULLIF(LAG(active_customers) OVER (ORDER BY month_start),0) * 100, 2
    ) AS retention_rate
FROM churn_data
ORDER BY month_start;

⚙️ Common Time Intelligence Scenarios for Origin Energy
Scenario	Purpose / Metric	Example SQL Concept
Monthly Revenue Trend	Revenue growth tracking	DATE_TRUNC('month', bill_date)
MoM & YoY Growth	Compare time periods	LAG(), JOIN on shifted dates
YTD & QTD	Year/Quarter-to-date totals	Window SUM() with partition by year
Opening/Closing Balance	Account balance	Window SUM() + LAG()
Rolling Avg Usage	Peak load smoothing	ROWS BETWEEN clause
Seasonal Usage	Predict high demand	Group by quarter/month
Customer Retention	Loyalty/Churn tracking	COUNT(DISTINCT customer_id) over time
Billing Accuracy Trend	Monitor late or rebill rates	Join billing vs payment tables
