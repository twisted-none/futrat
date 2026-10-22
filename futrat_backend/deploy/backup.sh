#!/usr/bin/env bash
# Back up only Futrat, using the existing PostgreSQL container's local admin.
set -euo pipefail
umask 077

backup_dir="${1:-./backups}"
container="${FUTRAT_POSTGRES_CONTAINER:-postgresql}"
admin="${FUTRAT_POSTGRES_ADMIN:-postgres}"
mkdir -p -- "$backup_dir"
temporary="$(mktemp "$backup_dir/.futrat-backup.XXXXXX")"
trap 'rm -f -- "$temporary"' EXIT

docker exec "$container" pg_dump -U "$admin" --dbname=futrat \
    --format=custom --no-owner --no-acl > "$temporary"
test -s "$temporary"
destination="$backup_dir/futrat-$(date -u +%Y%m%dT%H%M%SZ)-$$.dump"
mv -- "$temporary" "$destination"
trap - EXIT
printf 'Futrat backup saved: %s\n' "$destination"
