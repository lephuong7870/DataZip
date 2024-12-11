CREATE DATABASE dz_test;

USE dz_test;

CREATE TABLE dz_test
(
    B Int64,          -- A 64-bit integer column
    T String,         -- A string (text) column
    D Date            -- A date column
) 
ENGINE = MergeTree          -- Using the MergeTree engine for table storage
PARTITION BY D              -- Partitioning the data by the 'D' (Date) column
ORDER BY B                  -- Ordering data by the 'B' column for efficient query execution


insert into dz_test select number, number, '2023-01-01' from numbers(1e4);
select * from dz_test

insert into dz_test select number, number, '2023-01-01' from numbers(1e9);


s3

INSERT INTO FUNCTION s3(
    'https://s3-bucket-clickhouse-1.s3.us-east-1.amazonaws.com/data/',  -- Your S3 path
    'AKIA5FTZCHRINFSSSCXM',  -- AWS Access Key
    'loHd78xdP7nKyZ92y8qLuNQLRx1HbAYwq2FPrAbg',  -- AWS Secret Key
    'CSV'  -- File format (CSV in this case)
)
SELECT
    number AS column1,  -- Adjust the column name to match the S3 schema
    number AS column2,  -- If you're inserting the same data into two columns, adjust as needed
    '2023-01-01' AS date_column  -- A constant column (adjust based on your schema)
FROM numbers(1e9)
LIMIT 10000;