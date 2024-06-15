#!/bin/bash

# Check if .env file exists and
if [ -f .env ]; then
    source .env
else
    echo ".env file not found!"
    exit 1
fi

# Check if Restic is installed
if ! command -v restic &> /dev/null
then
    echo "Restic could not be found."
    exit
fi

lockFile() {
    exec 99>"${LOCKFILE}"
    flock -n 99

    RC=$?
    if [ "$RC" != 0 ]; then
        echo "This restic ${REPOSITORY} backup of ${FOLDER_PATH} is already running. Exiting."
        exit
    fi
}

# Function to check if the repository exists
check_repo() {
    echo "Checking if repository exists"
    restic -r $REPO --password-file=$PASSWORD_FILE cat config > /dev/null 2>&1
    exit_code=$?
}
# Executing the function
check_repo
if [ $exit_code -ne 0 ]; then
    echo "Can't find repo"
    exit 1
fi
echo "Repository found"

runBackup() {
    echo "Starting Backup"
    restic -r $REPO backup --files-from $BACKUP_FILE --verbose --compression=max --password-file=$PASSWORD_FILE --exclude-if-present .resticignore
    if [ $(echo $?) -eq 1 ]; then
        echo "Fatal error detected!"
        echo "Cleaning up lock file and exiting."
        rm -f ${LOCKFILE} | tee -a $LOG_FILE
        exit 1
    fi
}

datestring() {
    date +%Y-%m-%d\ %H:%M:%S
}
datestring

# Create Log
START_TIMESTAMP=$(date +%s)
LOG_FILE="logs/$(date +%Y-%m-%d-%H-%M-%S).log"
touch $LOG_FILE
echo "restic backup script started at $(datestring)" | tee -a $LOG_FILE
echo "REPOSITORY=${REPO}" | tee -a $LOG_FILE

# Create Lockfile
LOCKFILE="/tmp/my_restic_backup.lock"
lockFile | tee -a $LOG_FILE

# Run the backup
runBackup | tee -a $LOG_FILE

# clean up lockfile
rm -f ${LOCKFILE} | tee -a $LOG_FILE

delta=$(date -d@$(($(date +%s) - $START_TIMESTAMP)) -u +%H:%M:%S)
echo "restic backup script finished at $(datestring) in ${delta}" | tee -a $LOG_FILE