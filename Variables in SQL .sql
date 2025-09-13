/*Using a variable improves performance because the 
AVG(ListPrice) is calculated once and reused,
  whereas in a regular query the same subquery is
  repeated multiple times (SELECT, WHERE, calculation) and SQL Server recalculates it each time.
DECLARE @AvgPrice Money */

select @AvgPrice = (Select Avg(ListPrice) from AdventureWorks2022.Production.Product)

select
   ProductID,
   [Name],
   standardcost,
   AvgListPrice = @AvgPrice,
   AvgListPriceDiff = ListPrice - @AvgPrice

   from AdventureWorks2022.Production.Product
   where ListPrice > @AvgPrice
   order by listprice asc 


