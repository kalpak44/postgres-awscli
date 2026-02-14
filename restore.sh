#!/bin/sh
set -eu

log() { printf '%s %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$*"; }
die() { log "ERROR: $*"; exit 1; }

cleanup() {
  [ -n "${TMP_FILE-}" ] && [ -f "${TMP_FILE}" ] && rm -f "${TMP_FILE}" || true
}
trap cleanup EXIT INT TERM HUP

require_var() {
  var_name="$1"
  eval "var_val=\${$var_name-}"
  [ -n "${var_val}" ] || die "Missing required environment variable: ${var_name}"
}

# ---- Validate required variables (do NOT rename vars) ----
required_vars="PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD S3_BUCKET AWS_DEFAULT_REGION RESTORE_S3_KEY"
for var in $required_vars; do
  require_var "$var"
done

# Optional vars:
#   RECREATE_DB (default false) - if "true", drop & recreate PGDATABASE before restore
#   ADMIN_DB    (default postgres) - DB to connect to for drop/create
RECREATE_DB="${RECREATE_DB-false}"
ADMIN_DB="${ADMIN_DB-postgres}"

S3_PATH="s3://${S3_BUCKET}/${RESTORE_S3_KEY}"
TMP_FILE="/tmp/restore_${PGDATABASE}_$(date -u +"%Y%m%dT%H%M%SZ").sql.gz"

log "Downloading backup from ${S3_PATH}"
aws s3 cp "${S3_PATH}" "${TMP_FILE}" --only-show-errors
[ -s "${TMP_FILE}" ] || die "Downloaded file is empty: ${TMP_FILE}"

if [ "${RECREATE_DB}" = "true" ]; then
  log "Dropping and recreating database ${PGDATABASE} (connecting to ${ADMIN_DB})"

  # NOTE: This is safe if the DB does not exist; it only revokes/terminates/drops if found.
  PGPASSWORD="${PGPASSWORD}" psql \
    -h "${PGHOST}" \
    -p "${PGPORT}" \
    -U "${PGUSER}" \
    -d "${ADMIN_DB}" \
    -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_database WHERE datname = '${PGDATABASE}') THEN
    EXECUTE format('REVOKE CONNECT ON DATABASE %I FROM PUBLIC', '${PGDATABASE}');
    PERFORM pg_terminate_backend(pid)
    FROM pg_stat_activity
    WHERE datname = '${PGDATABASE}' AND pid <> pg_backend_pid();
    EXECUTE format('DROP DATABASE %I', '${PGDATABASE}');
  END IF;

  EXECUTE format('CREATE DATABASE %I', '${PGDATABASE}');
END
\$\$;
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
exit 0
