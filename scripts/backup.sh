#!/bin/bash
set -uo pipefail

<< readme
MySQL backup script for SkillPulse
Dumps the skillpulse database from the k3s MySQL pod
Cleans backups older than 14 days automatically
Usage: ./backup.sh <backup_directory>
readme

BACKUP_DIR="${1:-/home/ubuntu/backups}"
NAMESPACE="skillpulse"
BACKUP_NAME=""
BACKUP_SIZE=""
DELETED=0

validate_args() {
    if [ -z "$BACKUP_DIR" ]; then
        echo "Usage: $0 <backup_directory>"
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

setup_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "Creating backup directory: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
    fi
}

create_backup() {
    local TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
    BACKUP_NAME="skillpulse-db-$TIMESTAMP.sql.gz"
    local BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

    echo "Starting MySQL backup..."
    echo "Pod: $MYSQL_POD"
    echo "Destination: $BACKUP_PATH"

    kubectl exec -n "$NAMESPACE" "$MYSQL_POD" -- \
        mysqldump -u root -ppassword skillpulse 2>/dev/null | gzip > "$BACKUP_PATH"

    if [ $? -ne 0 ] || [ ! -f "$BACKUP_PATH" ] || [ ! -s "$BACKUP_PATH" ]; then
        echo "Error: Backup failed"
        rm -f "$BACKUP_PATH"
        exit 1
    fi

    BACKUP_SIZE=$(ls -lh "$BACKUP_PATH" | awk '{print $5}')

    echo "-----------------------------------"
    echo "Backup created: $BACKUP_NAME"
    echo "Size: $BACKUP_SIZE"
    echo "-----------------------------------"
}

cleanup_old_backups() {
    local COUNT=$(find "$BACKUP_DIR" -type f -name "skillpulse-db-*.sql.gz" -mtime +14 2>/dev/null | wc -l)

    if [ "$COUNT" -gt 0 ]; then
        echo "Removing $COUNT old backups..."
        find "$BACKUP_DIR" -type f -name "skillpulse-db-*.sql.gz" -mtime +14 -exec rm -f {} \;
        DELETED=$COUNT
    else
        echo "No old backups to clean up"
        DELETED=0
    fi
}

main() {
    validate_args
    check_mysql_pod
    setup_backup_dir
    create_backup
    cleanup_old_backups

    echo "-----------------------------------"
    echo "Backup process completed"
    echo "New backup: $BACKUP_NAME ($BACKUP_SIZE)"
    echo "Total backups deleted: $DELETED"
    echo "-----------------------------------"
}

main
