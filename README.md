# Docker Compose Examples for Cache Manager

[![Docker Image CI/CD](https://github.com/hhftechnology/docker-cache-manager-unraid/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/hhftechnology/docker-cache-manager-unraid/actions/workflows/docker-publish.yml)

## Basic Setup Example
```yaml
version: '3.8'
services:
  cache-manager:
    image: hhftechnology/docker-cache-manager-unraid:latest
    container_name: cache-manager
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /mnt/cache:/mnt/cache:ro
      - ./config:/app/config
      - ./logs:/app/logs
    environment:
      - TZ=UTC
      - PAUSE_THRESHOLD=85
      - RESUME_THRESHOLD=70
      - CONTAINER_NAME=downloader
    privileged: true
```

## Scenario 1: Large Media Downloads (Usenet)
```yaml
version: '3.8'
services:
  cache-manager:
    image: hhftechnology/docker-cache-manager-unraid:latest
    container_name: cache-manager-usenet
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /mnt/cache:/mnt/cache:ro
      - /mnt/user/appdata/cache-manager:/app/config
      - /mnt/user/appdata/cache-manager/logs:/app/logs
    environment:
      - TZ=UTC
      - CONTAINER_NAME=nzbget
      - PAUSE_THRESHOLD=90
      - RESUME_THRESHOLD=75
      - CHECK_INTERVAL=300
      - INCOMPLETE_DIR=/mnt/cache/downloads/usenet/incomplete
      - COMPLETE_DIR=/mnt/cache/downloads/usenet/complete
      - ENABLE_NOTIFICATIONS=true
      - NOTIFICATION_URL=http://notify.mydomain.com
      - MOVER_CHECK_ENABLED=true
    privileged: true
    networks:
      - usenet_network
```

## Scenario 2: Multiple Download Clients
```yaml
version: '3.8'
services:
  cache-manager:
    image: hhftechnology/docker-cache-manager-unraid:latest
    container_name: cache-manager-multi
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /mnt/cache:/mnt/cache:ro
      - ./config:/app/config
      - ./logs:/app/logs
    environment:
      - TZ=UTC
      - CONTAINER_NAMES=["qbittorrent","nzbget","transmission"]
      - PAUSE_THRESHOLDS={"qbittorrent":85,"nzbget":80,"transmission":75}
      - RESUME_THRESHOLDS={"qbittorrent":70,"nzbget":65,"transmission":60}
      - CHECK_INTERVAL=180
      - ENABLE_DEBUG_LOGGING=true
      - MAX_LOG_SIZE=50M
      - NOTIFICATION_DISCORD_WEBHOOK=https://discord.webhook.url
    privileged: true
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 1m
      timeout: 10s
      retries: 3
```

## Scenario 3: High-Speed Cache (NVMe)
```yaml
version: '3.8'
services:
  cache-manager:
    image: hhftechnology/docker-cache-manager-unraid:latest
    container_name: cache-manager-nvme
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /mnt/nvme_cache:/mnt/cache:ro
      - ./config:/app/config
      - ./logs:/app/logs
    environment:
      - TZ=UTC
      - PAUSE_THRESHOLD=95
      - RESUME_THRESHOLD=85
      - CHECK_INTERVAL=60
      - ENABLE_TURBO_WRITE=true
      - MOVER_AGGRESSIVE=true
      - IO_THRESHOLD=500MB/s
      - MONITOR_DISK_IO=true
    privileged: true
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 256M
```

## Scenario 4: Small Cache Drive with Multiple Apps
```yaml
version: '3.8'
services:
  cache-manager:
    image: hhftechnology/docker-cache-manager-unraid:latest
    container_name: cache-manager-small
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /mnt/cache:/mnt/cache:ro
      - ./config:/app/config
      - ./logs:/app/logs
    environment:
      - TZ=UTC
      - PAUSE_THRESHOLD=75
      - RESUME_THRESHOLD=60
      - CHECK_INTERVAL=120
      - MAX_CONCURRENT_DOWNLOADS=2
      - CONTAINER_NAMES=["plex","qbittorrent","radarr","sonarr"]
      - PRIORITY_CONTAINERS=["plex"]
      - AGGRESSIVE_MOVER=true
      - MINIMUM_FREE_SPACE=10G
      - ENABLE_NOTIFICATIONS=true
      - NOTIFICATION_TYPE=telegram
      - TELEGRAM_BOT_TOKEN=your_bot_token
      - TELEGRAM_CHAT_ID=your_chat_id
    privileged: true
    labels:
      - "com.unraid.docker.managed=true"
      - "com.unraid.docker.icon=https://raw.githubusercontent.com/your-repo/icon.png"
```

## Scenario 5: Media Server with Plex Transcoding
```yaml
version: '3.8'
services:
  cache-manager:
    image: hhftechnology/docker-cache-manager-unraid:latest
    container_name: cache-manager-plex
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /mnt/cache:/mnt/cache:ro
      - /mnt/transcodes:/mnt/transcodes:ro
      - ./config:/app/config
      - ./logs:/app/logs
    environment:
      - TZ=UTC
      - CONTAINER_NAMES=["plex","downloader"]
      - PAUSE_THRESHOLD=80
      - RESUME_THRESHOLD=65
      - CHECK_INTERVAL=300
      - MONITOR_PATHS=["/mnt/transcodes","/mnt/cache/downloads"]
      - PLEX_TOKEN=your_plex_token
      - ENABLE_PLEX_WEBHOOK=true
      - WEBHOOK_URL=http://your-webhook-url
    privileged: true
    networks:
      - plex_network

networks:
  plex_network:
    external: true
```

## Scenario 6: Docker Development Environment
```yaml
version: '3.8'
services:
  cache-manager:
    image: hhftechnology/docker-cache-manager-unraid:latest
    container_name: cache-manager-dev
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /mnt/cache:/mnt/cache:ro
      - ./config:/app/config
      - ./logs:/app/logs
      - ./custom-scripts:/app/custom-scripts
    environment:
      - TZ=UTC
      - CONTAINER_PATTERNS=["*-dev", "*-test"]
      - EXCLUDE_CONTAINERS=["database","redis"]
      - PAUSE_THRESHOLD=70
      - RESUME_THRESHOLD=50
      - CHECK_INTERVAL=60
      - ENABLE_DEBUG_LOGGING=true
      - CUSTOM_SCRIPT_PATH=/app/custom-scripts/dev-handler.sh
    privileged: true
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD", "/app/scripts/healthcheck.sh"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## Usage Notes

1. All configurations assume:
   - The image is already pulled
   - Required directories exist
   - Proper permissions are set

2. Before using any configuration:
   - Update timezone (TZ) to match your location
   - Modify paths to match your Unraid setup
   - Update notification tokens/webhooks
   - Adjust thresholds based on your cache size

3. Important volume mounts:
   ```yaml
   volumes:
     - /var/run/docker.sock:/var/run/docker.sock  # Required for Docker control
     - /mnt/cache:/mnt/cache:ro                   # Cache access
     - ./config:/app/config                       # Configuration
     - ./logs:/app/logs                          # Logging
   ```

4. Common environment variables:
   ```yaml
   environment:
     - PAUSE_THRESHOLD=85        # When to pause containers
     - RESUME_THRESHOLD=70       # When to resume containers
     - CHECK_INTERVAL=300        # Check frequency in seconds
     - ENABLE_NOTIFICATIONS=true # Enable notifications
   ```

5. Security considerations:
   - The container requires privileged mode for cache access
   - Use read-only mounts where possible
   - Consider network isolation for sensitive containers

6. Additional features:
   - Health checks ensure the service is running properly
   - Resource limits prevent excessive CPU/memory usage
   - Custom scripts can be mounted for additional functionality
   - Multiple notification options available
