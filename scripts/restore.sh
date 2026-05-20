#!/bin/bash
set -uo pipefail

<< readme
MySQL restore script for SkillPulse
Restores the skillpulse database into the k3s MySQL pod from a backup file
Usage: ./restore.sh <backup_file>
readme

BACKUP_FILE="${1:-}"
NAMESPACE="skillpulse"

validate_args() {
    if [ -z "$BACKUP_FILE" ]; then
        echo "Usage: $0 <backup_file>"
        echo "Example: $0 /home/ubuntu/backups/skillpulse-db-2026-05-20_120000.sql.gz"
        exit 1
    fi

    if [ ! -f "$BACKUP_FILE" ]; then
        echo "Error: Backup file '$BACKUP_FILE' not found"
        exit 1
    fi
}

check_mysql_pod() {
    MYSQL_POD=$(kubectl get pod -n "$NAMESPACE" -l app=mysql -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
    if [ -z "$MYSQL_POD" ]; then
        echo "Error: MySQL pod not found in namespace $NAMESPACE"
        exit 1
    fi
    echo "Found MySQL pod: $MYSQL_POD"
}

restore_backup() {
    echo "Starting restore..."
    echo "File: $BACKUP_FILE"
    echo "Pod: $MYSQL_POD"
    echo "-----------------------------------"

    gunzip -c "$BACKUP_FILE" | kubectl exec -i -n "$NAMESPACE" "$MYSQL_POD" -- \
        mysql -u root -ppassword skillpulse

    if [ $? -ne 0 ]; then
        echo "Error: Restore failed"
        exit 1
    fi

    echo "-----------------------------------"
    echo "Restore completed successfully"
    echo "Database: skillpulse"
    echo "Source: $BACKUP_FILE"
    echo "-----------------------------------"
}

main() {
    validate_args
    check_mysql_pod
    restore_backup
}

main
