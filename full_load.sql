USE Employees;
GO


CREATE OR ALTER PROCEDURE full_load_employees
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        DECLARE @rows_inserted INT;

        TRUNCATE TABLE staging.employees_clean;

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
            employee_id,
            first_name,
            last_name,
            department,
            salary,
            updated
        FROM landing.employees;

        SET @rows_inserted = @@ROWCOUNT;

        INSERT INTO config.audit_log
        (
            procedure_name,
            status,
            message
        )
        VALUES
        (
            'full_load_employees',
            'SUCCESS',
            'Full load completed. Rows inserted: ' + CAST(@rows_inserted AS VARCHAR(10))
        );

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH

        ROLLBACK TRANSACTION;

        INSERT INTO config.audit_log
        (
            procedure_name,
            status,
            message
        )
        VALUES
        (
            'full_load_employees',
            'FAIL',
            ERROR_MESSAGE()
        );

    END CATCH
END;
GO

EXEC full_load_employees;
GO

SELECT *
FROM landing.employees;
GO

SELECT *
FROM staging.employees_clean;
GO

SELECT *
FROM config.audit_log;
GO
