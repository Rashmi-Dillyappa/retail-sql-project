Aggregate SUM() vs Window Function SUM() OVER() – When to Use What

I ran a performance comparison on the AdventureWorks sample sales data to understand the differences between Aggregate SUM() with GROUP BY and Window Function SUM() OVER().

✅ Test Queries

1. Aggregate SUM() with GROUP BY
---------------------------------------------------------------
SELECT
    YEAR(h.OrderDate) AS OrderYear,
    t.Name AS Territory,
    SUM(d.LineTotal) AS TotalSales
FROM Sales.SalesOrderHeader h
JOIN Sales.SalesOrderDetail d ON h.SalesOrderID = d.SalesOrderID
JOIN Sales.SalesTerritory t ON h.TerritoryID = t.TerritoryID
GROUP BY YEAR(h.OrderDate), t.Name
ORDER BY OrderYear, Territory;


Execution Time:

CPU: 188 ms  Elapsed: 199 ms
------------------------------------------------------------------
2. Window Function SUM() OVER()
------------------------------------------------------------------
SELECT
    YEAR(h.OrderDate) AS OrderYear,
    t.Name AS Territory,
    d.LineTotal,
    SUM(d.LineTotal) OVER(PARTITION BY YEAR(h.OrderDate), t.Name) AS TotalSales
FROM Sales.SalesOrderHeader h
JOIN Sales.SalesOrderDetail d ON h.SalesOrderID = d.SalesOrderID
JOIN Sales.SalesTerritory t ON h.TerritoryID = t.TerritoryID
ORDER BY OrderYear, Territory;


Execution Time:

CPU: 1063 ms Elapsed: 2370 ms
----------------------------------------------------------------------
📝 Key Insights
When to use Aggregate SUM() with GROUP BY :
-------------------------------------------
1.Best for summary reports (e.g., total sales per year, per territory).
2.More performant since it reduces rows (aggregation happens first).
3.Query result contains one row per group (compact result set).

Example:
Total sales per year
Average revenue per region
Count of orders per customer
-----------------------------------------------------------------------
When to use Window SUM() OVER()
-------------------------------------------:
1.Best for scenarios where you need both detail + aggregate in the same query.
2.Does not collapse rows → you still see each line/item, plus its group total.
3.Useful for advanced analytics:
    Running totals
    Percent of total
    Ranking (ROW_NUMBER, RANK, DENSE_RANK)
    Sliding window calculations

Example:
Show each order line with total sales for the year/region
Calculate a running total of monthly sales
Find % contribution of each product to category total
-------------------------------------------------------------------------

⚖️ Conclusion

1.GROUP BY + Aggregate = Faster, best for summaries.
2.Window Function SUM() OVER() = More flexible, best for analytics where detail + total are both required.

👉 Use Aggregate SUM() when performance is critical and you only need grouped summaries.





👉 Use Window SUM() OVER() when you need row-level insights with aggregate context.
