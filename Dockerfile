# Use Alpine Linux for a minimal base image
FROM hhftechnology/alpine:3.19

# Add labels for better container management
LABEL maintainer="HHF Technology <discourse@hhf.technology>"
LABEL description="Docker container for managing cache and downloads"
LABEL version="1.0"

# Install required packages
RUN apk add --no-cache \
    bash \
    docker-cli \
    curl \
    jq \
    tzdata \
    && rm -rf /var/cache/apk/*

# Create necessary directories
RUN mkdir -p /app/config /app/scripts /app/logs

# Set working directory
WORKDIR /app

# Copy configuration and scripts
COPY config/default.conf /app/config/
COPY scripts/entrypoint.sh /app/scripts/
COPY scripts/cache_manager.sh /app/scripts/

# Make scripts executable
RUN chmod +x /app/scripts/*.sh

# Set environment variables
ENV CONFIG_FILE=/app/config/default.conf
ENV LOG_FILE=/app/logs/cache_manager.log
ENV TZ=UTC

# Create volume mount points
VOLUME ["/app/config", "/app/logs", "/var/run/docker.sock"]

# Set entrypoint
ENTRYPOINT ["/app/scripts/entrypoint.sh"]