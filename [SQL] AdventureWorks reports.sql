
--Question 1 - Show products that were never purchased 

use AdventureWorks2019
GO
select ProductId, Name, Color, ListPrice, Size
from Production.Product
where not exists (select 1 from Sales.SalesOrderDetail
				  where ProductID = Product.ProductID)

-- Updates to execute preparing for question 2

use AdventureWorks2019
GO
-- Pre-ex
update sales.Customer set PersonID=CustomerID
	where CustomerID<=290
update Sales.Customer set PersonID=CustomerID+1700
	where CustomerID>= 300 and CustomerID <= 350
update Sales.Customer set PersonID=CustomerID+1700
	where CustomerID>= 352 and CustomerID <= 701 

--Question 2 - Show customers that have not placed any orders

use AdventureWorks2019
GO
select CustomerId, 
IIF(LastName is null,'Unknown', LastName) as LastName, 
IIF(FirstName is null, 'Unknown', FirstName) as FirstName
from Sales.Customer c left join Person.Person p
on c.PersonID = p.BusinessEntityID
where not exists	
		(select 1 from Sales.SalesOrderHeader
		 where CustomerID = c.CustomerID)
order by CustomerID

--Question 3 - Show the 10 customers that have placed the highest quantity of orders

use AdventureWorks2019
GO
select top 10 c.CustomerId, FirstName, LastName, count(SalesOrderID) as cnt_orders
from Sales.Customer c join Person.Person p 
on c.PersonId = p.BusinessEntityId
join Sales.SalesOrderHeader h 
on c.CustomerID = h.CustomerID
group by c.CustomerId, FirstName, LastName
order by count(SalesOrderID) desc

--Question 4 - Show data of employees, their job titles and the amount of employees that share the same job title

use AdventureWorks2019
GO
select FirstName, LastName, JobTitle, HireDate, 
count(e.BusinessEntityId)over(partition by JobTitle) as CountOfTitle
from HumanResources.Employee e join Person.Person p
on e.BusinessEntityID = p.BusinessEntityID
order by FirstName

--Question 5 - For every customer, show their most recent order date and the second most recent order date

use AdventureWorks2019
GO
WITH cte1 AS
(select * from
(select SalesOrderID, c.CustomerID, FirstName, LastName, orderDate, row_number()over(partition by h.customerId order by orderDate desc) as RN
from Sales.Customer c left join Person.Person p
on c.PersonID = p.BusinessEntityID
join Sales.SalesOrderHeader h 
on h.CustomerID = c.CustomerID) o
where RN=1),
cte2 AS
(select * from
(select c.CustomerID, FirstName, LastName, orderDate, row_number()over(partition by h.customerId order by orderDate desc) as RN
from Sales.Customer c left join Person.Person p
on c.PersonID = p.BusinessEntityID
join Sales.SalesOrderHeader h 
on h.CustomerID = c.CustomerID) o
where RN=2)
select a.SalesOrderID, a.CustomerID, a.LastName, a.FirstName, a.OrderDate as LastOrder, b.OrderDate as PrevOrder
from cte1 a left join cte2 b 
on a.CustomerID = b.CustomerID
order by a.LastName, a.FirstName

--Question 6 - For every year, show the order with the highest total payment and which customer placed the order

use AdventureWorks2019
GO
WITH cte AS
(select distinct year(h.orderDate) as [Year],
max(SubTotal)over(partition by year(OrderDate)) as total
from Sales.SalesOrderHeader h)
select c.year, h.SalesOrderID, p.LastName, p.FirstName, c.total
from Sales.Customer k left join Person.Person p
on k.PersonID = p.BusinessEntityID
join Sales.SalesOrderHeader h 
on h.CustomerID = k.CustomerID
join cte c on c.total = h.SubTotal
order by year(h.orderDate)

--Question 7 - Show the number of orders by months, for every year

use AdventureWorks2019
GO
select * from
(select YEAR(OrderDate) as [year], MONTH(OrderDate) as [month], SalesOrderID
from Sales.SalesOrderHeader) h
PIVOT (count(SalesOrderId) FOR [year] in ([2011],[2012],[2013],[2014])) pvt
order by [month]

--Question 8 - Show the total amount of orders by months, for every year and the cumulative total amount for every year

use AdventureWorks2019
GO
WITH cte1 AS
(select distinct YEAR(OrderDate) as [year], cast(MONTH(OrderDate) as varchar) as [month],
round(sum(SubTotal)over(partition by YEAR(OrderDate),MONTH(OrderDate)),2) as Sum_price
from Sales.SalesOrderHeader)
select [year], [month], sum_price,
sum(Sum_price)over(partition by [year] order by [year],[month]+0
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as [money]
from cte1

UNION

select distinct YEAR(OrderDate) as [year], 'grand_total' as [month], null,
round(sum(SubTotal)over(partition by YEAR(OrderDate)),2) as [money]
from Sales.SalesOrderHeader
order by [year], [money]

--Question 9 - Show the list of employees sorted by their hire date in every department from most to least recent, name and hire date for the last employee hired before them 
--             and the number of days between the two hire dates

use AdventureWorks2019
GO
select *, DATEDIFF(DD,PrevEmpHireDate, HireDate) as DiffDays from
(select Name as DepartmentName, e.BusinessEntityID as EmployeeId, CONCAT(FirstName, ' ', LastName) as EmpFullName, HireDate, 
DATEDIFF(MM,HireDate,GETDATE()) as Seniority,
LEAD(CONCAT(FirstName, ' ', LastName),1)over(partition by h.DepartmentId order by HireDate desc) as PrevEmpName,
LEAD(HireDate,1)over(partition by h.DepartmentId order by HireDate desc) as PrevEmpHireDate
from HumanResources.Employee e left join Person.Person p
on e.BusinessEntityID = p.BusinessEntityID
join HumanResources.EmployeeDepartmentHistory h 
on h.BusinessEntityID = e.BusinessEntityID
join HumanResources.Department d
on d.DepartmentID = h.DepartmentID
where h.EndDate is null) o
order by DepartmentName, HireDate desc

--Question 10 - Show the list of employees that work at the same department and were hired on the same date

use AdventureWorks2019
GO
select HireDate, h.DepartmentID, STRING_AGG(CONCAT(e.BusinessEntityID, ' ', LastName, ' ', FirstName), ' ,') as 'ListEmployees'
from HumanResources.Employee e left join Person.Person p
on e.BusinessEntityID = p.BusinessEntityID
join HumanResources.EmployeeDepartmentHistory h 
on h.BusinessEntityID = e.BusinessEntityID
join HumanResources.Department d
on d.DepartmentID = h.DepartmentID
where h.EndDate is null
GROUP BY HireDate, h.DepartmentID
ORDER BY HireDate