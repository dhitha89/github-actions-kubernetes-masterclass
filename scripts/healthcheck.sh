#!/bin/bash
set -uo pipefail

<< readme
Healthcheck script for SkillPulse
Checks app endpoints and reports status
Usage: ./healthcheck.sh <app_url>
Example: ./healthcheck.sh http://18.209.241.158:30080
readme

APP_URL="${1:-http://localhost:30080}"
FAILED=0

check_endpoint() {
    local NAME="$1"
    local URL="$2"
    local EXPECTED="$3"

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$URL")

    if [ "$HTTP_CODE" -eq "$EXPECTED" ]; then
        echo "[OK]   $NAME → $URL (HTTP $HTTP_CODE)"
    else
        echo "[FAIL] $NAME → $URL (Expected $EXPECTED, got $HTTP_CODE)"
        FAILED=1
    fi
}

main() {
    echo "=========================================="
    echo "SkillPulse Healthcheck"
    echo "Target: $APP_URL"
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=========================================="

    check_endpoint "Frontend"       "$APP_URL"          200
    check_endpoint "Health API"     "$APP_URL/health"   200
    check_endpoint "Skills API"     "$APP_URL/api/skills" 200
    check_endpoint "Dashboard API"  "$APP_URL/api/dashboard" 200

    echo "=========================================="
    if [ $FAILED -eq 0 ]; then
        echo "All checks passed"
    else
        echo "One or more checks failed"
        exit 1
    fi
    echo "=========================================="
}

main
