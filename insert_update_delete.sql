USE Employees;
GO

CREATE OR ALTER PROCEDURE iud
    @SourceSchema VARCHAR(200),
    @SourceTable VARCHAR(200),
    @TargetSchema VARCHAR(200),
    @TargetTable VARCHAR(200),
    @KeyColumn VARCHAR(200)
AS
BEGIN

    BEGIN TRY

        DECLARE @sql NVARCHAR(MAX);
        DECLARE @updated_rows INT;
        DECLARE @inserted_rows INT;
        DECLARE @deleted_rows INT;
        DECLARE @update_columns NVARCHAR(MAX);
        DECLARE @insert_columns NVARCHAR(MAX);
        DECLARE @insert_values NVARCHAR(MAX);

        -- Get columns dynamically

        SELECT @update_columns =
            STRING_AGG(
                's.' + QUOTENAME(name) + ' = l.' + QUOTENAME(name),
                ', '
            )
        FROM sys.columns
        WHERE object_id = OBJECT_ID(
            QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable)
        )
        AND name <> @KeyColumn
        AND is_identity = 0
        AND is_computed = 0;

        SELECT @insert_columns =
            STRING_AGG(
                QUOTENAME(name),
                ', '
            )
        FROM sys.columns
        WHERE object_id = OBJECT_ID(
            QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable)
        )
        AND is_identity = 0
        AND is_computed = 0;

        SELECT @insert_values =
            STRING_AGG(
                'l.' + QUOTENAME(name),
                ', '
            )
        FROM sys.columns
        WHERE object_id = OBJECT_ID(
            QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable)
        )
        AND is_identity = 0
        AND is_computed = 0;

        -- Update existing records

        SET @sql = '
        UPDATE s
        SET ' + @update_columns + '
        FROM ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + ' s
        INNER JOIN ' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable) + ' l
            ON s.' + QUOTENAME(@KeyColumn) + ' = l.' + QUOTENAME(@KeyColumn);

        EXEC sp_executesql @sql;

        SET @updated_rows = @@ROWCOUNT;

        -- Insert new records

        SET @sql = '
        INSERT INTO ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + '
        (' + @insert_columns + ')
        SELECT ' + @insert_values + '
        FROM ' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable) + ' l
        LEFT JOIN ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + ' s
            ON l.' + QUOTENAME(@KeyColumn) + ' = s.' + QUOTENAME(@KeyColumn) + '
        WHERE s.' + QUOTENAME(@KeyColumn) + ' IS NULL';

        EXEC sp_executesql @sql;

        SET @inserted_rows = @@ROWCOUNT;

        -- Delete records removed from source

        SET @sql = '
        DELETE s
        FROM ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + ' s
        LEFT JOIN ' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable) + ' l
            ON s.' + QUOTENAME(@KeyColumn) + ' = l.' + QUOTENAME(@KeyColumn) + '
        WHERE l.' + QUOTENAME(@KeyColumn) + ' IS NULL';

        EXEC sp_executesql @sql;

        SET @deleted_rows = @@ROWCOUNT;

        -- Audit

        INSERT INTO config.audit_log
        (
            procedure_name,
            status,
            message
        )
        VALUES
        (
            'iud',
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
            'iud',
            'FAIL',
            ERROR_MESSAGE()
        );

        THROW;

    END CATCH

END;
GO