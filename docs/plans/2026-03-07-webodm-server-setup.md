# WebODM Server Setup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Set up a fully functional WebODM server that processes drone imagery using Docker Compose with database, web application, Redis broker, and worker services.

**Architecture:** WebODM uses a multi-container Docker architecture consisting of: PostgreSQL database (data persistence), Redis broker (async task queue), Web application (Django app on port 8000), and Celery worker (background task processing). The setup requires Docker and Docker Compose to orchestrate all services.

**Tech Stack:** 
- Docker & Docker Compose
- PostgreSQL (database)
- Redis (message broker)
- Django/Python (webapp)
- Celery (task queue)
- OpenDroneMap processing engine

---

## Task 1: Verify Prerequisites and Create Project Structure

**Files:**
- Create: `.env` (environment configuration)
- Create: `docker-compose.yml` (service orchestration - will be copied from repo)
- Create: `.gitignore` (ignore generated files)

**Step 1: Verify Docker and Docker Compose installation**

Run: `docker --version && docker-compose --version`

Expected output:
```
Docker version 20.x.x or higher
Docker Compose version 2.x.x or higher
```

**Step 2: Create project directories for data persistence**

Run: `mkdir -p ./data/db ./data/media`

Expected: Two directories created for PostgreSQL data and media uploads

**Step 3: Create .env file with required environment variables**

File: `.env`

```
# WebODM Configuration
WO_PORT=8000
WO_HOST=0.0.0.0
WO_DEBUG=0
WO_BROKER=redis://broker:6379
WO_DEV=0
WO_DEV_WATCH_PLUGINS=0
WO_SECRET_KEY=your-secret-key-change-this-in-production
WEB_CONCURRENCY=4

# Data directories
WO_DB_DIR=./data/db
WO_MEDIA_DIR=./data/media
```

**Step 4: Create .gitignore to ignore sensitive files and data**

File: `.gitignore`

```
# Environment variables
.env
.env.local
.env.*.local

# Data directories
data/db/*
data/media/*

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Docker
docker-compose.override.yml
```

**Step 5: Commit initial setup**

```bash
git add .env .gitignore docs/plans/
git commit -m "docs: add WebODM server setup plan with environment configuration"
```

---

## Task 2: Create Docker Compose Configuration

**Files:**
- Create: `docker-compose.yml` (main orchestration file)

**Step 1: Create docker-compose.yml with all services**

File: `docker-compose.yml`

```yaml
# WebODM Docker Compose Configuration
# This configuration includes: PostgreSQL DB, Redis Broker, Web App, and Celery Worker

version: '3.8'

services:
  # PostgreSQL Database
  db:
    image: opendronemap/webodm_db:latest
    container_name: webodm_db
    environment:
      POSTGRES_DB: webodm
      POSTGRES_USER: webodm
      POSTGRES_PASSWORD: webodm_password
    volumes:
      - ${WO_DB_DIR}:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U webodm"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Message Broker
  broker:
    image: redis:7.0.10-alpine
    container_name: webodm_broker
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # WebODM Web Application
  webapp:
    image: opendronemap/webodm_webapp:latest
    container_name: webodm_webapp
    depends_on:
      db:
        condition: service_healthy
      broker:
        condition: service_healthy
    volumes:
      - ${WO_MEDIA_DIR}:/webodm/app/media
    ports:
      - "${WO_PORT}:8000"
    environment:
      - DATABASE_URL=postgresql://webodm:webodm_password@db:5432/webodm
      - CELERY_BROKER_URL=${WO_BROKER}
      - CELERY_RESULT_BACKEND=${WO_BROKER}
      - WO_DEBUG=${WO_DEBUG}
      - WO_SECRET_KEY=${WO_SECRET_KEY}
      - WEB_CONCURRENCY=${WEB_CONCURRENCY}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Celery Worker for Background Tasks
  worker:
    image: opendronemap/webodm_webapp:latest
    container_name: webodm_worker
    command: celery -A webodm worker --loglevel=info
    depends_on:
      db:
        condition: service_healthy
      broker:
        condition: service_healthy
    volumes:
      - ${WO_MEDIA_DIR}:/webodm/app/media
    environment:
      - DATABASE_URL=postgresql://webodm:webodm_password@db:5432/webodm
      - CELERY_BROKER_URL=${WO_BROKER}
      - CELERY_RESULT_BACKEND=${WO_BROKER}
      - WO_DEBUG=${WO_DEBUG}
      - WO_SECRET_KEY=${WO_SECRET_KEY}
    restart: unless-stopped

volumes:
  db_data:
  media_data:
```

