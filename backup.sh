#!/bin/sh

set -eu

# ---- helpers ----
log() { printf '%s %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$*"; }
die() { log "ERROR: $*"; exit 1; }

cleanup() {
  [ -n "${DUMP_FILE-}" ] && [ -f "${DUMP_FILE}" ] && rm -f "${DUMP_FILE}"
  [ -n "${LOCAL_FILE-}" ] && [ -f "${LOCAL_FILE}" ] && rm -f "${LOCAL_FILE}"
}
trap cleanup EXIT INT TERM HUP

require_var() {
  # POSIX-safe check that does not explode with `set -u`
  # (uses ${VAR-} to avoid "unset variable" errors)
  var_name="$1"
  eval "var_val=\${$var_name-}"
  if [ -z "${var_val}" ]; then
    die "Missing required environment variable: ${var_name}"
  fi
}

# ---- Validate required variables (do NOT rename vars) ----
required_vars="PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD S3_BUCKET S3_PREFIX AWS_DEFAULT_REGION"
for var in $required_vars; do
  require_var "$var"
done

# Optional hardening: ensure /tmp files are not world-readable
umask 077

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
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

# ---- Create dump (NO PIPELINE so failures are caught) ----
# If pg_dump fails, script stops here.
# Note: We keep --no-owner/--no-acl as you had them; dump still contains DATA unless you add --schema-only.
PGPASSWORD="${PGPASSWORD}" pg_dump \
  --host="${PGHOST}" \
  --port="${PGPORT}" \
  --username="${PGUSER}" \
  --dbname="${PGDATABASE}" \
  --no-owner \
  --no-acl \
  > "${DUMP_FILE}"

# Sanity check: dump must not be empty
if [ ! -s "${DUMP_FILE}" ]; then
  die "pg_dump produced an empty file. Check connectivity/credentials/permissions. Refusing to upload."
fi

# Compress
gzip -9 -c "${DUMP_FILE}" > "${LOCAL_FILE}"

# Sanity check: gzip output must not be empty
if [ ! -s "${LOCAL_FILE}" ]; then
  die "Compression produced an empty file. Refusing to upload."
fi

log "Uploading backup to S3..."

# Optional server-side encryption (SSE-S3). If you don't want it, remove this block.
S3_CP_EXTRA_ARGS=""
# You can keep this always-on; it doesn't require a new env var and is safe for most prod buckets.
S3_CP_EXTRA_ARGS="--sse AES256"

aws s3 cp "${LOCAL_FILE}" "${S3_PATH}" \
  --only-show-errors \
  ${S3_CP_EXTRA_ARGS}

log "Upload complete."

# Cleanup local artifacts (also handled by trap)
rm -f "${DUMP_FILE}" "${LOCAL_FILE}"
DUMP_FILE=""
LOCAL_FILE=""

log "Applying retention policy (keep last 10 backups)..."

# ---- Retention using s3api + LastModified sort (more reliable than parsing `aws s3 ls`) ----
# Get keys sorted newest-first by LastModified, then delete everything after the first 10.
# Note: This assumes your prefix contains only backup objects you want managed.
keys="$(aws s3api list-objects-v2 \
  --bucket "${S3_BUCKET}" \
  --prefix "${S3_PREFIX_CLEAN}/" \
  --query "reverse(sort_by(Contents, &LastModified))[].Key" \
  --output text)"

# If there are no objects, keys will be empty
if [ -n "${keys}" ]; then
  count=0
  # Iterate over whitespace-separated keys (backup filenames should not contain spaces)
  for key in ${keys}; do
    count=$((count + 1))
    if [ "${count}" -le 10 ]; then
      continue
    fi
    log "Deleting old backup: s3://${S3_BUCKET}/${key}"
    aws s3api delete-object --bucket "${S3_BUCKET}" --key "${key}" --only-show-errors
  done
else
  log "No existing backups found under prefix; skipping retention."
fi

log "Backup process completed successfully."
