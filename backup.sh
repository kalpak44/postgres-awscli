#!/bin/sh

set -eu

# Validate required variables
required_vars="PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD S3_BUCKET S3_PREFIX AWS_DEFAULT_REGION"
for var in $required_vars; do
  if [ -z "$(eval echo \$$var)" ]; then
    echo "Missing required environment variable: $var"
    exit 1
  fi
done

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
FILENAME="${PGDATABASE}_${TIMESTAMP}.sql.gz"
LOCAL_FILE="/tmp/${FILENAME}"
S3_PATH="s3://${S3_BUCKET}/${S3_PREFIX}/${FILENAME}"

echo "Starting PostgreSQL backup..."
echo "Database: ${PGDATABASE}"
echo "Host: ${PGHOST}"

# Create dump and compress
PGPASSWORD="${PGPASSWORD}" pg_dump \
  --host="${PGHOST}" \
  --port="${PGPORT}" \
  --username="${PGUSER}" \
  --dbname="${PGDATABASE}" \
  --no-owner \
  --no-acl \
  | gzip -9 > "${LOCAL_FILE}"

echo "Uploading backup to S3..."
aws s3 cp "${LOCAL_FILE}" "${S3_PATH}"

echo "Upload complete."

# Cleanup local file
rm -f "${LOCAL_FILE}"

echo "Applying retention policy (keep last 10 backups)..."

# List backups, sort, remove all except newest 10
aws s3 ls "s3://${S3_BUCKET}/${S3_PREFIX}/" \
  | awk '{print $4}' \
  | sort \
  | head -n -10 \
  | while read old_file; do
      if [ -n "$old_file" ]; then
        echo "Deleting old backup: $old_file"
        aws s3 rm "s3://${S3_BUCKET}/${S3_PREFIX}/${old_file}"
      fi
    done

echo "Backup process completed successfully."
