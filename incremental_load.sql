USE Employees;
GO

CREATE OR ALTER PROCEDURE incremental_load
    @SourceSchema VARCHAR(200),
    @SourceTable VARCHAR(200),
    @TargetSchema VARCHAR(200),
    @TargetTable VARCHAR(200),
    @KeyColumn VARCHAR(200),
    @UpdatedColumn VARCHAR(200)
AS
BEGIN

    BEGIN TRY

        DECLARE @sql NVARCHAR(MAX);
        DECLARE @last_load_time DATETIME;
        DECLARE @updated_rows INT;
        DECLARE @inserted_rows INT;
        DECLARE @deleted_rows INT;
        DECLARE @update_columns NVARCHAR(MAX);
        DECLARE @insert_columns NVARCHAR(MAX);
        DECLARE @insert_values NVARCHAR(MAX);

        SELECT @last_load_time = last_load_time
        FROM config.load_config
        WHERE id = 1;

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
        AND name <> @KeyColumn;

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
            ON s.' + QUOTENAME(@KeyColumn) + ' = l.' + QUOTENAME(@KeyColumn) + '
        WHERE l.' + QUOTENAME(@UpdatedColumn) + ' > @last_load_time';

        EXEC sp_executesql
            @sql,
            N'@last_load_time DATETIME',
            @last_load_time = @last_load_time;

        SET @updated_rows = @@ROWCOUNT;

        -- Insert new records

        SET @sql = '
        INSERT INTO ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + '
        (' + @insert_columns + ')
        SELECT ' + @insert_values + '
        FROM ' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable) + ' l
        LEFT JOIN ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + ' s
            ON s.' + QUOTENAME(@KeyColumn) + ' = l.' + QUOTENAME(@KeyColumn) + '
        WHERE s.' + QUOTENAME(@KeyColumn) + ' IS NULL
        AND l.' + QUOTENAME(@UpdatedColumn) + ' > @last_load_time';

        EXEC sp_executesql
            @sql,
            N'@last_load_time DATETIME',
            @last_load_time = @last_load_time;

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
            'incremental_load',
            'FAIL',
            ERROR_MESSAGE()
        );

    END CATCH

END;
GO