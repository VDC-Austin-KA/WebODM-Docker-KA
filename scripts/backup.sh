#!/bin/bash
# WebODM Database and Media Backup Script
# Usage: ./scripts/backup.sh
# Creates timestamped backups in ./backups/ directory

set -e  # Exit on any error
set -o pipefail  # Catch pipe failures

# Get script directory for proper path resolution
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( dirname "$SCRIPT_DIR" )"

BACKUP_DIR="$PROJECT_DIR/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DB_BACKUP="$BACKUP_DIR/db_backup_$TIMESTAMP.sql"
MEDIA_BACKUP="$BACKUP_DIR/media_backup_$TIMESTAMP.tar.gz"

# Validate backup directory
echo "Creating backup directory..."
if ! mkdir -p "$BACKUP_DIR" 2>/dev/null; then
    echo "✗ ERROR: Cannot create backup directory at $BACKUP_DIR"
    echo "Check permissions and disk space"
    exit 1
fi

# Validate required directories exist
if [ ! -d "$PROJECT_DIR/data/media" ]; then
    echo "✗ ERROR: Media directory not found at $PROJECT_DIR/data/media"
    exit 1
fi

echo "Starting WebODM backup..."
echo "Backup location: $BACKUP_DIR"

# Backup database
echo ""
echo "Backing up PostgreSQL database..."
if ! docker-compose -f "$PROJECT_DIR/docker-compose.yml" exec -T db pg_dump -U webodm webodm > "$DB_BACKUP" 2>/dev/null; then
    echo "✗ ERROR: Database backup failed"
    rm -f "$DB_BACKUP"
    exit 1
fi

# Secure database backup (contains credentials/data)
chmod 600 "$DB_BACKUP"
DB_SIZE=$(du -h "$DB_BACKUP" | cut -f1)
echo "✓ Database backup: $DB_BACKUP ($DB_SIZE)"

# Backup media files
echo ""
echo "Backing up media files..."
if ! tar -czf "$MEDIA_BACKUP" -C "$PROJECT_DIR" data/media 2>/dev/null; then
    echo "✗ ERROR: Media backup failed"
    rm -f "$MEDIA_BACKUP"
    exit 1
fi

MEDIA_SIZE=$(du -h "$MEDIA_BACKUP" | cut -f1)
echo "✓ Media backup: $MEDIA_BACKUP ($MEDIA_SIZE)"

echo ""
echo "✅ Backup completed successfully!"
echo "Total backups in $BACKUP_DIR: $(find "$BACKUP_DIR" -type f | wc -l) files"
exit 0
