USE Employees;
GO

-- Create Schemas
CREATE SCHEMA landing;
GO

CREATE SCHEMA staging;
GO

CREATE SCHEMA config;
GO

-- Source Table (Landing Layer)
CREATE TABLE landing.employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary DECIMAL(10,2),
    updated DATETIME
);
GO

-- Target Table (Staging Layer)
CREATE TABLE staging.employees_clean (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department VARCHAR(50),
    salary DECIMAL(10,2),
    updated DATETIME
);
GO

-- Incremental Load Configuration Table
CREATE TABLE config.load_config (
    id INT IDENTITY(1,1) PRIMARY KEY,
    last_load_time DATETIME
);
GO

-- Audit Table
CREATE TABLE config.audit_log (
    id INT IDENTITY(1,1) PRIMARY KEY,
    procedure_name VARCHAR(100),
    status VARCHAR(20),
    message VARCHAR(255),
    log_time DATETIME DEFAULT GETDATE()
);
GO

SELECT *
FROM config.load_config;
GO