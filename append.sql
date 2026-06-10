USE Employees;
GO

CREATE OR ALTER PROCEDURE append_employees
AS
BEGIN

    BEGIN TRY

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
            'append_employees',
            'SUCCESS',
            'Append load completed'
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
            'append_employees',
            'FAIL',
            ERROR_MESSAGE()
        );

    END CATCH

END;
GO

EXEC append_employees;
GO

SELECT *
FROM staging.employees_clean
ORDER BY employee_id;
GO

SELECT COUNT(*) AS StagingRows
FROM staging.employees_clean;
GO

SELECT *
FROM landing.employees
ORDER BY employee_id;
GO

SELECT COUNT(*) AS LandingRows
FROM landing.employees;
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
(12, 'Maria', 'Johnson', 'IT', 5200, GETDATE());
