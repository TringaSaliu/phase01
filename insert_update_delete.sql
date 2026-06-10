USE Employees;
GO

CREATE OR ALTER PROCEDURE iud_employees
AS
BEGIN

    -- Update existing records
    UPDATE s
    SET
        s.first_name = l.first_name,
        s.last_name = l.last_name,
        s.department = l.department,
        s.salary = l.salary,
        s.updated = l.updated
    FROM staging.employees_clean s
    INNER JOIN landing.employees l
        ON s.employee_id = l.employee_id;

    -- Insert new records
    INSERT INTO staging.employees_clean
    (
        employee_id,
        first_name,
        last_name,
        department,
        salary,
        updated
    )
    SELECT
        l.employee_id,
        l.first_name,
        l.last_name,
        l.department,
        l.salary,
        l.updated
    FROM landing.employees l
    LEFT JOIN staging.employees_clean s
        ON l.employee_id = s.employee_id
    WHERE s.employee_id IS NULL;

    -- Delete records removed from Landing
    DELETE s
    FROM staging.employees_clean s
    LEFT JOIN landing.employees l
        ON s.employee_id = l.employee_id
    WHERE l.employee_id IS NULL;

END;
GO

EXEC iud_employees;
GO

SELECT *
FROM landing.employees;
GO

SELECT *
FROM staging.employees_clean;
GO

 INSERT INTO staging.employees_clean
(
    employee_id,
    first_name,
    last_name,
    department,
    salary,
    updated
)
VALUES
(21, 'Veton', 'Johnson', 'IT', 5200, GETDATE());

 INSERT INTO landing.employees
(
    employee_id,
    first_name,
    last_name,
    department,
    salary,
    updated
)
VALUES
(104, 'Ela', 'Johnson', 'IT', 5200, GETDATE());

UPDATE landing.employees
SET
    first_name = 'Nedim',
    updated = GETDATE()
WHERE employee_id = 4;

DELETE FROM landing.employees
WHERE employee_id = 100 AND first_name = 'Veton';

