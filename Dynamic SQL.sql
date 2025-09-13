Create  Procedure dbo.DynamicTopN(@TopN int,@AggFunction varchar(50))
AS
BEGIN

Declare @DynamicSql  varchar(max)

set @DynamicSql =  'select 
                      * from 
					        (select 
							         productname=B.[Name],
									 linetotalsum = '
Set @DynamicSql = @DynamicSql+ @AggFunction 
set @DynamicSql = @DynamicSql+ '(A.linetotal),
                               linetotalsumrank = dense_rank() over(order by '
set @DynamicSql= @DynamicSql + @AggFunction

set @DynamicSql=@DynamicSql + '(A.Linetotal) Desc)
                              from  AdventureWorks2022.Sales.SalesOrderDetail A
          join AdventureWorks2022.Production.Product B
		  on A.ProductID = B.ProductID

		  group by
		  B.[Name]
		  )X
		  where Linetotalsumrank<= 10

'
set @DynamicSql = @DynamicSql+cast(@TopN as varchar)


END

--exec DynamicTopN 15,'max'

/*select * from AdventureWorks2022.Sales.SalesOrderDetail A
          join AdventureWorks2022.Production.Product B
		  on A.ProductID = B.ProductID

		  group by
		  B.[Name]
		  )X
		  where Linetotalsumrank<= 10 */
									 

                   


       
