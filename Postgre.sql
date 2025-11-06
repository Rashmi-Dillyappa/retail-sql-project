🧱 PostgreSQL Options to Load from S3
Option 1️⃣: Use aws_s3 extension (RDS or Aurora Postgres)

If you’re on AWS RDS or Aurora PostgreSQL, AWS gives you a built-in extension called aws_s3.

Enable it:

CREATE EXTENSION IF NOT EXISTS aws_s3 CASCADE;


Then you can run:

SELECT aws_s3.table_import_from_s3(
    'schema.table_name',        -- Target table
    '',                         -- Columns (empty = all)
    '(format csv, delimiter '','', header true)',
    'bucket-name',              -- Your S3 bucket
    'path/to/file.csv',         -- File path
    'us-east-1',                -- Region
    aws_commons.create_aws_credentials(
        'ACCESS_KEY_ID',
        'SECRET_ACCESS_KEY',
        ''
    )
);


✅ Works like Redshift COPY but uses a function instead.
⚠️ Only supported in RDS / Aurora PostgreSQL, not local Postgres.

Option 2️⃣: If You’re Using Local PostgreSQL or EC2

Mount your S3 bucket to the file system using one of these:

s3fs → Mounts S3 as a local folder

AWS CLI sync → Copies files from S3 to local /mnt/s3_bucket/

Then use the normal PostgreSQL COPY:

COPY schema.table_name
FROM '/mnt/s3_bucket/path/to/file.csv'
DELIMITER ',' 
CSV HEADER;


✅ Works perfectly for on-prem or EC2-hosted PostgreSQL.

Option 3️⃣: Use Foreign Data Wrapper (postgres_fdw or file_fdw)

If you have CSVs that are constantly refreshed, use a foreign table:

CREATE EXTENSION file_fdw;

CREATE SERVER csv_server FOREIGN DATA WRAPPER file_fdw;

CREATE FOREIGN TABLE stg_transaction (
    transaction_id INT,
    customer_id INT,
    product_id INT,
    transaction_date DATE,
    quantity INT,
    amount NUMERIC
)
SERVER csv_server
OPTIONS (filename '/mnt/s3_bucket/transaction.csv', format 'csv', header 'true');


Then query directly:

SELECT * FROM stg_transaction;


You can even INSERT INTO fact_transaction SELECT * FROM stg_transaction;
No need to COPY each time.

✅ Summary
Use Case	Best Option	Command
AWS RDS / Aurora PostgreSQL	aws_s3.table_import_from_s3()	✅ Fast, serverless
On-prem / EC2	COPY FROM '/mnt/s3_bucket/file.csv'	Mount S3 first
Constant CSV source	file_fdw	Read CSVs directly
💬 Bonus Tip: Validation after COPY

You can immediately log results into your audit_log after the load:

INSERT INTO audit_log(step_name, table_name, issue_type, issue_details)
VALUES('EXTRACT', 'stg_transaction', 'INFO', 'Data successfully imported from S3');
