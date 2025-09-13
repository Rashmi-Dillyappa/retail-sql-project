create  procedure dbo.ordersreport (@TopN Int)

as
begin


select 
 * 
  from (
         select 
		 productname = b.[name],
		 linetotalsum = sum(a.linetotal),
		 linetotalsumrank = dense_rank() over(order by sum(a.linetotal) desc)


		 from AdventureWorks2022.Sales.SalesOrderDetail A
		 Join AdventureWorks2022.Production.Product B
		  on a.ProductID = b.ProductID

		  group by 
		  b.[Name]

		  ) X

		  where linetotalsumrank < =@TopN

end ; 

exec dbo.ordersreport 15
