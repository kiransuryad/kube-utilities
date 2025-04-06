
import subprocess
import pandas as pd
import json
from pathlib import Path

# === Step 1: Get active services from Steampipe cost table ===
print("Fetching active services with cost > 0...")
cost_query = """
select
  service,
  region,
  round(sum(unblended_cost), 2) as cost_usd
from
  aws_cost_by_service_monthly
where
  start_time >= date_trunc('month', current_date - interval '1 month')
group by
  service, region
having sum(unblended_cost) > 0
order by
  service;
"""

result = subprocess.run(
    ["steampipe", "query", "--output=json"],
    input=cost_query,
    text=True,
    capture_output=True
)

if result.returncode != 0:
    print("Failed to fetch cost data:", result.stderr)
    exit(1)

cost_data = json.loads(result.stdout)
cost_df = pd.DataFrame(cost_data)
cost_df.to_csv("active_services_cost.csv", index=False)
print("Saved active services with cost > 0 to active_services_cost.csv")

# === Step 2: Identify services and query inventory ===
# Map AWS Cost service names to corresponding Steampipe table names
service_table_map = {
    "Amazon EC2": "aws_ec2_instance",
    "Amazon S3": "aws_s3_bucket",
    "Amazon RDS": "aws_rds_db_instance",
    "Amazon DynamoDB": "aws_dynamodb_table",
    "AWS Lambda": "aws_lambda_function",
    "AWS Key Management Service": "aws_kms_key",
    "AWS Secrets Manager": "aws_secretsmanager_secret",
    "Elastic Load Balancing": "aws_elbv2_load_balancer",
    "Amazon CloudWatch": "aws_cloudwatch_log_group",
    "Amazon SNS": "aws_sns_topic",
    "Amazon SQS": "aws_sqs_queue",
    "AWS CloudFormation": "aws_cloudformation_stack",
    "AWS Identity and Access Management": "aws_iam_role",
}

# Filter services we can query
queried_services = []
for _, row in cost_df.iterrows():
    service = row["service"]
    region = row["region"]
    if service not in service_table_map:
        continue

    table = service_table_map[service]
    sql = f"select * from {table} where region = '{region}' limit 1000;"  # safety limit

    out_file = f"{table.replace('aws_', '')}_{region}.csv"
    print(f"Querying {service} ({table}) in {region}...")

    result = subprocess.run(
        ["steampipe", "query", "--output=csv"],
        input=sql,
        text=True,
        capture_output=True
    )

    if result.returncode == 0:
        Path(out_file).write_text(result.stdout)
        queried_services.append((service, table, region))
    else:
        print(f"Failed to query {table} in {region}: {result.stderr}")

# === Step 3: Final Summary (optional enhancement can be added here) ===
print("✅ All done. Queried services:")
for s, t, r in queried_services:
    print(f"  - {s} ({t}) in {r}")
