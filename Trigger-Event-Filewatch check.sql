💡 1️⃣ AUTOMATION TASKS (Python + PySpark)
✅ a) File Watcher – detect new CSV files automatically
import os, time
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("FileWatcherETL").getOrCreate()
input_dir = "/data/incoming/"
processed_dir = "/data/processed/"

def process_file(file_path):
    df = spark.read.csv(file_path, header=True, inferSchema=True)
    df.show(5)
    df.write.mode("append").parquet("/data/output/cleaned/")
    os.rename(file_path, processed_dir + os.path.basename(file_path))

# Watch folder every minute
while True:
    new_files = [f for f in os.listdir(input_dir) if f.endswith(".csv")]
    for file in new_files:
        process_file(os.path.join(input_dir, file))
        print(f"Processed: {file}")
    time.sleep(60)


🧠 Purpose: Automates ETL trigger when new file arrives → no manual intervention.

✅ b) Automatic Email Alert on ETL Failure
import smtplib
from email.mime.text import MIMEText

def send_email_alert(subject, message):
    sender = "etl-monitor@company.com"
    recipients = ["rashmi@company.com"]
    msg = MIMEText(message)
    msg["Subject"] = subject
    msg["From"] = sender
    msg["To"] = ", ".join(recipients)

    with smtplib.SMTP("smtp.gmail.com", 587) as server:
        server.starttls()
        server.login("etl.monitor@gmail.com", "app_password")
        server.sendmail(sender, recipients, msg.as_string())

# Example: use after try-except
try:
    # ETL Logic
    print("ETL running...")
    raise Exception("Database connection failed")
except Exception as e:
    send_email_alert("ETL Job Failed 🚨", f"Error: {e}")


🧠 Purpose: Sends real-time notification when job fails or completes successfully.

✅ c) Logging ETL Completion (Audit Log)
from datetime import datetime
import logging

logging.basicConfig(filename="etl_audit.log", level=logging.INFO)

def log_etl_status(status):
    logging.info(f"{datetime.now()} - ETL Status: {status}")

try:
    # your ETL process here
    log_etl_status("Started")
    # Transformation, loading, etc.
    log_etl_status("Completed Successfully ✅")
except Exception as e:
    log_etl_status(f"Failed ❌: {str(e)}")


🧠 Purpose: Creates automated logs for monitoring and traceability.

⚙️ 2️⃣ ADVANCED DATA TRANSFORMATIONS (PySpark & Spark SQL)
✅ a) PySpark — Complex Business Transformation

Let’s take a retail transaction dataset and do cleansing + analytics.

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, round, when, avg, countDistinct, sum, year, month

spark = SparkSession.builder.appName("TransformationETL").getOrCreate()

df = spark.read.csv("transactions.csv", header=True, inferSchema=True)

# Remove special chars and clean
df = df.withColumn("customer_name", regexp_replace(col("customer_name"), "[^a-zA-Z0-9 ,.-]", ""))

# Add derived columns
df = df.withColumn("discount_flag", when(col("discount") > 0, "YES").otherwise("NO"))

# Aggregation
summary_df = df.groupBy("customer_id").agg(
    round(avg("amount"), 2).alias("avg_spend"),
    countDistinct("trans_id").alias("transaction_count"),
    sum("discount").alias("total_discount")
)

summary_df.show(5)

✅ b) Spark SQL — Advanced Joins and Time Intelligence
df.createOrReplaceTempView("transactions")

# Example: Monthly sales, previous month comparison
spark.sql("""
SELECT 
    customer_id,
    DATE_TRUNC('month', trans_date) AS month,
    SUM(amount) AS total_sales,
    LAG(SUM(amount)) OVER (PARTITION BY customer_id ORDER BY DATE_TRUNC('month', trans_date)) AS prev_sales,
    ROUND((SUM(amount) - LAG(SUM(amount)) OVER (PARTITION BY customer_id ORDER BY DATE_TRUNC('month', trans_date))) 
          / NULLIF(LAG(SUM(amount)) OVER (PARTITION BY customer_id ORDER BY DATE_TRUNC('month', trans_date)),0) * 100, 2) 
          AS growth_pct
FROM transactions
GROUP BY customer_id, DATE_TRUNC('month', trans_date)
ORDER BY customer_id, month;
""").show()


🧠 Purpose: Shows month-over-month growth — a real ETL reporting use case.

⚡ 3️⃣ AUTO ALERT WHEN FILE IS MISSING OR EMPTY
import os, smtplib
from email.mime.text import MIMEText

def check_file(file_path):
    if not os.path.exists(file_path):
        send_email_alert("File Missing ⚠️", f"{file_path} not found!")
    elif os.path.getsize(file_path) == 0:
        send_email_alert("Empty File ⚠️", f"{file_path} is empty!")

check_file("/data/incoming/customer_info.csv")

🧠 4️⃣ INTERVIEW EXPLAINER (how to say it)

“I use Python and PySpark to automate ETL processes —
