#!/bin/bash
# WebODM Health Check Script
# Usage: ./scripts/health-check.sh
# Returns: 0 if all services healthy, 1 if any service failed

set -o pipefail
FAILURES=0

echo "=== WebODM System Health Check ==="
echo ""

# Check containers
echo "Container Status:"
if ! docker-compose ps; then
    echo "✗ FAILED: docker-compose command failed"
    FAILURES=$((FAILURES + 1))
fi

echo ""
echo "Service Health:"

# Check database
echo -n "PostgreSQL: "
if docker-compose exec -T db pg_isready -U webodm > /dev/null 2>&1; then
    echo "✓ OK"
else
    echo "✗ FAILED"
    FAILURES=$((FAILURES + 1))
fi

# Check Redis
echo -n "Redis Broker: "
if docker-compose exec -T broker redis-cli ping > /dev/null 2>&1; then
    echo "✓ OK"
else
    echo "✗ FAILED"
    FAILURES=$((FAILURES + 1))
fi

# Check Web App
echo -n "Web Application: "
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000)
if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
    echo "✓ OK (HTTP $HTTP_STATUS)"
else
    echo "✗ FAILED (HTTP $HTTP_STATUS)"
    FAILURES=$((FAILURES + 1))
fi

# Check logs for errors
echo ""
echo "Recent Errors:"
if docker-compose logs --tail=50 2>/dev/null | grep -qi error; then
    echo "⚠ WARNING: Errors found in logs - check with: docker-compose logs"
    FAILURES=$((FAILURES + 1))
else
    echo "✓ No recent errors found"
fi

# Return appropriate exit code
echo ""
if [ $FAILURES -eq 0 ]; then
    echo "✅ All services healthy!"
    exit 0
else
    echo "❌ $FAILURES service(s) failed health check"
    exit 1
fi
