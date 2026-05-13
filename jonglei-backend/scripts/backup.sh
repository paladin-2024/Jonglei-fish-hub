#!/usr/bin/env bash
# Automated PostgreSQL backup — run via cron or docker exec
# Cron example (daily at 02:00): 0 2 * * * /app/scripts/backup.sh

set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/backups}"
DB_NAME="${DB_NAME:-jonglei_fish_hub}"
DB_USER="${DB_USER:-jonglei_admin}"
DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-5432}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql.gz"

PGPASSWORD="$DB_PASSWORD" pg_dump \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    "$DB_NAME" | gzip > "$FILE"

echo "[backup] Wrote $FILE ($(du -sh "$FILE" | cut -f1))"

# Prune backups older than RETENTION_DAYS
find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime +"$RETENTION_DAYS" -delete
echo "[backup] Pruned backups older than ${RETENTION_DAYS} days"