**Step 2: Validate docker-compose.yml syntax**

Run: `docker-compose config`

Expected: Output showing the composed configuration without errors

**Step 3: Commit Docker configuration**

```bash
git add docker-compose.yml
git commit -m "feat: add Docker Compose configuration for WebODM server stack"
```

---

## Task 3: Initialize Database and Services

**Files:**
- Modify: `docker-compose.yml` (already created)

**Step 1: Pull all required Docker images**

Run: `docker-compose pull`

Expected: All images downloaded successfully (opendronemap/webodm_db, opendronemap/webodm_webapp, redis)

**Step 2: Start all services**

Run: `docker-compose up -d`

Expected: All containers starting and reaching healthy state

**Step 3: Verify all containers are running**

Run: `docker-compose ps`

Expected output should show:
```
NAME                    STATUS
webodm_db              Up (healthy)
webodm_broker          Up (healthy)
webodm_webapp          Up (healthy)
webodm_worker          Up (healthy)
```

**Step 4: Check database initialization logs**

Run: `docker-compose logs db | grep -i "ready\|created"`

Expected: Database initialization messages indicating success

**Step 5: Verify webapp is accessible**

Run: `curl -s http://localhost:8000 | head -20`

Expected: HTML content from the WebODM web interface (or HTTP 200 status)

**Step 6: Check worker status**

Run: `docker-compose logs worker | grep -i "ready\|started"`

Expected: Worker process logs showing it's connected to broker and ready

---

## Task 4: Create Initial User and Configuration

**Files:**
- Create: `scripts/init-admin.sh` (user initialization script)

**Step 1: Create admin user for WebODM**

Run: `docker-compose exec webapp python manage.py createsuperuser --username admin --email admin@example.com`

Expected: User creation prompt asking for password

**Step 2: Set admin password (non-interactive)**

Run: `docker-compose exec webapp bash -c "python manage.py shell <<EOF
from django.contrib.auth import get_user_model
User = get_user_model()
user = User.objects.get(username='admin')
user.set_password('your-secure-password')
user.save()
print('Admin user created successfully')
EOF"`

Expected: Confirmation message

**Step 3: Verify admin user created**

Run: `docker-compose exec db psql -U webodm -d webodm -c "SELECT id, username, email FROM auth_user WHERE username='admin';"`

Expected: Admin user row showing in database

---

## Task 5: Configure System Services and Monitoring

**Files:**
- Create: `scripts/health-check.sh` (monitoring script)
- Create: `scripts/backup.sh` (backup script)

**Step 1: Create health check script**

File: `scripts/health-check.sh`

```bash
#!/bin/bash
# WebODM Health Check Script

echo "=== WebODM System Health Check ==="
echo ""

# Check containers
echo "Container Status:"
docker-compose ps

echo ""
echo "Service Health:"

# Check database
echo -n "PostgreSQL: "
docker-compose exec -T db pg_isready -U webodm && echo "✓ OK" || echo "✗ FAILED"

# Check Redis
echo -n "Redis Broker: "
docker-compose exec -T broker redis-cli ping && echo "✓ OK" || echo "✗ FAILED"

# Check Web App
echo -n "Web Application: "
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 && echo " ✓ OK" || echo " ✗ FAILED"

# Check logs for errors
echo ""
echo "Recent Errors:"
docker-compose logs --tail=50 | grep -i error || echo "No recent errors found"
```

**Step 2: Make health check script executable**

Run: `chmod +x scripts/health-check.sh`

Expected: Script permissions updated

**Step 3: Run health check**

Run: `./scripts/health-check.sh`

Expected: All services showing healthy status with ✓ marks

**Step 4: Create backup script**

File: `scripts/backup.sh`

