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
-- SELECT d.name, SUM(e.salary) AS total_salary
-- FROM departments d
-- JOIN employees e ON d.department_id = e.department_id
-- GROUP BY d.name
-- HAVING SUM(e.salary) > 150000;
SELECT d.name, SUM(e.salary) AS total_salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
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

DROP MATERIALIZED VIEW IF EXISTS project_status_mv;
DROP VIEW IF EXISTS project_status;
DROP VIEW IF EXISTS department_summary;
DROP TABLE IF EXISTS salary_history;
DROP TABLE IF EXISTS employee_certifications;
DROP TABLE IF EXISTS certifications;

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

TRUNCATE employee_certifications;

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





-- TIER 1

SELECT p.project_id,
       p.name AS project_name,
       p.budget,
       COALESCE(SUM(pa.hours_allocated), 0) AS total_hours
FROM projects p
LEFT JOIN project_assignments pa ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name, p.budget
HAVING COALESCE(SUM(pa.hours_allocated), 0) > 0.8 * p.budget;


-- SELECT e.first_name,
--        e.last_name,
--        d1.name AS employee_department,
--        p.name AS project_name,
--        d2.name AS project_department
-- FROM employees e
-- JOIN departments d1 ON e.department_id = d1.department_id
-- JOIN project_assignments pa ON e.employee_id = pa.employee_id
-- JOIN projects p ON pa.project_id = p.project_id
-- JOIN departments d2 ON p.department_id= d2.department_id 
-- WHERE e.department_id <> p.department_id;                   
SELECT DISTINCT e.first_name,
       e.last_name,
       d1.name AS employee_department,
       p.name AS project_name
FROM employees e
JOIN departments d1 ON e.department_id = d1.department_id
JOIN project_assignments pa ON e.employee_id = pa.employee_id
JOIN projects p ON pa.project_id = p.project_id
JOIN employees e2 ON pa.employee_id = e2.employee_id
WHERE e.department_id <> e2.department_id;


-- TIER 2

CREATE VIEW department_summary AS
SELECT d.name AS department_name,
       COUNT(e.employee_id) AS employee_count,
       SUM(e.salary) AS total_salary
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.name;


CREATE VIEW project_status AS
SELECT p.project_id,
       p.name AS project_name,
       p.budget,
       COALESCE(SUM(pa.hours_allocated), 0) AS total_hours,
       CASE 
           WHEN COALESCE(SUM(pa.hours_allocated), 0) > 0.8 * p.budget THEN 'At Risk'
           ELSE 'Normal'
       END AS status
FROM projects p
LEFT JOIN project_assignments pa ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name, p.budget;


CREATE MATERIALIZED VIEW project_status_mv AS
SELECT * FROM project_status;


CREATE OR REPLACE FUNCTION get_department_stats(dept_name TEXT)
RETURNS JSON AS $$
DECLARE result JSON;
BEGIN
    SELECT json_build_object(
        'employee_count', COUNT(e.employee_id),
        'total_salary', SUM(e.salary),
        'active_projects', COUNT(DISTINCT p.project_id)
    )
    INTO result
    FROM departments d
    LEFT JOIN employees e ON d.department_id = e.department_id
    LEFT JOIN projects p ON d.department_id = p.department_id   
    WHERE d.name = dept_name;

    RETURN result;
END;
$$ LANGUAGE plpgsql;



-- TIER 3

CREATE TABLE salary_history (
    id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(employee_id),
    salary NUMERIC NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE
);


INSERT INTO salary_history (employee_id, salary, start_date, end_date)
SELECT employee_id, salary, CURRENT_DATE, NULL
FROM employees;


INSERT INTO salary_history (employee_id, salary, start_date, end_date)
SELECT employee_id, salary * 0.8, CURRENT_DATE - INTERVAL '3 years', CURRENT_DATE - INTERVAL '2 years'
FROM employees;

INSERT INTO salary_history (employee_id, salary, start_date, end_date)
SELECT employee_id, salary * 0.9, CURRENT_DATE - INTERVAL '2 years', CURRENT_DATE - INTERVAL '1 year'
FROM employees;


SELECT d.name AS department_name,
       e.employee_id,
       MAX(sh.salary) - MIN(sh.salary) AS salary_growth
FROM salary_history sh
JOIN employees e ON sh.employee_id = e.employee_id
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.name, e.employee_id;


SELECT e.first_name,
       e.last_name,
       MAX(sh.start_date) AS last_change
FROM employees e
JOIN salary_history sh ON e.employee_id = sh.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name
HAVING MAX(sh.start_date) < CURRENT_DATE - INTERVAL '12 months';
