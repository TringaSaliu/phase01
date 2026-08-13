USE Employees;
GO

CREATE OR ALTER PROCEDURE dbo.InsertUpdateDelete
    @SourceSchema VARCHAR(200),
    @TargetSchema VARCHAR(200),
    @TargetTableName VARCHAR(200),
    @SourceTableName VARCHAR(200)
AS
BEGIN

    DECLARE @sql NVARCHAR(MAX);

    BEGIN TRY

        SET @sql = '
        UPDATE target
        SET
            target.first_name = source.first_name,
            target.last_name = source.last_name,
            target.department = source.department,
            target.salary = source.salary,
            target.updated = source.updated
        FROM ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTableName) + ' target
        INNER JOIN ' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTableName) + ' source
            ON target.employee_id = source.employee_id;


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
        FROM ' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTableName) + ' source
        LEFT JOIN ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTableName) + ' target
            ON target.employee_id = source.employee_id
        WHERE target.employee_id IS NULL;


        DELETE target
        FROM ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTableName) + ' target
        LEFT JOIN ' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTableName) + ' source
            ON target.employee_id = source.employee_id
        WHERE source.employee_id IS NULL;
        ';

        EXEC sp_executesql @sql;

        INSERT INTO config.audit_log
        (
            procedure_name,
            status,
            message
        )
        VALUES
        (
            'InsertUpdateDelete',
            'SUCCESS',
            'Insert, update and delete completed successfully.'
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
            'InsertUpdateDelete',
            'FAIL',
            ERROR_MESSAGE()
        );

        THROW;

    END CATCH

END;
GO
-- Add new employees
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
(25, 'Hana  ', 'Johnson', 'HR', 4700.00, GETDATE()),
(30, 'Jon', 'Anderson', 'IT', 5200.00, GETDATE());
GO

-- Update an existing employee
UPDATE landing.employees
SET
    first_name = 'Era',
    salary = 20000.00,
    updated = GETDATE()
WHERE employee_id = 1;
GO

-- Delete employees
DELETE FROM landing.employees
WHERE employee_id IN (12, 14, 20);
GO

SELECT *
FROM landing.employees;

SELECT *
FROM staging.employees_clean;

exec dbo.InsertUpdateDelete
    @SourceSchema = 'landing',
    @TargetSchema = 'staging',
    @SourceTableName = 'employees',
    @TargetTableName = 'employees_clean';