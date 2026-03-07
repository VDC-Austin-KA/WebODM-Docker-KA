#!/bin/bash
# WebODM Database and Media Backup Script

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DB_BACKUP="$BACKUP_DIR/db_backup_$TIMESTAMP.sql"
MEDIA_BACKUP="$BACKUP_DIR/media_backup_$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "Starting WebODM backup..."

# Backup database
echo "Backing up database..."
docker-compose exec -T db pg_dump -U webodm webodm > "$DB_BACKUP"
echo "Database backup: $DB_BACKUP"

# Backup media files
echo "Backing up media files..."
tar -czf "$MEDIA_BACKUP" ./data/media
echo "Media backup: $MEDIA_BACKUP"

echo "Backup completed successfully!"
