-- Step 1: Calculate running total per customer per bill date
WITH daily_balance AS (
    SELECT
        customer_id,
        bill_date,
        SUM(amount) OVER (
            PARTITION BY customer_id
            ORDER BY bill_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total
    FROM dw.billing
),

-- Step 2: Find first and last bill date for each customer per month
monthly_dates AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', bill_date) AS month_start,
        MIN(bill_date) AS first_bill_date,
        MAX(bill_date) AS last_bill_date
    FROM dw.billing
    GROUP BY customer_id, DATE_TRUNC('month', bill_date)
),

-- Step 3: Get opening balance (running total on first bill date)
opening_balance AS (
    SELECT
        m.customer_id,
        m.month_start,
        d.running_total AS opening_balance
    FROM monthly_dates m
    JOIN daily_balance d
      ON m.customer_id = d.customer_id
     AND m.first_bill_date = d.bill_date
),

-- Step 4: Get closing balance (running total on last bill date)
closing_balance AS (
    SELECT
        m.customer_id,
        m.month_start,
        d.running_total AS closing_balance
    FROM monthly_dates m
    JOIN daily_balance d
      ON m.customer_id = d.customer_id
     AND m.last_bill_date = d.bill_date
)

-- Step 5: Combine opening & closing balances
SELECT
    o.customer_id,
    o.month_start,
    o.opening_balance,
    c.closing_balance,
    c.closing_balance - o.opening_balance AS balance_change
FROM opening_balance o
JOIN closing_balance c
  ON o.customer_id = c.customer_id
 AND o.month_start = c.month_start
ORDER BY o.customer_id, o.month_start;
