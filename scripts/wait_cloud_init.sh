#!/usr/bin/env bash

set -euo pipefail

CLOUD_INIT_FINISH_FILE="/var/lib/cloud/instance/boot-finished"
FILE_NAME=${FILE_NAME:-$CLOUD_INIT_FINISH_FILE}

SLEEP_DELAY=${SLEEP_DELAY:-3}
TIMEOUT_SECONDS=${TIMEOUT_SECONDS:-60}

current_timestamp() {
    date +%s
}

START_TIME=$(current_timestamp)
DEADLINE_TIME=$(( START_TIME + TIMEOUT_SECONDS ))

# Wait for cloud-init to finish running
while [[ ! -e $FILE_NAME ]]; do
    echo "--> Waiting for cloud-init to finish..."

    # Allow timing-out if waiting for too long
    CURRENT_TIME=$(current_timestamp)
    if (( CURRENT_TIME > DEADLINE_TIME )); then
        echo "--> Waiting for cloud-init to finish timed out after $TIMEOUT_SECONDS seconds."
        exit 1
    fi

    # Wait
    sleep $SLEEP_DELAY
done

FINISH_TIME=$(current_timestamp)
TOTAL_DURATION=$(( FINISH_TIME - START_TIME ))

echo "--> Finished waiting for cloud-init to finish after $TOTAL_DURATION seconds."

