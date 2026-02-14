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
#   RECREATE_DB (default false)
#   ADMIN_DB    (default postgres)
RECREATE_DB="${RECREATE_DB-false}"
ADMIN_DB="${ADMIN_DB-postgres}"

S3_PATH="s3://${S3_BUCKET}/${RESTORE_S3_KEY}"
TMP_FILE="/tmp/restore_${PGDATABASE}_$(date -u +"%Y%m%dT%H%M%SZ").sql.gz"

psql_admin() {
  PGPASSWORD="${PGPASSWORD}" psql \
    -h "${PGHOST}" \
    -p "${PGPORT}" \
    -U "${PGUSER}" \
    -d "${ADMIN_DB}" \
    -v ON_ERROR_STOP=1 \
    "$@"
}

psql_db() {
  PGPASSWORD="${PGPASSWORD}" psql \
    -h "${PGHOST}" \
    -p "${PGPORT}" \
    -U "${PGUSER}" \
    -d "${PGDATABASE}" \
    -v ON_ERROR_STOP=1 \
    "$@"
}

log "Downloading backup from ${S3_PATH}"
aws s3 cp "${S3_PATH}" "${TMP_FILE}" --only-show-errors
[ -s "${TMP_FILE}" ] || die "Downloaded file is empty: ${TMP_FILE}"

if [ "${RECREATE_DB}" = "true" ]; then
  log "Recreating database ${PGDATABASE} (connecting to ${ADMIN_DB})"

  # Check existence (returns "1" if exists, empty otherwise)
  exists="$(psql_admin -tAc "SELECT 1 FROM pg_database WHERE datname='${PGDATABASE}' LIMIT 1;" || true)"
  exists="$(printf '%s' "${exists}" | tr -d '[:space:]')"

  if [ "${exists}" = "1" ]; then
    log "Database exists; revoking connect, terminating sessions, dropping database"

    # REVOKE will fail if DB doesn't exist; we only run it when exists=1.
    psql_admin -c "REVOKE CONNECT ON DATABASE \"${PGDATABASE}\" FROM PUBLIC;"

    # Terminate active sessions to allow drop
    psql_admin -c "SELECT pg_terminate_backend(pid)
                   FROM pg_stat_activity
                   WHERE datname = '${PGDATABASE}'
                     AND pid <> pg_backend_pid();"

    # DROP/CREATE must be top-level statements (not in DO / not in a transaction block)
    psql_admin -c "DROP DATABASE \"${PGDATABASE}\";"
  else
    log "Database does not exist; will create it"
  fi

  log "Creating database ${PGDATABASE}"
  psql_admin -c "CREATE DATABASE \"${PGDATABASE}\";"
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
