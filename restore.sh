#!/bin/sh
set -eu

log() { printf '%s %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$*"; }
die() { log "ERROR: $*"; exit 1; }

require_var() {
  var_name="$1"
  eval "var_val=\${$var_name-}"
  [ -n "${var_val}" ] || die "Missing required environment variable: ${var_name}"
}

# Required vars
required_vars="PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD S3_BUCKET AWS_DEFAULT_REGION RESTORE_S3_KEY"
for var in $required_vars; do
  require_var "$var"
done

RECREATE_DB="${RECREATE_DB-false}"
ADMIN_DB="${ADMIN_DB-postgres}"

S3_PATH="s3://${S3_BUCKET}/${RESTORE_S3_KEY}"
TMP_FILE="/tmp/restore.sql.gz"

log "Downloading backup from ${S3_PATH}"
aws s3 cp "${S3_PATH}" "${TMP_FILE}" --only-show-errors

[ -s "${TMP_FILE}" ] || die "Downloaded file is empty"

if [ "$RECREATE_DB" = "true" ]; then
  log "Dropping and recreating database ${PGDATABASE}"

  PGPASSWORD="${PGPASSWORD}" psql \
    -h "${PGHOST}" \
    -p "${PGPORT}" \
    -U "${PGUSER}" \
    -d "${ADMIN_DB}" \
    -v ON_ERROR_STOP=1 <<SQL
REVOKE CONNECT ON DATABASE "${PGDATABASE}" FROM PUBLIC;
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '${PGDATABASE}' AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS "${PGDATABASE}";
CREATE DATABASE "${PGDATABASE}";
SQL
fi

log "Restoring into ${PGDATABASE}"
gunzip -c "${TMP_FILE}" | PGPASSWORD="${PGPASSWORD}" psql \
  -h "${PGHOST}" \
  -p "${PGPORT}" \
  -U "${PGUSER}" \
  -d "${PGDATABASE}" \
  -v ON_ERROR_STOP=1

log "Restore completed successfully"
