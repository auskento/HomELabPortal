# Apache Reverse Proxy with Modular Service Configuration

## What You've Got

A complete, production-ready Docker setup for an Apache reverse proxy with:

✅ **Automatic HTTPS** - Let's Encrypt with auto-renewal  
✅ **Modular Services** - Enable/disable services with environment variables  
✅ **13+ Pre-configured Services** - Sonarr, Radarr, Jellyfin, qBittorrent, and more  
✅ **Load Balancing** - Distribute traffic across multiple backends  
✅ **Custom HTML** - Professional error pages and home page  
✅ **Zero Manual Config** - Service selection via simple env vars  
✅ **Auto-renewal** - Certificates renew automatically daily  

## Project Structure

```
outputs/
├── 📄 Documentation
│   ├── QUICKSTART-SERVICES.md    ← START HERE for service setup
│   ├── QUICKSTART.md             ← Original quick start
│   ├── README.md                 ← Full reference guide
│   ├── SERVICES.md               ← Service details & customization
│   └── TROUBLESHOOTING.md        ← Common issues & fixes
│
├── 🐳 Docker & Configuration
│   ├── Dockerfile                ← Docker image definition
│   ├── docker-compose.yml        ← Complete stack (services included!)
│   ├── docker-entrypoint.sh      ← Container startup script
│   ├── generate-config.sh        ← Service config generator
│   ├── cert-renewal-cron         ← Auto-renewal cron job
│   └── .env.example              ← Environment variables template
│
├── 🔧 Apache Configuration
│   ├── apache-conf/
│   │   ├── reverse-proxy.conf.template  ← Main config template
│   │   ├── ssl-config.conf              ← SSL/TLS settings
│   │   └── services/                    ← Service-specific configs
│   │       ├── sonarr.conf
│   │       ├── radarr.conf
│   │       ├── lidarr.conf
│   │       ├── readarr.conf
│   │       ├── prowlarr.conf
│   │       ├── overseerr.conf
│   │       ├── jellyfin.conf
│   │       ├── emby.conf
│   │       ├── plex.conf
│   │       ├── tautulli.conf
│   │       ├── transmission.conf
│   │       └── qbittorrent.conf
│
└── 🎨 Web Assets
    └── html/
        ├── index.html                    ← Home page
        └── error-pages/
            ├── 502.html                  ← Bad Gateway
            └── 503.html                  ← Service Unavailable
```

## How It Works - The Magic

### Traditional Approach ❌
```
Edit Apache config file → Check syntax → Restart Apache
Repeat for each service → Manual maintenance → Easy to break
```

### New Modular Approach ✅
```
Set environment variables → Container starts → Config auto-generates
Add/remove services → Just restart → No manual config editing
```

### The Process

1. **You set environment variables** in `docker-compose.yml`:
   ```yaml
   ENABLE_SONARR: "true"
   ENABLE_RADARR: "true"
   ENABLE_JELLYFIN: "false"
   ```

2. **Container starts** and entrypoint script runs

3. **Config generator** reads template and environment variables

4. **Selective includes** - Only enabled services are added to Apache config:
   ```
   Template + Variables → Include sonarr.conf ✓
                        → Include radarr.conf ✓
                        → Skip jellyfin.conf ✗
   ```

5. **Apache loads** the generated configuration

6. **Services are live** at their proxy URLs

## Quick Start - Choose Your Path

### Path 1: Just Deploy (5 minutes)

1. Edit `docker-compose.yml` - set domain and enable services
2. Run `docker-compose up -d`
3. Access at `https://yourdomain.com/sonarr`, etc.

**→ See `QUICKSTART-SERVICES.md`**

### Path 2: Learn Everything

1. Start with `README.md` for overview
2. Read `SERVICES.md` for service details
3. Use `TROUBLESHOOTING.md` if issues arise

**→ See `README.md`**

### Path 3: Production Deployment

1. Review production checklist in `README.md`
2. Configure all security settings
3. Set up backups and monitoring
4. Deploy with proper process management

**→ See `README.md` - "Production Deployment" section**

## Available Services (14 Options)

### Media Server Managers (*arr)
- **Sonarr** - TV show automation at `/sonarr`
- **Radarr** - Movie automation at `/radarr`
- **Whisparr** - Adult content collection manager at `/whisparr`
- **Lidarr** - Music automation at `/lidarr`
- **Readarr** - Book automation at `/readarr`
- **Prowlarr** - Indexer manager at `/prowlarr`
- **Overseerr** - Request manager at `/overseerr`

