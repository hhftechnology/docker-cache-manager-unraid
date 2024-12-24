#!/bin/bash

# Verify configuration file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Verify Docker socket access
if [[ ! -S /var/run/docker.sock ]]; then
    echo "Error: Docker socket not found"
    exit 1
fi

# Check required directories
for dir in "$CACHE_DIR" "$INCOMPLETE_DIR" "$COMPLETE_DIR"; do
    if [[ ! -d "$dir" ]]; then
        echo "Warning: Directory $dir not found"
    fi
done

# Start cache manager
exec /app/scripts/cache_manager.sh