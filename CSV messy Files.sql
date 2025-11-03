COPY stg_customer
FROM 's3://origin-energy-data/customer/customer_clean.csv'
IAM_ROLE 'arn:aws:iam::123456789012:role/RedshiftS3Access'
CSV
IGNOREHEADER 1
BLANKSASNULL
EMPTYASNULL
TRUNCATECOLUMNS;



1️⃣ Bash (Linux / Mac / WSL)
Suppose customer.csv has:
Multiple headers repeated
Blank lines before or after header

Command to clean:

awk 'NR==1 {h=$0; print; next} $0 != h && NF > 0 {print}' customer.csv > customer_clean.csv

Explanation:
NR==1 {h=$0; print; next} → save first line as header h and print it.
$0 != h → skip rows identical to header (repeated headers).
NF > 0 → skip blank rows.
Output: customer_clean.csv → ready for Redshift COPY.

✅ Works for small or medium CSV files.


import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import pyspark.sql.functions as F

## Glue context setup
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# Read CSV with header
df = spark.read.option("header","true").csv("s3://origin-energy-data/customer/")

# Remove blank rows
df_clean = df.dropna(how="all")

# Remove repeated header rows (if header appears as a row)
header_row = df_clean.columns
df_clean = df_clean.filter(~F.concat_ws(",",*df_clean.columns).isin([",".join(header_row)]))

# Write to staging S3 (or directly to Redshift)
df_clean.write \
    .format("csv") \
    .mode("overwrite") \
    .save("s3://origin-energy-data/staging/customer_clean/")
✅ Advantages:

Handles large files.

Can remove repeated headers and blanks dynamically.

Can write directly to Redshift via Glue connectors.
