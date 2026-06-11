USE Employees;
GO

CREATE OR ALTER PROCEDURE incremental_load_employees
AS
BEGIN

    BEGIN TRY

        DECLARE @last_load_time DATETIME;
        DECLARE @updated_rows INT;
        DECLARE @inserted_rows INT;
        DECLARE @deleted_rows INT;

        SELECT @last_load_time = last_load_time
        FROM config.load_config
        WHERE id = 1;

        -- Update existing records
        UPDATE s
        SET
            s.first_name = l.first_name,
            s.last_name = l.last_name,
            s.department = l.department,
            s.salary = l.salary,
            s.updated = l.updated
        FROM staging.employees_clean s
        JOIN landing.employees l
            ON s.employee_id = l.employee_id
        WHERE l.updated > @last_load_time;
        
        SET @updated_rows = @@ROWCOUNT;

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
        WHERE s.employee_id IS NULL
          AND l.updated > @last_load_time;

          SET @inserted_rows = @@ROWCOUNT;

          -- Delete records removed from Landing
        DELETE s
        FROM staging.employees_clean s
        LEFT JOIN landing.employees l
            ON s.employee_id = l.employee_id
        WHERE l.employee_id IS NULL;

        SET @deleted_rows = @@ROWCOUNT;

        -- Update last load time
        UPDATE config.load_config
        SET last_load_time = GETDATE()
        WHERE id = 1;

        INSERT INTO config.audit_log
        (
            procedure_name,
            status,
            message
        )
        VALUES
        (
    'incremental_load_employees',
    'SUCCESS',
    'Updated: ' + CAST(@updated_rows AS VARCHAR(10))
        + ', Inserted: ' + CAST(@inserted_rows AS VARCHAR(10))
        + ', Deleted: ' + CAST(@deleted_rows AS VARCHAR(10))
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
            'incremental_load_employees',
            'FAIL',
            ERROR_MESSAGE()
        );

    END CATCH

END;
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
(100, 'Veton', 'Aqifi', 'IT', 2500, GETDATE());
GO

UPDATE landing.employees
SET
    first_name = 'Era',
    updated = '2026-06-09 10:29:59.673'
WHERE employee_id = 40;
GO

DELETE FROM landing.employees
WHERE employee_id = 99;
GO

EXEC incremental_load_employees;
GO

SELECT *
FROM staging.employees_clean
WHERE employee_id = 99;

SELECT *
FROM staging.employees_clean
ORDER BY employee_id;
GO

SELECT *
FROM landing.employees
ORDER BY employee_id;
GO

USE Employees;
GO

SELECT *
FROM config.load_config;
GO

SELECT *
FROM config.audit_log;
GO

SELECT *
FROM staging.employees_clean
WHERE employee_id = 5;
GO