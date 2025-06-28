# Keycloak Data Migration Guide

This guide provides step-by-step instructions for migrating Keycloak data between environments using PostgreSQL database dumps.

## Prerequisites

- Access to DBAdmin pods in both nonprod and prod environments
- kubectl CLI configured with appropriate permissions
- AWS CLI configured for S3 access
- OpenSSL for encryption/decryption
- PostgreSQL client tools (psql, pg_dump, pg_restore)

## Environment Details

### Non-Production Environment
- **Host**: `xplane-nonprod-rds-ethoskeycloak-use1.cj0pjq12qw6q.us-east-1.rds.amazonaws.com`
- **Port**: `5432`
- **Username**: `keycloakadmin`
- **Database**: `keycloak`

### Production Environment (Old EDA)
- **Host**: `xplane-prod-rds-ethoskeycloak-use1.cluster-c7lsridxtv.us-east-1.rds.amazonaws.com`
- **Port**: `5432`
- **Username**: `keycloak`
- **Database**: `keycloak`
- **Password**: `RvctV4JTpQaMCk8M76DS9ZjEYv3J3Xp`

## Migration Steps

### Step 1: Connect to Database

Connect to the appropriate PostgreSQL instance using psql:

**For Non-Production:**
```bash
psql -h xplane-nonprod-rds-ethoskeycloak-use1.cj0pjq12qw6q.us-east-1.rds.amazonaws.com \
     -p 5432 \
     -U keycloakadmin \
     -d keycloak
```

**For Production (Old EDA):**
```bash
psql -h xplane-prod-rds-ethoskeycloak-use1.cluster-c7lsridxtv.us-east-1.rds.amazonaws.com \
     -p 5432 \
     -U keycloak \
     -d keycloak
```

### Step 2: Create Database Dump

Generate a compressed database dump using pg_dump:

**For Non-Production:**
```bash
pg_dump -Fc -v \
    --host=xplane-nonprod-rds-ethoskeycloak-use1.cj0pjq12qw6q.us-east-1.rds.amazonaws.com \
    --port=5432 \
    --username=keycloakadmin \
    --dbname=keycloak \
    -f /tmp/keycloak-09-06-25.dump
```

**For Production:**
```bash
pg_dump -Fc -v \
    --host=xplane-prod-rds-ethoskeycloak-use1.cluster-c7lsridxtv.us-east-1.rds.amazonaws.com \
    --port=5432 \
    --username=keycloakadmin \
    --dbname=keycloak \
    -f /tmp/keycloak-eda-prod-18-06-25.dump
```

### Step 3: Compress the Dump File

Create a compressed tar archive of the database dump:

```bash
tar -czvf keycloak-eda-prod-18-06-25.dump.tar.gz keycloak-eda-prod-18-06-25.dump
```

### Step 4: Export from Kubernetes Pod

Copy the compressed dump file from the Kubernetes pod to your local machine:

**From Non-Production Pod:**
```bash
kubectl cp ethoskeycloak-dbadmin-7b57b7dc46-cws98:/tmp/keycloak-09-06-25.dump.tar.gz ./keycloak-ethos/
```

**From Production Pod:**
```bash
kubectl cp ethoskeycloak-dbadmin-86694477cf-lgf7q:/tmp/keycloak-eda-prod-18-06-25.dump.tar.gz ./keycloak-eda/
```

### Step 5: Encrypt the File

Encrypt the compressed dump file using OpenSSL AES-256 encryption:

```bash
openssl enc -aes-256-cbc -salt -pbkdf2 \
    -in keycloak-eda-prod-18-06-25.dump.tar.gz \
    -out keycloak-eda-prod-18-06-25.dump.tar.gz.enc \
    -pass pass:'EncryptedFuture@2025'
```

### Step 6: Upload to S3 Bucket

Upload the encrypted file to the S3 bastion artifacts bucket:

```bash
aws s3 cp ./keycloak-eda-prod-18-06-25.dump.tar.gz.enc \
    s3://prod-bastionartifacts-int-usel/keycloak-eda-prod-18-06-25.dump.tar.gz.enc
```

### Step 7: Transfer via Windows Bastion

From the Windows bastion machine, use SCP to transfer the file to the destination Unix server:

```bash
scp \Downloads\keycloak-09-06-25.dump.tar.gz.enc \
    ec2-user@<destination-host>:/home/<username>/
```

### Step 8: Decrypt and Extract

On the destination server, decrypt and extract the database dump:

**Decrypt the file:**
```bash
openssl enc -d -aes-256-cbc -pbkdf2 \
    -in keycloak-09-06-25.dump.tar.gz.enc \
    -out keycloak-09-06-25.dump.tar.gz \
    -pass pass:'EncryptedFuture@2025'
```

**Extract the tar archive:**
```bash
tar -xzvf keycloak-09-06-25.dump.tar.gz
```

### Step 9: Restore to PostgreSQL

Restore the database dump to the target PostgreSQL instance:

**Basic restore command:**
```bash
pg_restore \
    --host=xplane-rds-cluster-instance.cj0pjq12qw6q.us-east-1.rds.amazonaws.com \
    --port=5432 \
    --username=keycloakadmin \
    --dbname=keycloak \
    --clean \
    -f keycloak-09-06-25.dump
```

**Alternative restore method:**
```bash
pg_restore \
    --host=<prod-host> \
    --port=5432 \
    --username=keycloakadmin \
    --dbname=keycloak \
    -f /tmp/keycloak-eda-prod-18-06-25.dump
```

### Step 10: Full Keycloak Data Restore Example

Complete restore command with all options:

```bash
pg_restore \
    --host=prod-rds-pbkb7r7c.prod \
    -n full-keycloak \
    -d keycloak-eda-prod-18-06-25 \
    keycloak-eda-prod-18-06-25.dump.tar.gz.enc \
    --pass pass:'EncryptedFuture@2025'
```

## Security Notes

- **Encryption Password**: `EncryptedFuture@2025`
- Always encrypt sensitive database dumps before transfer
- Use secure channels (SCP, HTTPS) for file transfers
- Remove temporary files after successful migration
- Verify data integrity after restoration

## Troubleshooting

- Ensure proper network connectivity to RDS instances
- Verify database credentials and permissions
- Check available disk space before creating dumps
- Monitor restoration progress for large databases
- Test connectivity before starting the migration process

## Post-Migration Verification

After completing the restoration:

1. Verify database connectivity
2. Check data integrity and completeness
3. Test Keycloak functionality
4. Update any configuration files if necessary
5. Monitor logs for any errors or warnings