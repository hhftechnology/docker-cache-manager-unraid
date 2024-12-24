#!/bin/bash

# Source configuration
source "${CONFIG_FILE:-/app/config/default.conf}"

# Initialize logging
setup_logging() {
    local log_dir=$(dirname "$LOG_FILE")
    mkdir -p "$log_dir"
    
    if [[ "$ENABLE_DEBUG_LOGGING" == "true" ]]; then
        set -x
    fi
}

# Enhanced logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
    
    if [[ "$ENABLE_NOTIFICATIONS" == "true" && "$level" == "ERROR" ]]; then
        send_notification "$message"
    fi
}

# Send notifications
send_notification() {
    local message="$1"
    if [[ -n "$NOTIFICATION_URL" && -n "$NOTIFICATION_TOKEN" ]]; then
        curl -s -X POST \
             -H "Authorization: Bearer $NOTIFICATION_TOKEN" \
             -H "Content-Type: application/json" \
             -d "{\"message\": \"$message\"}" \
             "$NOTIFICATION_URL" || true
    fi
}

# Get cache usage with error handling
get_cache_usage() {
    local usage
    if ! usage=$(df "$CACHE_DIR" | awk 'NR==2 {print $5}' | sed 's/%//'); then
        log_message "ERROR" "Failed to get cache usage"
        return 1
    fi
    echo "$usage"
}

# Check Docker container status
check_container() {
    local container="$1"
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        log_message "ERROR" "Container $container not found"
        return 1
    fi
    
    local status
    status=$(docker inspect -f '{{.State.Status}}' "$container")
    echo "$status"
}

# Manage container state
manage_container() {
    local cache_usage="$1"
    local container_status
    
    if ! container_status=$(check_container "$CONTAINER_NAME"); then
        return 1
    fi
    
    if [[ $cache_usage -ge $PAUSE_THRESHOLD && "$container_status" == "running" ]]; then
        log_message "INFO" "Pausing container due to high cache usage (${cache_usage}%)"
        if ! docker pause "$CONTAINER_NAME"; then
            log_message "ERROR" "Failed to pause container"
            return 1
        fi
    elif [[ $cache_usage -le $RESUME_THRESHOLD && "$container_status" == "paused" ]]; then
        if [[ "$MOVER_CHECK_ENABLED" == "true" ]]; then
            if mover status | grep -q "not running"; then
                log_message "INFO" "Resuming container (cache usage: ${cache_usage}%)"
                if ! docker unpause "$CONTAINER_NAME"; then
                    log_message "ERROR" "Failed to resume container"
                    return 1
                fi
            else
                log_message "INFO" "Mover is running, waiting to resume container"
            fi
        else
            if ! docker unpause "$CONTAINER_NAME"; then
                log_message "ERROR" "Failed to resume container"
                return 1
            fi
        fi
    fi
}

# Rotate logs
rotate_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        local log_size
        log_size=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE")
        if [[ ${log_size:-0} -gt ${MAX_LOG_SIZE//[!0-9]/} ]]; then
            for i in $(seq $((MAX_LOG_FILES-1)) -1 1); do
                [[ -f "${LOG_FILE}.$i" ]] && mv "${LOG_FILE}.$i" "${LOG_FILE}.$((i+1))"
            done
            mv "$LOG_FILE" "${LOG_FILE}.1"
            touch "$LOG_FILE"
        fi
    fi
}

# Main execution loop
main() {
    setup_logging
    log_message "INFO" "Cache manager started"
    
    while true; do
        rotate_logs
        
        local cache_usage
        if ! cache_usage=$(get_cache_usage); then
            sleep "$CHECK_INTERVAL"
            continue
        fi
        
        log_message "INFO" "Current cache usage: ${cache_usage}%"
        manage_container "$cache_usage"
        
        sleep "$CHECK_INTERVAL"
    done
}

# Handle signals
trap 'log_message "INFO" "Shutting down..."; exit 0' SIGTERM SIGINT

# Start the service
main