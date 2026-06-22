# Quick Start Guide

Get your Apache reverse proxy with Let's Encrypt running in 5 minutes!

## Prerequisites

- Registered domain (e.g., `yourdomain.com`)
- DNS pointing to your server's IP address
- Port 80 and 443 accessible
- Docker and docker-compose installed

## Step 1: Get the Configuration

Download or clone the repository with all configuration files.

## Step 2: Update Environment Variables

Edit `docker-compose.yml` and set:

```yaml
environment:
  DOMAIN: yourdomain.com
  EMAIL: your-email@example.com
  
  # Enable services you want to proxy
  ENABLE_SONARR: "true"
  ENABLE_RADARR: "true"
  ENABLE_JELLYFIN: "false"
```

Or copy and edit `.env.example`:

```bash
cp .env.example .env
# Edit .env with your domain and email
```

## Step 3: Configure Backend Services

Ensure your Docker services are running and accessible:

```bash
# Example: Start Sonarr if not already running
docker run -d \
  --name sonarr \
  -p 8989:8989 \
  -v /path/to/config:/config \
  -v /path/to/media:/media \
  lscr.io/linuxserver/sonarr
```

**Important**: Services must be on the same Docker network as the proxy.

## Step 4: Build and Deploy

```bash
# Build the Docker image
docker-compose build

# Start the reverse proxy
docker-compose up -d

# Watch startup process
docker-compose logs -f apache-reverse-proxy
```

You should see:
```
=== Setting up Office 365 Authentication === (if enabled)
=== Apache & Let's Encrypt Setup ===
Domain: yourdomain.com
Requesting certificate from Let's Encrypt...
=== Starting Apache ===
Apache is running!
```

## Step 5: Verify It Works

```bash
# Check container status
docker-compose ps

# Test HTTP → HTTPS redirect
curl -I http://yourdomain.com
# Should show: HTTP/1.1 301 Moved Permanently

# Test HTTPS
curl -I https://yourdomain.com
# Should show: HTTP/2 200 OK

# Verify certificate
docker-compose exec apache-reverse-proxy certbot certificates
```

## Step 6: Access Your Services

Visit your domain in browser:

```
https://yourdomain.com/         # Dashboard
https://yourdomain.com/sonarr   # Sonarr (if enabled)
https://yourdomain.com/radarr   # Radarr (if enabled)
https://yourdomain.com/jellyfin # Jellyfin (if enabled)
```

## Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| "Connection refused" | Services not running - check Docker containers |
| "Certificate not found" | Port 80 blocked - check firewall rules |
| "502 Bad Gateway" | Backend not accessible - verify service container name |
| "Can't connect to domain" | DNS not resolving - check DNS settings |

## What Happens Next?

1. ✅ Certificate obtained from Let's Encrypt (free)
2. ✅ HTTPS enabled with strong security settings
3. ✅ Auto-renewal set up for daily certificate checks
4. ✅ Traffic routed securely to your services
5. ✅ Dashboard available for service access

## Common Tasks

### View Logs
```bash
docker-compose logs -f apache-reverse-proxy
```

### Restart After Changes
```bash
docker-compose restart apache-reverse-proxy
```

### Renew Certificate Manually
```bash
docker-compose exec apache-reverse-proxy certbot renew
```

### Stop Everything
```bash
docker-compose down
```

## Next Steps

For more detailed guides, see:

- **QUICKSTART-SERVICES.md** - Detailed service configuration
- **COMPLETE-FEATURES.md** - All available features
- **OFFICE365-AUTH.md** - Setting up authentication
- **UNRAID-SETUP.md** - Unraid installation
- **README.md** - Full technical reference

---

**You're all set!** 🚀

Services are now accessible through your secure reverse proxy.
