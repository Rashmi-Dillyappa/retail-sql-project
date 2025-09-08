When to use Rownum() and Rank or Dense_Rank()

Overall Top N (no grouping by department)
-----------------------------------------------
👉 Use ROW_NUMBER()

You just want “the single highest / 2nd highest / Nth highest salary across the whole company

Example: Find the 2nd highest salary in the whole org.
-------------------------------------------------------
SELECT EmployeeID, FullName, Salary
FROM (
    SELECT EmployeeID, FullName, Salary,
           ROW_NUMBER() OVER (ORDER BY Salary DESC) AS rn
    FROM Employees
) x
WHERE rn = 2;
--------------------------------------------------------

Department-wise Top N (partitioned ranking)
--------------------------------------------------------
👉 Use DENSE_RANK() or RANK()

You want “highest / 2nd highest salary in each department

Example: Find 2nd highest salary employee(s) in every department.
--------------------------------------------------------------------------------------------
SELECT DepartmentID, EmployeeID, FullName, Salary
FROM (
    SELECT DepartmentID, EmployeeID, FullName, Salary,
           DENSE_RANK() OVER (PARTITION BY DepartmentID ORDER BY Salary DESC) AS drnk
    FROM Employees
) x
WHERE drnk = 2;
-------------------------------------------------------------------------------------------

🔹 Here PARTITION BY DepartmentID resets ranking inside each department.
🔹 Use DENSE_RANK() if you want all employees tied at 2nd highest.

Simple rule to remember:
---------------------------
1.Company-wide Nth highest → ROW_NUMBER()
2.Department-wise Nth highest → DENSE_RANK() / RANK() with PARTITION BY

--Rashmi Dillyappa 







Department-wise Nth highest → DENSE_RANK() / RANK() with PARTITION BY
