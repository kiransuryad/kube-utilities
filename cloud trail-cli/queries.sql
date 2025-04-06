
-- EC2 Instances
select instance_id, instance_type, region, availability_zone, state ->> 'name' as status, launch_time
from aws_ec2_instance;

-- S3 Buckets
select name, region, versioning_status, has_public_access_block, encryption ->> 'rules' as encryption_rules
from aws_s3_bucket;

-- RDS Instances
select db_instance_identifier, db_instance_class, engine, allocated_storage, multi_az, region
from aws_rds_instance;

-- DynamoDB Tables
select name, region, table_status, table_size_bytes, item_count, read_capacity, write_capacity
from aws_dynamodb_table;

-- Lambda Functions
select name, region, runtime, memory_size, timeout, handler, last_modified
from aws_lambda_function;

-- IAM Roles
select name, path, max_session_duration, description
from aws_iam_role;

-- IAM Users
select user_name, arn, create_date, password_last_used
from aws_iam_user;

-- Secrets Manager Secrets
select name, region, kms_key_id, rotation_enabled, last_changed_date
from aws_secretsmanager_secret;

-- EBS Volumes
select volume_id, region, size, state, encrypted, attachments[0]->>'instance_id' as attached_to
from aws_ebs_volume;

-- ELBs
select name, region, scheme, type, dns_name, vpc_id
from aws_elbv2_load_balancer;

-- CloudWatch Log Groups
select name, region, retention_in_days, kms_key_id
from aws_cloudwatch_log_group;

-- KMS Keys
select key_id, key_state, key_usage, creation_date, description
from aws_kms_key;

-- VPCs
select vpc_id, cidr_block, is_default, region
from aws_vpc;

-- Subnets
select subnet_id, cidr_block, availability_zone, vpc_id
from aws_subnet;

-- SNS Topics
select name, region, display_name, kms_master_key_id
from aws_sns_topic;

-- SQS Queues
select name, region, fifo_queue, kms_master_key_id, visibility_timeout_seconds
from aws_sqs_queue;

-- CloudFormation Stacks
select name, stack_status, creation_time, last_updated_time, description
from aws_cloudformation_stack;

-- Monthly Cost per Service
select
  service,
  round(sum(unblended_cost), 2) as cost_usd
from
  aws_cost_by_service_monthly
where
  start_time >= date_trunc('month', current_date - interval '1 month')
group by
  service
order by
  cost_usd desc;
