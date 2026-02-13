#!/bin/sh
set -eu

MODE="${MODE-backup}"

case "$MODE" in
  backup)
    exec /app/backup.sh
    ;;
  restore)
    exec /app/restore.sh
    ;;
  *)
    echo "Unknown MODE=$MODE (use backup or restore)"
    exit 1
    ;;
esac
