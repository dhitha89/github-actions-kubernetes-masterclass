#!/bin/bash
set -uo pipefail

<< readme
Daily maintenance script for SkillPulse
Runs backup and healthcheck, logs everything
Usage: ./maintenance.sh
readme

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/home/ubuntu/logs/maintenance.log"
BACKUP_DIR="/home/ubuntu/backups"
APP_URL="http://localhost:30080"

BACKUP_SUCCESS=0
HEALTH_SUCCESS=0
FAILED=0

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a "$LOG_FILE"
}

setup_log_dir() {
    mkdir -p "$(dirname "$LOG_FILE")"
}

run_backup() {
    log_msg "Running database backup..."
    "$SCRIPT_DIR/backup.sh" "$BACKUP_DIR" >> "$LOG_FILE" 2>&1 && BACKUP_SUCCESS=1 || FAILED=1
}

run_healthcheck() {
    log_msg "Running healthcheck..."
    "$SCRIPT_DIR/healthcheck.sh" "$APP_URL" >> "$LOG_FILE" 2>&1 && HEALTH_SUCCESS=1 || FAILED=1
}

main() {
    setup_log_dir

    log_msg "=========================================="
    log_msg "Starting SkillPulse maintenance"
    log_msg "=========================================="

    run_backup
    run_healthcheck

    log_msg "=========================================="
    log_msg "Backup:      $([ $BACKUP_SUCCESS -eq 1 ] && echo 'OK' || echo 'FAILED')"
    log_msg "Healthcheck: $([ $HEALTH_SUCCESS -eq 1 ] && echo 'OK' || echo 'FAILED')"
    log_msg "=========================================="
    log_msg "Maintenance completed"

    [ $FAILED -eq 1 ] && exit 1
    exit 0
}

main
