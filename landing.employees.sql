USE Employees;
GO

SELECT
    t.name AS trigger_name,
    OBJECT_SCHEMA_NAME(t.parent_id) AS table_schema,
    OBJECT_NAME(t.parent_id) AS table_name,
    t.is_instead_of_trigger,
    t.is_disabled
FROM sys.triggers AS t
WHERE t.parent_id = OBJECT_ID('landing.employees');
GO

USE Employees;
GO

DELETE FROM landing.employees;
GO

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
(1, 'John', 'Smith', 'IT', 5000.00, GETDATE()),
(2, 'Emma', 'Brown', 'HR', 4500.00, GETDATE()),
(3, 'Michael', 'Davis', 'Finance', 6000.00, GETDATE()),
(4, 'Sarah', 'Wilson', 'Marketing', 4800.00, GETDATE()),
(5, 'David', 'Taylor', 'Sales', 5500.00, GETDATE()),
(6, 'Anna', 'Miller', 'Finance', 6200.00, GETDATE());
GO

SELECT COUNT(*) AS TotalRows
FROM landing.employees;
GO

SELECT *
FROM landing.employees;
GO

DROP TRIGGER IF EXISTS landing.trg_check_employee_id;
GO

CREATE TRIGGER landing.trg_check_employee_id
ON landing.employees
INSTEAD OF INSERT
AS
BEGIN

    IF EXISTS
    (
        SELECT *
        FROM landing.employees e
        JOIN inserted i
            ON e.employee_id = i.employee_id
    )
    BEGIN
        RAISERROR(
            'This ID already exists, please try another one.',
            16,
            1
        );
        RETURN;
    END;

    INSERT INTO landing.employees
    (
        employee_id,
        first_name,
        last_name,
        department,
        salary,
        updated
    )
    SELECT
        employee_id,
        first_name,
        last_name,
        department,
        salary,
        updated
    FROM inserted;

END;
GO

SELECT name
FROM sys.triggers
WHERE parent_id = OBJECT_ID('landing.employees');
GO

SELECT
    employee_id,
    COUNT(*) AS TotalRows
FROM landing.employees
GROUP BY employee_id
HAVING COUNT(*) > 1;
GO

SELECT *
FROM landing.employees
ORDER BY employee_id;
GO