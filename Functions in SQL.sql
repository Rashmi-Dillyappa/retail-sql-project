Use AdventureWorks2022
go

Create Function dbo.ufnelapsedbusinessDays(@startDate Date,@endDate Date)

Returns Int

As

Begin

return (
           select 
		   count(*)
		   from AdventureWorks2022.dbo.calendar 
		   wher  datevalue  between @startDate and @endDate
		    and weekkendflag = 0
			and holidayflag = 0

			)
end 


----------------------------------------------------------------------------------------------------
select Salesorderid,
orderdate,
DueDate,ShipDate,
elapsedbusinessday = dbo.ufnelapsedbusinessDays(orderdate,shipdate)
from AdventureWorks2022.Sales.SalesOrderHeader a
where year(a,OrderDate) = 2011


