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
