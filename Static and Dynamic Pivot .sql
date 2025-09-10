Static PIVOT 
--------------------------------------------------------------------------------
select 
[bikes],
[clothing],
[accessories],
[Components]

 from
(Select 
   productCategoryName = D.Name,
   a.LineTotal

 from AdventureWorks2022.Sales.SalesOrderDetail a
     JOIN AdventureWorks2022.Production.Product b
	     ON A.ProductID = B.ProductID
		 Join AdventureWorks2022.Production.ProductSubcategory C
		  on b.ProductSubcategoryID = c.ProductSubcategoryID
		  join AdventureWorks2022.Production.ProductCategory D
		   on c.ProductCategoryID = d.ProductCategoryID
		   ) A

		   PIVOT (
		   sum(lineTotal )
		   For ProductCategoryName in ([bikes],[clothing],[accessories],[Components] )) B



Problem → you must manually list categories.

Dynamic Pivot Alternative (CASE WHEN + GROUP BY)
-------------------------------------------------------------------------------
We can simulate pivot logic without PIVOT by using conditional aggregation:

SELECT
    SUM(CASE WHEN d.Name = 'Bikes' THEN a.LineTotal ELSE 0 END) AS Bikes,
    SUM(CASE WHEN d.Name = 'Clothing' THEN a.LineTotal ELSE 0 END) AS Clothing,
    SUM(CASE WHEN d.Name = 'Accessories' THEN a.LineTotal ELSE 0 END) AS Accessories,
    SUM(CASE WHEN d.Name = 'Components' THEN a.LineTotal ELSE 0 END) AS Components
FROM AdventureWorks2022.Sales.SalesOrderDetail a
JOIN AdventureWorks2022.Production.Product b
    ON a.ProductID = b.ProductID
JOIN AdventureWorks2022.Production.ProductSubcategory c
    ON b.ProductSubcategoryID = c.ProductSubcategoryID
JOIN AdventureWorks2022.Production.ProductCategory d
    ON c.ProductCategoryID = d.ProductCategoryID;


This gives same output as your PIVOT, but still static.

Fully Dynamic Pivot (SQL String Building)
--------------------------------------------------------------------------------------------
If you want categories to adjust automatically, build a query dynamically:

DECLARE @cols NVARCHAR(MAX), @sql NVARCHAR(MAX);

-- Get distinct category names
SELECT @cols = STRING_AGG(QUOTENAME(Name), ',')
FROM AdventureWorks2022.Production.ProductCategory;

-- Build dynamic SQL
SET @sql = '
SELECT ' + @cols + '
FROM (
    SELECT 
        d.Name AS ProductCategoryName,
        a.LineTotal
    FROM AdventureWorks2022.Sales.SalesOrderDetail a
    JOIN AdventureWorks2022.Production.Product b
        ON a.ProductID = b.ProductID
    JOIN AdventureWorks2022.Production.ProductSubcategory c
        ON b.ProductSubcategoryID = c.ProductSubcategoryID
    JOIN AdventureWorks2022.Production.ProductCategory d
        ON c.ProductCategoryID = d.ProductCategoryID
) AS src
PIVOT (
    SUM(LineTotal)
    FOR ProductCategoryName IN (' + @cols + ')
) AS p;';

-- Execute
EXEC sp_executesql @sql;

Summary:
-----------------------------------------------------------------------------------
Option 1 → PIVOT (static, manual column list).
Option 2 → CASE WHEN + GROUP BY (manual but simpler, no PIVOT keyword).
Option 3 → Dynamic SQL PIVOT with STRING_AGG

