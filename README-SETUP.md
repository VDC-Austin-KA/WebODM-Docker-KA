# WebODM Server Setup Documentation

## Overview
This document describes the complete setup of a WebODM server using Docker Compose.

## Prerequisites
- Docker (version 20.x or higher)
- Docker Compose (version 2.x or higher)
- 8GB+ RAM recommended
- 50GB+ disk space for processing results

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

## Services

- **PostgreSQL (db)**: Database for storing project metadata
- **Redis (broker)**: Message queue for async tasks
- **Web App (webapp)**: Django application on port 8000
- **Celery Worker (worker)**: Background task processor

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

## Troubleshooting

### Services won't start
Check logs: `docker-compose logs`

### Database connection errors
Verify db service is healthy: `docker-compose ps`

### Port already in use
Change WO_PORT in .env file to different port

## For Production Deployment
- Change WO_SECRET_KEY to a strong random value
- Set WO_DEBUG=0
- Use external database server
- Configure SSL/TLS certificates
- Set up proper monitoring and alerting
