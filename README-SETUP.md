# WebODM Server Setup Documentation

## Overview
This document describes the complete setup of a WebODM server using Docker Compose.

## Prerequisites
- Docker (version 20.x or higher)
- Docker Compose (version 2.x or higher)
- 8GB+ RAM recommended
- 50GB+ disk space for processing results

## Verify Prerequisites

Before starting, verify that Docker and Docker Compose are properly installed:

```bash
docker --version      # Should be 20.x.x or higher
docker-compose --version  # Should be 2.x.x or higher
docker ps             # Verify Docker daemon is running
```

If any of these commands fail, install or fix Docker before proceeding.

## Quick Start

### 1. Initialize Environment
```bash
cd WebODM-OpenDroneMap
mkdir -p data/{db,media}
```

### 2. Start Services
```bash
docker-compose up -d
```

### 3. Create Admin User
```bash
docker-compose exec webapp python manage.py createsuperuser
```

### 4. Access Web Interface
Open http://localhost:8000 in your browser

## Verify Services Are Running

After starting services, wait 30-60 seconds for initialization, then verify:

```bash
# Check all services are healthy
docker-compose ps

# You should see:
# db       - Up (healthy)
# broker   - Up (healthy)
# webapp   - Up (healthy)
# worker   - Up (healthy)

# Or use the health check script
./scripts/health-check.sh
```

Expected output shows all services with "Up" status. If any show "restarting" or "exited", check logs:
```bash
docker-compose logs webapp
```

## Services

WebODM uses a multi-container architecture:

- **PostgreSQL (db)**: Relational database for storing project metadata, user accounts, and processing results
- **Redis (broker)**: In-memory message broker that queues asynchronous tasks for the worker
- **Web App (webapp)**: Django REST API and web interface on port 8000 - this is what you access in the browser
- **Celery Worker (worker)**: Processes drone images asynchronously based on tasks from the Redis broker

These services work together to allow you to upload images via the web interface and process them in the background without blocking the UI.

## Useful Commands

### View Logs
```bash
docker-compose logs -f webapp
docker-compose logs -f worker
```

### Execute Commands in Container
```bash
docker-compose exec webapp python manage.py migrate
docker-compose exec webapp python manage.py shell
```

### Stop Services
```bash
docker-compose down
```

### Health Check
```bash
./scripts/health-check.sh
```

## Backup and Restore

### Create Backup
```bash
./scripts/backup.sh
```

Backups are created in the `./backups/` directory with timestamps:
- Database: `db_backup_YYYYMMDD_HHMMSS.sql`
- Media: `media_backup_YYYYMMDD_HHMMSS.tar.gz`

### Restore from Backup

#### Restore Database
```bash
# Copy backup file to project directory
docker-compose exec -T db psql -U webodm webodm < backups/db_backup_YYYYMMDD_HHMMSS.sql
```

#### Restore Media Files
```bash
# Extract media backup (ensure data/media is empty first)
rm -rf data/media/*
tar -xzf backups/media_backup_YYYYMMDD_HHMMSS.tar.gz
```

## Troubleshooting

### Services won't start
Check logs: `docker-compose logs`

### Database connection errors
Verify db service is healthy: `docker-compose ps`

### Port already in use
Change WO_PORT in .env file to different port

### Services take too long to start
First startup may take 2-3 minutes as database initializes. Check logs: `docker-compose logs db`

### Permission denied errors
Ensure Docker daemon is running: `docker ps`
On Linux, add your user to docker group or use sudo

### Port 8000 shows connection refused
Services may still be starting. Wait 30-60 seconds and try again.
Check with: `docker-compose ps` to see if webapp is up

### Database migration errors
If you see database migration errors, run:
```bash
docker-compose exec webapp python manage.py migrate
```

### Memory or CPU limits reached
Adjust resource limits in docker-compose.yml if your system has different specs

## For Production Deployment
- Change WO_SECRET_KEY to a strong random value
- Set WO_DEBUG=0
- Use external database server
- Configure SSL/TLS certificates
- Set up proper monitoring and alerting