### Media Centers
- **Jellyfin** - Open-source streaming at `/jellyfin`
- **Emby** - Emby streaming at `/emby`
- **Plex** - Plex streaming at `/plex`
- **Tautulli** - Plex monitoring at `/tautulli`

### Torrent Clients
- **Transmission** - Torrent client at `/transmission`
- **qBittorrent** - Advanced torrent at `/qbittorrent`

### Custom
- **Custom Backend** - Any service at custom path

All configured with WebSocket support where needed!

## Features Explained

### 1. Modular Configuration
Services are defined in separate `.conf` files in `apache-conf/services/`. The main config template includes them conditionally based on environment variables.

### 2. Automatic Config Generation
The `generate-config.sh` script processes the template and creates a complete Apache config with only enabled services.

### 3. Service Isolation
Services on the Docker network can be accessed through the reverse proxy without exposing individual ports to the internet. Only expose 80/443.

### 4. WebSocket Support
Real-time features work out of the box:
- Sonarr/Radarr SignalR updates
- Overseerr Socket.io notifications
- qBittorrent real-time status

### 5. Load Balancing

### 6. Security
- Strong TLS 1.2+ enforcement
- Security headers (HSTS, CSP, X-Frame-Options)
- Certificate auto-renewal
- Optional authentication support

## Common Setups

### Setup 1: TV/Movie Automation
```yaml
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
ENABLE_PROWLARR: "true"
ENABLE_OVERSEERR: "true"
ENABLE_QBITTORRENT: "true"
```
Covers: Grabbing, organizing, and requesting TV/movies

### Setup 2: Complete Media Server
```yaml
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
ENABLE_JELLYFIN: "true"
ENABLE_OVERSEERR: "true"
ENABLE_QBITTORRENT: "true"
ENABLE_TAUTULLI: "true"
```
Covers: Everything - grabbing, managing, playing, monitoring

### Setup 3: Minimal
```yaml
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
```
Covers: Just TV and movies

## File Reference

### Core Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Builds the Apache container with all dependencies |
| `docker-compose.yml` | Defines all services (proxy + media servers) |
| `docker-entrypoint.sh` | Startup script - handles certs and config generation |
| `generate-config.sh` | Template processor - creates final Apache config |

### Configuration Files

| File | Purpose |
|------|---------|
| `reverse-proxy.conf.template` | Template with @@PLACEHOLDERS@@ for services |
| `ssl-config.conf` | TLS/SSL security settings |
| `services/*.conf` | Individual service proxy rules |

### Supporting Files

| File | Purpose |
|------|---------|
| `cert-renewal-cron` | Cron schedule for certificate renewal |
| `html/index.html` | Reverse proxy home page |
| `html/error-pages/` | Custom error pages (502, 503) |
| `.env.example` | Template for environment variables |

## Key Environment Variables

```bash
# Required
DOMAIN=yourdomain.com
EMAIL=your-email@example.com

# Services (set to "true" to enable)
ENABLE_SONARR=true
ENABLE_RADARR=true
ENABLE_LIDARR=false
# ... etc

# Optional
SSL_PROTOCOLS="all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1"
SSL_CIPHERS="HIGH:!aNULL:!MD5"
ENABLE_CUSTOM_BACKEND=false
CUSTOM_BACKEND_PATH=/custom
CUSTOM_BACKEND_URL=http://service:8000
```

## Customization Options

### Add a New Service

1. **Create config file** at `apache-conf/services/myservice.conf`:
   ```apache
   <Location /myservice>
       ProxyPass http://myservice:9000
       ProxyPassReverse http://myservice:9000
       ProxyPreserveHost On
   </Location>
   ```

2. **Add to template** in `reverse-proxy.conf.template`:
   ```apache
   @@INCLUDE_MYSERVICE@@
   ```

3. **Update generator script** `generate-config.sh`:
   ```bash
   ENABLE_MYSERVICE="${ENABLE_MYSERVICE:-false}"
   MYSERVICE_INCLUDE=$(generate_include "myservice" "$ENABLE_MYSERVICE")
   CONFIG="${CONFIG//@@INCLUDE_MYSERVICE@@/$MYSERVICE_INCLUDE}"
   ```

