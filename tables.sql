USE Employees;
GO

-- Create schemas if they do not already exist
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'landing')
BEGIN
    EXEC('CREATE SCHEMA landing');
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'staging')
BEGIN
    EXEC('CREATE SCHEMA staging');
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'config')
BEGIN
    EXEC('CREATE SCHEMA config');
END;
GO


-- Landing table
IF OBJECT_ID('landing.employees', 'U') IS NULL
BEGIN
    CREATE TABLE landing.employees
    (
        employee_id INT PRIMARY KEY,
        first_name VARCHAR(50),
        last_name VARCHAR(50),
        department VARCHAR(50),
        salary DECIMAL(10,2),
        updated DATETIME
    );
END;
GO


-- Staging table
IF OBJECT_ID('staging.employees_clean', 'U') IS NULL
BEGIN
    CREATE TABLE staging.employees_clean
    (
        employee_id INT PRIMARY KEY,
        first_name VARCHAR(50) NOT NULL,
        last_name VARCHAR(50) NOT NULL,
        department VARCHAR(50),
        salary DECIMAL(10,2),
        updated DATETIME
    );
END;
GO


-- Configuration table
IF OBJECT_ID('config.load_config', 'U') IS NULL
BEGIN
    CREATE TABLE config.load_config
    (
        id INT IDENTITY(1,1) PRIMARY KEY,
        last_load_time DATETIME
    );
END;
GO


-- Add the initial load time
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


-- Audit table
IF OBJECT_ID('config.audit_log', 'U') IS NULL
BEGIN
    CREATE TABLE config.audit_log
    (
        id INT IDENTITY(1,1) PRIMARY KEY,
        procedure_name VARCHAR(100),
        status VARCHAR(20),
        message VARCHAR(255),
        log_time DATETIME DEFAULT GETDATE()
    );
END;
GO


-- Check the configuration
SELECT *
FROM config.load_config;
GO