#!/bin/sh
set -eu

# ---- helpers ----
log() { printf '%s %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$*"; }
die() { log "ERROR: $*"; exit 1; }

cleanup() {
  [ -n "${DUMP_FILE-}" ] && [ -f "${DUMP_FILE}" ] && rm -f "${DUMP_FILE}" || true
  [ -n "${LOCAL_FILE-}" ] && [ -f "${LOCAL_FILE}" ] && rm -f "${LOCAL_FILE}" || true
}
trap cleanup EXIT INT TERM HUP

require_var() {
  var_name="$1"
  eval "var_val=\${$var_name-}"
  [ -n "${var_val}" ] || die "Missing required environment variable: ${var_name}"
}

# ---- Validate required variables (do NOT rename vars) ----
required_vars="PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD S3_BUCKET S3_PREFIX AWS_DEFAULT_REGION"
for var in $required_vars; do
  require_var "$var"
done

# Optional vars:
#   RETENTION_COUNT (default 10)
#   S3_SSE         (default AES256; set to "" to disable)
RETENTION_COUNT="${RETENTION_COUNT-10}"
S3_SSE="${S3_SSE-AES256}"

# Harden temp file perms
umask 077

TIMESTAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
FILENAME="${PGDATABASE}_${TIMESTAMP}.sql.gz"

# Normalize prefix (avoid double slashes)
S3_PREFIX_CLEAN="${S3_PREFIX%/}"
S3_KEY="${S3_PREFIX_CLEAN}/${FILENAME}"
S3_PATH="s3://${S3_BUCKET}/${S3_KEY}"

# Local paths
DUMP_FILE="$(mktemp "/tmp/${PGDATABASE}_${TIMESTAMP}.sql.XXXXXX")"
LOCAL_FILE="/tmp/${FILENAME}"

log "Starting PostgreSQL backup..."
log "Database: ${PGDATABASE}"
log "Host: ${PGHOST}:${PGPORT}"
log "Target: ${S3_PATH}"

# ---- Create dump (no pipeline so failures are caught) ----
PGPASSWORD="${PGPASSWORD}" pg_dump \
  --host="${PGHOST}" \
  --port="${PGPORT}" \
  --username="${PGUSER}" \
  --dbname="${PGDATABASE}" \
  --no-owner \
  --no-acl \
  > "${DUMP_FILE}"

# Sanity check: dump must not be empty
[ -s "${DUMP_FILE}" ] || die "pg_dump produced an empty file. Check connectivity/credentials/permissions."

# Compress
gzip -9 -c "${DUMP_FILE}" > "${LOCAL_FILE}"
[ -s "${LOCAL_FILE}" ] || die "Compression produced an empty file."

log "Uploading backup to S3..."

S3_CP_EXTRA_ARGS=""
if [ -n "${S3_SSE}" ]; then
  # SSE-S3; safe default for most buckets. Set S3_SSE="" to disable.
  S3_CP_EXTRA_ARGS="--sse ${S3_SSE}"
fi

# Note: --only-show-errors is valid for `aws s3 cp`
aws s3 cp "${LOCAL_FILE}" "${S3_PATH}" \
  --only-show-errors \
  ${S3_CP_EXTRA_ARGS}

log "Upload complete."

# Cleanup local artifacts (also handled by trap)
rm -f "${DUMP_FILE}" "${LOCAL_FILE}" || true
DUMP_FILE=""
LOCAL_FILE=""

log "Applying retention policy (keep last ${RETENTION_COUNT} backups)..."

# ---- Retention using s3api + LastModified sort ----
# Safe even if prefix is empty (Contents is null).
# NOTE: Don't use --only-show-errors with `aws s3api ...` (it is NOT supported there).
keys="$(aws s3api list-objects-v2 \
  --bucket "${S3_BUCKET}" \
  --prefix "${S3_PREFIX_CLEAN}/" \
  --query "reverse(sort_by(Contents || \`[]\`, &LastModified))[].Key" \
  --output text || true)"

if [ -n "${keys}" ]; then
  count=0
  for key in ${keys}; do
    count=$((count + 1))
    if [ "${count}" -le "${RETENTION_COUNT}" ]; then
      continue
    fi
    log "Deleting old backup: s3://${S3_BUCKET}/${key}"
    aws s3api delete-object --bucket "${S3_BUCKET}" --key "${key}"
  done
else
  log "No existing backups found under prefix; skipping retention."
fi

log "Backup process completed successfully."
exit 0
