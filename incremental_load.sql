USE Employees;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'config')
BEGIN
    EXEC('CREATE SCHEMA config');
END;
GO

IF OBJECT_ID('config.load_config', 'U') IS NULL
BEGIN
    CREATE TABLE config.load_config
    (
        id INT IDENTITY(1,1) PRIMARY KEY,
        last_load_time DATETIME
    );
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM config.load_config
    WHERE id = 1
)
BEGIN
    INSERT INTO config.load_config (last_load_time)
    VALUES ('1900-01-01');
END;
GO

CREATE OR ALTER PROCEDURE incremental_load
    @SourceSchema VARCHAR(200),
    @TargetSchema VARCHAR(200),
    @TargetTableName VARCHAR(200),
    @SourceTableName VARCHAR(200)
AS
BEGIN

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @last_load_time DATETIME;

    BEGIN TRY

        SELECT @last_load_time = last_load_time
        FROM config.load_config
        WHERE id = 1;


        -- Update existing employees

        SET @sql = '
        UPDATE target
        SET
            target.first_name = source.first_name,
            target.last_name = source.last_name,
            target.department = source.department,
            target.salary = source.salary,
            target.updated = source.updated
        FROM ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTableName) + ' AS target
        INNER JOIN ' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTableName) + ' AS source
            ON target.employee_id = source.employee_id
        WHERE source.updated > @last_load_time;
        ';

        EXEC sp_executesql
            @sql,
            N'@last_load_time DATETIME',
            @last_load_time = @last_load_time;


        -- Insert new employees

        SET @sql = '
        INSERT INTO ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTableName) + '
        (
            employee_id,
            first_name,
            last_name,
            department,
            salary,
            updated
        )
        SELECT
            source.employee_id,
            source.first_name,
            source.last_name,
            source.department,
            source.salary,
            source.updated
        FROM ' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTableName) + ' AS source
        LEFT JOIN ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTableName) + ' AS target
            ON target.employee_id = source.employee_id
        WHERE target.employee_id IS NULL
        AND source.updated > @last_load_time;
        ';

        EXEC sp_executesql
            @sql,
            N'@last_load_time DATETIME',
            @last_load_time = @last_load_time;


        -- Update last load time

        UPDATE config.load_config
        SET last_load_time = GETDATE()
        WHERE id = 1;


        -- Audit

        INSERT INTO config.audit_log
        (
            procedure_name,
            status,
            message
        )
        VALUES
        (
            'incremental_load',
            'SUCCESS',
            'Incremental load completed successfully.'
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
            'incremental_load',
            'FAIL',
            ERROR_MESSAGE()
        );

        THROW;

    END CATCH

END;
GO

SELECT *
FROM config.load_config;
GO

-- create a new employee 
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
(50, 'Laura', 'Garcia', 'Finance', 6100.00, GETDATE()),
(100, 'Tringa', 'Saliu', 'IT', 9000.00, '2026-08-12 14:20:31.403');
GO

--update existing employee
UPDATE landing.employees
SET
    salary = 6300.00,
    updated = GETDATE()
WHERE employee_id = 3;
GO

--check the source
SELECT *
FROM landing.employees
ORDER BY employee_id;
GO


EXEC incremental_load
    @SourceSchema = 'landing',
    @TargetSchema = 'staging',
    @SourceTableName = 'employees',
    @TargetTableName = 'employees_clean';
GO

--check the target
SELECT *
FROM staging.employees_clean
ORDER BY employee_id;
GO

SELECT *
FROM config.load_config;
GO

SELECT *
FROM config.audit_log
ORDER BY id DESC;
GO

select * from config.load_config;
