# Docker Cache Manager for Unraid

A sophisticated Docker container solution for managing cache usage and download operations in Unraid environments. This system automatically manages Docker containers based on cache utilization, preventing cache overflow while maintaining optimal download performance.

## Table of Contents
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage Scenarios](#usage-scenarios)
- [Advanced Configuration](#advanced-configuration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Features

- Automated container management based on cache usage
- Configurable thresholds for pausing and resuming containers
- Integration with Unraid's mover service
- Comprehensive logging system with rotation
- Notification system for critical events
- Multiple deployment options
- Support for various download clients
- Customizable monitoring and alerting

## Requirements

- Unraid 6.9.0 or higher
- Docker runtime environment
- Access to Docker socket
- Sufficient permissions to manage containers
- Cache drive configured in Unraid
- Docker containers for download clients (optional)

## Installation

### Quick Start

1. Clone the repository:
```bash
git clone https://github.com/hhftechnology/docker-cache-manager-unraid.git
cd docker-cache-manager-unraid
```

2. Configure your settings:
```bash
cp config/default.conf config/my-config.conf
nano config/my-config.conf
```

3. Deploy using Docker Compose:
```bash
docker-compose up -d
```

### Manual Installation

1. Build the Docker image:
```bash
docker build -t cache-manager .
```

2. Run the container:
```bash
docker run -d \
  --name cache-manager \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /mnt/cache:/mnt/cache:ro \
  -v $(pwd)/config:/app/config \
  -v $(pwd)/logs:/app/logs \
  cache-manager
```

## Configuration

### Basic Configuration

The system can be configured through the `config/default.conf` file:

```bash
# Basic settings
CACHE_DIR="/mnt/cache"
PAUSE_THRESHOLD=85
RESUME_THRESHOLD=70
CONTAINER_NAME="downloader"

# Advanced settings
CHECK_INTERVAL=300
ENABLE_NOTIFICATIONS=true
```

### Environment Variables

You can override configuration settings using environment variables:

```yaml
environment:
  - PAUSE_THRESHOLD=90
  - RESUME_THRESHOLD=75
  - CHECK_INTERVAL=180
```

## Usage Scenarios

### Scenario 1: Large Media Downloads (Usenet)

Perfect for managing large Usenet downloads where cache overflow is a common issue.

```yaml
version: '3.8'

services:
  cache-manager:
    image: cache-manager
    environment:
      - CONTAINER_NAME=nzbget
      - PAUSE_THRESHOLD=90
      - RESUME_THRESHOLD=75
      - INCOMPLETE_DIR=/mnt/cache/downloads/incomplete
      - COMPLETE_DIR=/mnt/cache/downloads/complete
    volumes:
      - /mnt/cache/downloads:/mnt/cache/downloads
```

Recommended Unraid Share Configuration:
```plaintext
Downloads Share:
- Cache: Only
- Minimum Free Space: 100GB
- Direct I/O: Enabled

Media Share:
- Cache: Yes
- Minimum Free Space: 50GB
```

### Scenario 2: Multiple Download Clients (Torrents + Usenet)

Managing multiple download clients with different priorities.

```yaml
version: '3.8'

services:
  cache-manager:
    image: cache-manager
    environment:
      - CONTAINER_NAMES=["qbittorrent", "nzbget"]
      - PRIORITIES={"qbittorrent": 1, "nzbget": 2}
      - PAUSE_THRESHOLDS={"qbittorrent": 85, "nzbget": 75}
```

Share Structure:
```plaintext
/mnt/cache/
├── downloads/
│   ├── torrents/
│   │   ├── incomplete/
│   │   └── complete/
│   └── usenet/
│       ├── incomplete/
│       └── complete/
```

### Scenario 3: High-Speed Cache (NVMe)

Optimized for systems with high-speed NVMe cache drives.

```yaml
services:
  cache-manager:
    image: cache-manager
    environment:
      - CHECK_INTERVAL=60
      - MOVER_THRESHOLD=95
      - ENABLE_TURBO_WRITE=true
    volumes:
      - /mnt/nvme:/mnt/cache
```

Recommended Mover Settings:
```plaintext
Schedule: Every 15 minutes
Threshold: 95%
Turbo Write: Enabled
```

### Scenario 4: Small Cache Drive

Optimized configuration for systems with limited cache space.

```yaml
services:
  cache-manager:
    image: cache-manager
    environment:
      - PAUSE_THRESHOLD=80
      - RESUME_THRESHOLD=60
      - MAX_CONCURRENT_DOWNLOADS=2
      - AGGRESSIVE_MOVER=true
```

Share Configuration:
```plaintext
Downloads:
- Cache: Only
- Minimum Free Space: 25%
- Split Level: 1
```

## Advanced Configuration

### Notification Setup

Configure notifications through popular services:

```yaml
environment:
  - ENABLE_NOTIFICATIONS=true
  - NOTIFICATION_SERVICE=discord
  - NOTIFICATION_URL=https://discord.webhook.url
  - NOTIFICATION_EVENTS=["pause", "resume", "error"]
```

### Custom Monitoring

Add custom monitoring rules:

```bash
# config/monitoring.conf
MONITOR_DISK_IO=true
IO_THRESHOLD=50MB/s
MONITOR_NETWORK=true
NETWORK_THRESHOLD=100MB/s
```

### Resource Limits

Configure container resource limits:

```yaml
services:
  cache-manager:
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 256M
```

## Troubleshooting

### Common Issues

1. Container Won't Start
```bash
# Check logs
docker logs cache-manager

# Verify permissions
ls -l /var/run/docker.sock
```

2. High Cache Usage
```bash
# Check current status
docker exec cache-manager /app/scripts/status.sh

# Force mover run
docker exec cache-manager /app/scripts/force-move.sh
```

3. Container Not Pausing
```bash
# Verify container name
docker ps --format "{{.Names}}"

# Check container status
docker inspect downloader --format "{{.State.Status}}"
```

### Log Analysis

Analyze logs for issues:
```bash
# View real-time logs
tail -f logs/cache_manager.log

# Search for errors
grep ERROR logs/cache_manager.log
```

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.