# Quick Start Guide - Modular Service Setup

Get your Apache reverse proxy with selective service proxying running in 5 minutes!

## New Feature: Enable/Disable Services with Environment Variables

This updated version lets you control which services are proxied using simple environment variables. Perfect for media server setups!

## Step 1: Prepare Your Domain

Make sure you have:
- A registered domain (e.g., `yourdomain.com`)
- DNS pointing to your server's IP address
- Port 80 and 443 accessible from the internet

## Step 2: Clone/Download This Repository

```bash
cd /path/to/project
```

## Step 3: Choose Your Services

Before starting, decide which services you want to proxy. Common combinations:

### TV/Movie Automation Setup
```yaml
ENABLE_SONARR: "true"      # TV shows
ENABLE_RADARR: "true"      # Movies
ENABLE_PROWLARR: "true"    # Indexer management
ENABLE_OVERSEERR: "true"   # Request management
ENABLE_QBITTORRENT: "true" # Torrents
```

### Complete Media Server Setup
```yaml
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
ENABLE_JELLYFIN: "true"    # Media playback
ENABLE_OVERSEERR: "true"
ENABLE_QBITTORRENT: "true"
```

### Minimal Setup (Just TV/Movie)
```yaml
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
# Everything else disabled (default)
```

## Step 4: Update Configuration

### Option A: Using docker-compose.yml (Recommended)

Edit `docker-compose.yml` lines 12-40 and update:

```yaml
environment:
  # Your domain
  DOMAIN: yourdomain.com
  EMAIL: your-email@example.com
  
  # Enable the services you want
  ENABLE_SONARR: "true"      # ← Change to true to enable
  ENABLE_RADARR: "true"      # ← Change to true to enable
  ENABLE_PROWLARR: "false"   # ← Change to true to enable
  # ... set others as needed
```

### Option B: Using .env File

Copy and edit the .env file:

```bash
cp .env.example .env
# Edit .env with your preferences
```

Then in `docker-compose.yml`, reference it:

```yaml
env_file: .env
```

## Step 5: Configure Your Services

The proxy expects services to be available at the Docker network hostnames. If using the included docker-compose definitions, they're already configured.

### For Services in docker-compose.yml

Just uncomment the service definitions:

```yaml
sonarr:
  image: lscr.io/linuxserver/sonarr:latest
  # ... rest of config

radarr:
  image: lscr.io/linuxserver/radarr:latest
  # ... rest of config
```

Update the volume paths as needed:
```yaml
volumes:
  - /path/to/your/config:/config
  - /path/to/media:/media
```

### For External Services

If a service runs elsewhere (different machine), update `docker-compose.yml` to reference it:

```yaml
environment:
  ENABLE_SONARR: "true"

# And make sure the service can reach it via network
```

## Step 6: Build and Start

```bash
# Build the Docker image
docker-compose build

# Start all services
docker-compose up -d

# Watch the startup
docker-compose logs -f apache-reverse-proxy
```

Expected output:
```
=== Apache & Let's Encrypt Setup ===
Domain: yourdomain.com
Generating Apache configuration with enabled services...
  ✓ sonarr
  ✓ radarr
  - lidarr (disabled)
  - prowlarr (disabled)
  ...
Generating configuration from template...
Configuration generated: /etc/apache2/sites-available/reverse-proxy.conf
=== Starting Apache ===
```

## Step 7: Verify It Works

```bash
# Check all services are running
docker-compose ps

# Test HTTPS redirect
curl -I http://yourdomain.com

# Test HTTPS and specific services
curl -I https://yourdomain.com/sonarr
curl -I https://yourdomain.com/radarr

# Check certificate
docker-compose exec apache-reverse-proxy certbot certificates
```

## Accessing Your Services

Once running, access enabled services at:

```
https://yourdomain.com/sonarr      (if ENABLE_SONARR=true)
https://yourdomain.com/radarr      (if ENABLE_RADARR=true)
https://yourdomain.com/lidarr      (if ENABLE_LIDARR=true)
https://yourdomain.com/prowlarr    (if ENABLE_PROWLARR=true)
https://yourdomain.com/overseerr   (if ENABLE_OVERSEERR=true)
https://yourdomain.com/jellyfin    (if ENABLE_JELLYFIN=true)
https://yourdomain.com/qbittorrent (if ENABLE_QBITTORRENT=true)
```

