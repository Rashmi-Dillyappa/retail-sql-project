USE [AdventureWorks2022]
GO

/****** Object:  StoredProcedure [dbo].[ordersreport]    Script Date: 13-09-2025 15:39:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

alter procedure [dbo].[Logicalif_SP] (@TopN Int, @ordertype Int)

as
begin

if @ordertype =1 
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



    end 
	
   else
            begin
			               select 
               * 
               from (
                          select 
		                  productname = b.[name],
		                 linetotalsum = sum(a.linetotal),
		                linetotalsumrank = dense_rank() over(order by sum(a.linetotal) desc)


		                from AdventureWorks2022.Purchasing.PurchaseOrderDetail A
		                 Join AdventureWorks2022.Production.Product B
		                      on a.ProductID = b.ProductID

		                  group by 
		                  b.[Name]

		                      ) X

		                  where linetotalsumrank < =@TopN

			end 



end ; 
GO


exec dbo.Logicalif_SP 15,1


