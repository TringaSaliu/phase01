USE Employees;
GO

CREATE OR ALTER PROCEDURE upsert_employees
AS
BEGIN

    BEGIN TRY

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

        INSERT INTO config.audit_log
        (
            procedure_name,
            status,
            message
        )
        VALUES
        (
            'upsert_employees',
            'SUCCESS',
            'Upsert completed'
        ); 

    END TRY

    BEGIN CATCH

        INSERT INTO config.audit_log
        (
            procedure_name,
            status,
            message
        )
        VALUES
        (
            'upsert_employees',
            'FAIL',
            ERROR_MESSAGE()
        );

    END CATCH

END;
GO

EXEC upsert_employees;
GO

SELECT *
FROM staging.employees_clean
ORDER BY employee_id;
GO

SELECT *
FROM landing.employees
ORDER BY employee_id;
GO

SELECT *
FROM config.audit_log;
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
(13, 'Maria', 'Johnson', 'IT', 5200, GETDATE());

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
(20, 'Maria', 'Johnson', 'IT', 5200, GETDATE());

UPDATE landing.employees
SET
    first_name = 'Tringa',
    updated = GETDATE()
WHERE employee_id = 5;