4. **Add to docker-compose.yml** environment section

5. **Restart proxy** - it auto-generates the config

### Customize Styling

Edit `html/index.html` and `html/error-pages/*.html` directly. Changes apply on container restart.

### Adjust Timeouts

In `apache-conf/services/*.conf` files:
```apache
ProxyConnectTimeout 60
ProxyTimeout 600
```

### Add Authentication

Uncomment or add auth sections in service configs:
```apache
<Location /sonarr>
    AuthType Basic
    AuthName "Sonarr"
    AuthUserFile /etc/apache2/.htpasswd
    Require valid-user
    ...
</Location>
```

## Documentation Map

| Document | For | Duration |
|----------|-----|----------|
| `QUICKSTART-SERVICES.md` | Getting started with services | 5 min read |
| `QUICKSTART.md` | Original quick start guide | 5 min read |
| `SERVICES.md` | Understanding each service | 10 min read |
| `README.md` | Complete reference | 20 min read |
| `TROUBLESHOOTING.md` | Solving problems | Reference |

## Typical Workflow

### First Time Setup
```bash
1. Clone/download this repo
2. Read QUICKSTART-SERVICES.md (5 min)
3. Edit docker-compose.yml (2 min)
4. docker-compose up -d (2 min)
5. Wait for cert (30-60 sec)
6. Access your services (1 min)
Total: ~15 minutes
```

### Enable New Service Later
```bash
1. Edit docker-compose.yml - set ENABLE_MYSERVICE=true
2. docker-compose restart apache-reverse-proxy (30 sec)
3. Check logs to verify (2 sec)
4. Access at https://domain.com/myservice (instant)
Total: ~1 minute
```

### Troubleshoot Issue
```bash
1. Check TROUBLESHOOTING.md for your error
2. Run suggested diagnostic command
3. Fix the issue (varies)
4. Restart container
5. Verify with curl or browser
Total: 2-10 minutes depending on issue
```

## Important Notes

- ⚠️ **Only set to "true" or "false"** - Other values are ignored (lowercase!)
- ✅ **Changes need container restart** - Just run `docker-compose restart apache-reverse-proxy`
- 🔒 **Certificates obtained automatically** - From Let's Encrypt (free!)
- 🔄 **Auto-renewal runs daily** - No manual renewal needed
- 📝 **Config auto-generates** - No manual Apache editing needed
- 🌐 **Only expose 80/443** - Keep service ports internal
- 📊 **Monitor with logs** - `docker-compose logs -f`

## Getting Help

**If something doesn't work:**

1. **Check TROUBLESHOOTING.md** - covers 95% of issues
2. **Run diagnostic command** from troubleshooting guide
3. **View logs** - `docker-compose logs apache-reverse-proxy`
4. **Check environment variables** - `docker-compose exec apache-reverse-proxy env | grep ENABLE_`
5. **Verify config generated** - `docker-compose exec apache-reverse-proxy cat /etc/apache2/sites-available/reverse-proxy.conf`

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Internet (HTTPS)                        │
│                   yourdomain.com:443                         │
└────────────────────┬────────────────────────────────────────┘
                     │
         ┌───────────▼────────────┐
         │   Docker Network       │
         │                        │
         │  ┌──────────────────┐  │
         │  │ Apache Reverse   │  │
         │  │ Proxy Container  │  │
         │  │                  │  │
         │  │ ✓ SSL/TLS        │  │
         │  │ ✓ Let's Encrypt  │  │
         │  │ ✓ Load Balance   │  │
         │  └──────┬────┬──────┘  │
         │         │    │         │
         │    ┌────▼──┐ ┌▼────┐   │
         │    │Sonarr│ │Radarr│  │
         │    └──────┘ └──────┘   │
         │         ...            │
         │    ┌────────────────┐   │
         │    │ Jellyfin       │   │
         │    │ qBittorrent    │   │
         │    │ Tautulli       │   │
         │    └────────────────┘   │
         │                        │
         └────────────────────────┘
```

---

## Next Steps

👉 **Ready to deploy?** → Read `QUICKSTART-SERVICES.md`

👉 **Want full details?** → Read `README.md`

👉 **Something broken?** → Check `TROUBLESHOOTING.md`

👉 **Need service info?** → See `SERVICES.md`

---

**You've got everything you need. Deploy with confidence!** 🚀
