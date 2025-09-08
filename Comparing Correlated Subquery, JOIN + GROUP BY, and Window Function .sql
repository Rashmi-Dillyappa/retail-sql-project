SET STATISTICS TIME ON;   -- shows CPU + elapsed time
SET STATISTICS IO ON;  

Select  
SalesOrderID,
OrderDate,
subTotal, 
TaxAmt,
Freight,
TotalDue,
Multiordercount=
(select
count(*)
from AdventureWorks2022.Sales.SalesOrderDetail b
where b.SalesOrderID = a.SalesOrderID and b.OrderQty > 1
)
from 
AdventureWorks2022.Sales.SalesOrderHeader A

-- SQL Server Execution Times:
   --CPU time = 0 ms,  elapsed time = 443 ms.
/*Explanation:
For each row in SalesOrderHeader, the subquery counts the number of detail lines with OrderQty > 1.
Performance: Fast for small/medium tables. Performace :CPU time = 0 ms Elapsed time = 443 ms

Pros: Simple, easy to read.
Cons: Can be slower on very large datasets.*/


SELECT
    a.SalesOrderID,
    a.OrderDate,
    a.SubTotal,
    a.TaxAmt,
    a.Freight,
    a.TotalDue,
    COUNT(CASE WHEN b.OrderQty > 1 THEN 1 END) AS Multiordercount
FROM AdventureWorks2022.Sales.SalesOrderHeader a
LEFT JOIN AdventureWorks2022.Sales.SalesOrderDetail b
    ON a.SalesOrderID = b.SalesOrderID
GROUP BY
    a.SalesOrderID,
    a.OrderDate,
    a.SubTotal,
    a.TaxAmt,
    a.Freight,
    a.TotalDue
ORDER BY a.SalesOrderID;

-- SQL Server Execution Times:
--CPU time = 265 ms,  elapsed time = 569 ms
/*Explanation:
Aggregates SalesOrderDetail lines per SalesOrderID.
Uses COUNT(CASE WHEN…) to count only rows where OrderQty > 1.

Performance: Slightly slower than correlated subquery for your dataset:
CPU time = 265 ms Elapsed time = 569 ms

Pros: Efficient for large datasets; scales well.
Cons: Requires GROUP BY all non-aggregated columns */

   SELECT DISTINCT
    a.SalesOrderID,
    a.OrderDate,
    a.SubTotal,
    a.TaxAmt,
    a.Freight,
    a.TotalDue,
    COUNT(CASE WHEN b.OrderQty > 1 THEN 1 END) 
        OVER (PARTITION BY a.SalesOrderID) AS Multiordercount
FROM AdventureWorks2022.Sales.SalesOrderHeader a
LEFT JOIN AdventureWorks2022.Sales.SalesOrderDetail b
    ON a.SalesOrderID = b.SalesOrderID
ORDER BY a.SalesOrderID;

--SQL Server Execution Times:
--CPU time = 812 ms,  elapsed time = 1210 ms.

/*Explanation:
Uses a window function to count OrderQty > 1 per order without grouping all columns.
DISTINCT ensures one row per SalesOrderID.
Performance: Slowest for your dataset:
CPU time = 812 ms Elapsed time = 1210 ms

Pros: Clean for reporting; avoids verbose GROUP BY.
Cons: Extra overhead due to window calculation and DISTINCT */

/*
select
salesorderid,
orderQty

from AdventureWorks2022.Sales.SalesOrderDetail
where SalesOrderID = 43659
*/