```bash
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
```

**Step 5: Make backup script executable**

Run: `chmod +x scripts/backup.sh`

Expected: Script permissions updated

**Step 6: Test backup script**

Run: `./scripts/backup.sh`

Expected: Backup files created in `./backups/` directory

---

## Task 6: Verify Complete Setup and Documentation

**Files:**
- Create: `README-SETUP.md` (setup documentation)

**Step 1: Document complete setup process**

File: `README-SETUP.md`

```markdown
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
\`\`\`bash
cd WebODM-OpenDroneMap
mkdir -p data/{db,media}
\`\`\`

### 2. Start Services
\`\`\`bash
docker-compose up -d
\`\`\`

### 3. Create Admin User
\`\`\`bash
docker-compose exec webapp python manage.py createsuperuser
\`\`\`

### 4. Access Web Interface
Open http://localhost:8000 in your browser

## Services

- **PostgreSQL (db)**: Database for storing project metadata
- **Redis (broker)**: Message queue for async tasks
- **Web App (webapp)**: Django application on port 8000
- **Celery Worker (worker)**: Background task processor

## Useful Commands

### View Logs
\`\`\`bash
docker-compose logs -f webapp
docker-compose logs -f worker
\`\`\`

### Execute Commands in Container
\`\`\`bash
docker-compose exec webapp python manage.py migrate
docker-compose exec webapp python manage.py shell
\`\`\`

### Stop Services
\`\`\`bash
docker-compose down
\`\`\`

### Health Check
\`\`\`bash
./scripts/health-check.sh
\`\`\`

## Backup and Restore

### Create Backup
\`\`\`bash
./scripts/backup.sh
\`\`\`

## Troubleshooting

### Services won't start
Check logs: \`docker-compose logs\`

### Database connection errors
Verify db service is healthy: \`docker-compose ps\`

### Port already in use
Change WO_PORT in .env file to different port

## For Production Deployment
- Change WO_SECRET_KEY to a strong random value
- Set WO_DEBUG=0
- Use external database server
- Configure SSL/TLS certificates
- Set up proper monitoring and alerting
```

**Step 2: Run comprehensive test**

Run: `docker-compose ps && docker-compose logs --tail=20`

Expected: All containers running and recent logs showing normal operation

**Step 3: Create test project upload (if possible)**

Run: `curl -s http://localhost:8000/admin/ | grep -q "Welcome to Django" && echo "✓ Admin interface accessible"`

Expected: Confirmation that admin interface is accessible

**Step 4: Final commit**

```bash
git add scripts/ README-SETUP.md
git commit -m "feat: add health check, backup scripts and setup documentation"
```

**Step 5: Create summary report**

Run: `cat > SETUP-SUMMARY.txt << 'EOF'
WebODM Server Setup - Complete
===============================

Services Running:
- PostgreSQL Database on :5432
- Redis Broker on :6379  
- Web Application on :8000
- Celery Worker (background tasks)

Admin Access:
- URL: http://localhost:8000/admin/
- Username: admin
- Password: (as set during initialization)

Data Locations:
- Database: ./data/db/
- Media/Projects: ./data/media/

Next Steps:
1. Upload drone images via web interface
2. Create new project and select processing engine
3. Monitor processing progress in worker logs
4. Download results when complete

Useful Commands:
- View logs: docker-compose logs -f
- Health check: ./scripts/health-check.sh
- Backup data: ./scripts/backup.sh
- Restart services: docker-compose restart

EOF
cat SETUP-SUMMARY.txt`

Expected: Summary report displayed and saved

---

## Execution Notes

- **Docker Images**: All images are pulled from Docker Hub (opendronemap organization)
- **Data Persistence**: Database and media files are stored in `./data/` volume mounts
- **Networking**: All containers communicate through Docker's internal network
- **Healthchecks**: Built-in healthchecks ensure services are ready before dependent services start
- **Environment Variables**: All configuration is in `.env` file for easy customization

## Post-Setup Configuration

After completing these tasks:
1. Access web interface at http://localhost:8000
2. Create projects and upload drone images
3. Configure processing parameters
4. Monitor task progress in worker logs
5. Download georeferenced results

