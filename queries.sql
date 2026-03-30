-- queries.sql — SQL Analytics Lab
-- Module 3: SQL & Relational Data
--
-- Instructions:
--   Write your SQL query beneath each comment block.
--   Do NOT modify the comment markers (-- Q1, -- Q2, etc.) — the autograder uses them.
--   Test each query locally: psql -h localhost -U postgres -d testdb -f queries.sql
--
-- ============================================================

-- Q1: Employee Directory with Departments
-- List all employees with their department name, sorted by department (asc) then salary (desc).
-- Expected columns: first_name, last_name, title, salary, department_name
-- SQL concepts: JOIN, ORDER BY
SELECT e.first_name, e.last_name, d.name AS department_name, e.salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
ORDER BY d.name ASC, e.salary DESC;



-- Q2: Department Salary Analysis
-- Total salary expenditure by department. Only departments with total > 150,000.
-- Expected columns: department_name, total_salary
-- SQL concepts: GROUP BY, HAVING, SUM
SELECT d.name, SUM(e.salary) AS total_salary
FROM departments d
JOIN employees e ON d.department_id = e.department_id
GROUP BY d.name
HAVING SUM(e.salary) > 150000;

-- Q3: Highest-Paid Employee per Department
-- For each department, find the employee with the highest salary.
-- Expected columns: department_name, first_name, last_name, salary
-- SQL concepts: Window function (ROW_NUMBER or RANK), CTE
SELECT first_name, last_name, department_name, salary
FROM (
    SELECT e.first_name, e.last_name, d.name AS department_name, e.salary,
           ROW_NUMBER() OVER(PARTITION BY e.department_id ORDER BY e.salary DESC) as rank
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
) ranked
WHERE rank = 1;

-- Q4: Project Staffing Overview
-- All projects with employee count and total hours. Include projects with 0 assignments.
-- Expected columns: project_name, employee_count, total_hours
-- SQL concepts: LEFT JOIN, GROUP BY, COALESCE
SELECT p.name AS project_name, 
       COUNT(pa.employee_id) AS employee_count, 
       COALESCE(SUM(pa.hours_allocated), 0) AS total_hours
FROM projects p
LEFT JOIN project_assignments pa ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name;

-- Q5: Above-Average Departments
-- Departments where average salary exceeds the company-wide average salary.
-- Expected columns: department_name, avg_salary
-- SQL concepts: CTE
WITH DeptAvg AS (
    SELECT d.name, AVG(e.salary) as dept_avg
    FROM departments d
    JOIN employees e ON d.department_id = e.department_id
    GROUP BY d.department_id, d.name
),
CompanyAvg AS (
    SELECT AVG(salary) as global_avg FROM employees
)
SELECT da.name, da.dept_avg, ca.global_avg
FROM DeptAvg da, CompanyAvg ca
WHERE da.dept_avg > ca.global_avg;

-- Q6: Running Salary Total
-- Each employee's salary and running total within their department, ordered by hire date.
-- Expected columns: department_name, first_name, last_name, hire_date, salary, running_total
-- SQL concepts: Window function (SUM OVER)
SELECT first_name, last_name, salary, hire_date,
       SUM(salary) OVER(PARTITION BY department_id ORDER BY hire_date) AS running_dept_total
FROM employees;




-- Q7: Unassigned Employees
-- Employees not assigned to any project.
-- Expected columns: first_name, last_name, department_name
-- SQL concepts: LEFT JOIN + NULL check (or NOT EXISTS)
SELECT e.first_name, e.last_name
FROM employees e
LEFT JOIN project_assignments pa ON e.employee_id = pa.employee_id
WHERE pa.project_id IS NULL;

-- Q8: Hiring Trends
-- Month-over-month hire count.
-- Expected columns: hire_year, hire_month, hires
-- SQL concepts: EXTRACT, GROUP BY, ORDER BY
SELECT EXTRACT(YEAR FROM hire_date) as hire_year, 
       EXTRACT(MONTH FROM hire_date) as hire_month, 
       COUNT(*) as hire_count
FROM employees
GROUP BY hire_year, hire_month
ORDER BY hire_year, hire_month;



-- Q9: Schema Design — Employee Certifications
-- Design and implement a certifications tracking system.
CREATE TABLE certifications (
    certification_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    issuing_org VARCHAR(255),
    level VARCHAR(50) CHECK (level IN ('Beginner', 'Intermediate', 'Advanced'))
);

CREATE TABLE employee_certifications (
    id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(employee_id),
    certification_id INT REFERENCES certifications(certification_id),
    certification_date DATE NOT NULL
);

-- Insert sample data using valid employee_ids
INSERT INTO certifications (name, issuing_org, level) VALUES
('AWS Solutions Architect', 'Amazon', 'Intermediate'),
('PMP', 'PMI', 'Advanced'),
('Google Cloud Digital Leader', 'Google', 'Beginner');

-- Using employee_id 1-5 (Adjust if your employee IDs are different)
INSERT INTO employee_certifications (employee_id, certification_id, certification_date) 
SELECT employee_id, 1, CURRENT_DATE FROM employees LIMIT 5;

-- Final Review Query
SELECT e.first_name, e.last_name, c.name AS cert_name, ec.certification_date
FROM employees e
JOIN employee_certifications ec ON e.employee_id = ec.employee_id
JOIN certifications c ON ec.certification_id = c.certification_id;