## Changing Services Later

Want to enable/disable services?

1. **Edit environment variables** in `docker-compose.yml` or `.env`
2. **Restart the proxy**:
   ```bash
   docker-compose restart apache-reverse-proxy
   ```
3. **View new configuration**:
   ```bash
   docker-compose logs -f apache-reverse-proxy
   ```

The configuration automatically regenerates! No need to manually edit Apache configs.

## Available Services Reference

See `SERVICES.md` for complete information on each service:

- **Sonarr** - TV show automation
- **Radarr** - Movie automation
- **Lidarr** - Music automation
- **Readarr** - Book automation
- **Prowlarr** - Indexer manager
- **Overseerr** - Request manager
- **Jellyfin** - Media streaming
- **Emby** - Emby media server
- **Plex** - Plex media server
- **Tautulli** - Plex monitoring
- **Transmission** - Torrent client
- **qBittorrent** - Advanced torrent client

## Common Issues & Fixes

### Service configured but showing 502 error

1. **Is the service actually running?**
   ```bash
   docker-compose ps servicename
   ```

2. **Can the proxy reach it?**
   ```bash
   docker-compose exec apache-reverse-proxy ping servicename
   ```

3. **Check Apache error log**:
   ```bash
   docker-compose logs apache-reverse-proxy | grep -i error
   ```

### Changes not taking effect after restart

1. **Configuration was already generated** from a previous state
2. **Verify environment variable is set**:
   ```bash
   docker-compose exec apache-reverse-proxy env | grep ENABLE_
   ```
3. **Check generated config**:
   ```bash
   docker-compose exec apache-reverse-proxy cat /etc/apache2/sites-available/reverse-proxy.conf
   ```

### "Configuration validation error" on startup

1. **Check Apache syntax**:
   ```bash
   docker-compose exec apache-reverse-proxy apache2ctl configtest
   ```

2. **View detailed error**:
   ```bash
   docker-compose logs apache-reverse-proxy --tail 50
   ```

## Usage Examples

### Restart After Changes

```bash
# Edit docker-compose.yml to enable/disable services
nano docker-compose.yml

# Restart the proxy (it will regenerate config)
docker-compose restart apache-reverse-proxy

# Watch the startup to confirm services are loaded
docker-compose logs -f apache-reverse-proxy
```

### View Current Configuration

```bash
docker-compose exec apache-reverse-proxy cat /etc/apache2/sites-available/reverse-proxy.conf
```

### View Service Files

```bash
docker-compose exec apache-reverse-proxy ls -la /etc/apache2/sites-available/services/
```

### Test Custom Backend

```yaml
environment:
  ENABLE_CUSTOM_BACKEND: "true"
  CUSTOM_BACKEND_PATH: /myapp
  CUSTOM_BACKEND_URL: http://myservice:8000
```

Then restart and access at: `https://yourdomain.com/myapp`

## Next Steps

1. **For detailed service info**: Read `SERVICES.md`
2. **For full reference**: See `README.md`
3. **For production deployment**: Check README.md's production checklist

## Architecture Overview

```
Internet
   ↓
Your Domain (DNS)
   ↓
Port 80/443 on your server
   ↓
Apache Reverse Proxy (Docker)
   ├→ SSL/TLS (Let's Encrypt)
   ├→ Config Generator (reads environment variables)
   └→ Routes traffic to enabled services
        ├→ /sonarr → Sonarr (if enabled)
        ├→ /radarr → Radarr (if enabled)
        ├→ /jellyfin → Jellyfin (if enabled)
        └→ ... other enabled services
```

---

**Quick Commands Cheat Sheet**

```bash
# Start everything
docker-compose up -d

# View logs
docker-compose logs -f apache-reverse-proxy

# Restart after config changes
docker-compose restart apache-reverse-proxy

# Stop everything
docker-compose down

# Check specific service
docker-compose exec apache-reverse-proxy curl -I http://sonarr:8989

# View generated config
docker-compose exec apache-reverse-proxy cat /etc/apache2/sites-available/reverse-proxy.conf

# Renew certificates manually
docker-compose exec apache-reverse-proxy certbot renew
```

You're all set! 🚀
