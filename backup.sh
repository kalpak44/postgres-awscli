#!/bin/sh
set -eu

# ---- helpers ----
log() { printf '%s %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$*"; }
die() { log "ERROR: $*"; exit 1; }

cleanup() {
  [ -n "${DUMP_FILE-}" ] && [ -f "${DUMP_FILE}" ] && rm -f "${DUMP_FILE}" || true
  [ -n "${LOCAL_FILE-}" ] && [ -f "${LOCAL_FILE}" ] && rm -f "${LOCAL_FILE}" || true
  # Holds the S3 credentials, so it does not outlive the run.
  [ -n "${MC_CONFIG_DIR-}" ] && rm -rf "${MC_CONFIG_DIR}" || true
}
trap cleanup EXIT INT TERM HUP

require_var() {
  var_name="$1"
  eval "var_val=\${$var_name-}"
  [ -n "${var_val}" ] || die "Missing required environment variable: ${var_name}"
}

# ---- Validate required variables (do NOT rename vars) ----
required_vars="PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD S3_BUCKET S3_PREFIX AWS_DEFAULT_REGION AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY"
for var in $required_vars; do
  require_var "$var"
done

# Optional vars:
#   RETENTION_COUNT (default 10)
#   S3_SSE         (default AES256; set to "" to disable). A switch, not an
#                  algorithm name: the client takes no algorithm, and AES256 is
#                  the only value the old flag ever selected.
#   S3_ENDPOINT    (default https://s3.<AWS_DEFAULT_REGION>.amazonaws.com)
RETENTION_COUNT="${RETENTION_COUNT-10}"
S3_SSE="${S3_SSE-AES256}"

# Harden temp file perms
umask 077

# The object client keeps credentials in a config dir rather than in a host URL: an
# AWS secret key routinely contains / and +, which a URL cannot carry unencoded.
export MC_CONFIG_DIR="${MC_CONFIG_DIR-/tmp/.mc}"
S3_ENDPOINT="${S3_ENDPOINT-https://s3.${AWS_DEFAULT_REGION}.amazonaws.com}"

mcli alias set --quiet s3 "${S3_ENDPOINT}" "${AWS_ACCESS_KEY_ID}" "${AWS_SECRET_ACCESS_KEY}" >/dev/null \
  || die "Could not reach ${S3_ENDPOINT}. Check S3_ENDPOINT, AWS_DEFAULT_REGION and the credentials."

TIMESTAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
FILENAME="${PGDATABASE}_${TIMESTAMP}.sql.gz"

# Normalize prefix (avoid double slashes)
S3_PREFIX_CLEAN="${S3_PREFIX%/}"
S3_KEY="${S3_PREFIX_CLEAN}/${FILENAME}"
S3_PATH="s3://${S3_BUCKET}/${S3_KEY}"
S3_TARGET="s3/${S3_BUCKET}/${S3_PREFIX_CLEAN}/"

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
  # SSE-S3 with the bucket's own default key. A backend with no KMS configured
  # rejects this outright rather than storing the object unencrypted.
  S3_CP_EXTRA_ARGS="--enc-s3 s3/${S3_BUCKET}/${S3_PREFIX_CLEAN}"
fi

# The transfer summary goes to stdout even under --quiet; errors go to stderr and
# are left visible.
mcli cp --quiet ${S3_CP_EXTRA_ARGS} "${LOCAL_FILE}" "${S3_TARGET}" >/dev/null

log "Upload complete."

# Cleanup local artifacts (also handled by trap)
rm -f "${DUMP_FILE}" "${LOCAL_FILE}" || true
DUMP_FILE=""
LOCAL_FILE=""

log "Applying retention policy (keep last ${RETENTION_COUNT} backups)..."

# ---- Retention: newest first, keep RETENTION_COUNT, delete the rest ----
# An empty prefix lists nothing and exits 0, so this is safe on a first run.
# `.key` is the object's basename, not its full key, which is why the prefix is
# put back on before deleting.
keys="$(mcli ls --json "s3/${S3_BUCKET}/${S3_PREFIX_CLEAN}/" \
  | jq -r 'select(.type=="file") | [.lastModified, .key] | @tsv' \
  | sort -r | cut -f2 || true)"

if [ -n "${keys}" ]; then
  count=0
  for key in ${keys}; do
    count=$((count + 1))
    if [ "${count}" -le "${RETENTION_COUNT}" ]; then
      continue
    fi
    log "Deleting old backup: s3://${S3_BUCKET}/${S3_PREFIX_CLEAN}/${key}"
    mcli rm --quiet "s3/${S3_BUCKET}/${S3_PREFIX_CLEAN}/${key}" >/dev/null
  done
else
  log "No existing backups found under prefix; skipping retention."
fi

log "Backup process completed successfully."
exit 0
