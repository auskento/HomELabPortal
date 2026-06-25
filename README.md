# HomELabPortal (HeLP) - Unified Media Server Dashboard

A production-ready reverse proxy system for managing 17+ homelab applications with automatic HTTPS, flexible authentication, and customizable dashboards.

**Perfect for:** Sonarr, Radarr, Jellyfin, Plex, qBittorrent, Bazarr, and more!

## ⭐ Key Features

### Services (17 Total)
- **CONTENT**: Sonarr, Radarr, Lidarr, Whisparr
- **SEARCH**: Seerr, Prowlarr, Bazarr ⭐ NEW
- **USENET**: SABnzbd, NZBGet, NZBHydra
- **TORRENTS**: Transmission, qBittorrent, Deluge
- **MEDIA**: Jellyfin, Emby, Plex, Tautulli

### Core Capabilities
- ✅ **HTTPS/TLS** - Automatic via Let's Encrypt
- ✅ **Authentication** - 4 methods (none, basic, Entra ID, Google OAuth)
- ✅ **Dashboard** - 4 themes (modern, classic, sleek, minimal)
- ✅ **Service Ordering** - Customize category order
- ✅ **Auto-Renewal** - Daily certificate renewal
- ✅ **WebSocket Support** - Real-time updates for services
- ✅ **Security Headers** - HSTS, X-Frame-Options, and more

---

## 🚀 Quick Start (5 minutes)

### Prerequisites
- Docker & Docker Compose
- A registered domain (for HTTPS)
- Port 80 and 443 accessible

### Step 1: Clone & Configure

```bash
git clone https://github.com/auskento/apache-reverse-proxy.git
cd apache-reverse-proxy

# Copy example configuration
cp .env.example .env
nano .env  # Edit with your settings
```

### Step 2: Set Basic Variables

```bash
DOMAIN=yourdomain.com
EMAIL=admin@yourdomain.com
ACCESS_MODE=public

# Enable services you want
ENABLE_SONARR=true
ENABLE_RADARR=true
ENABLE_JELLYFIN=true
ENABLE_BAZARR=true
ENABLE_QBITTORRENT=true
```

### Step 3: Deploy

```bash
docker-compose build
docker-compose up -d
```

### Step 4: Verify

```bash
# Check logs
docker-compose logs -f apache-reverse-proxy

# Access dashboard
https://yourdomain.com

# Access individual services
https://yourdomain.com/sonarr
https://yourdomain.com/radarr
https://yourdomain.com/jellyfin
https://yourdomain.com/bazarr
```

---

## 📋 Common Configurations

### Minimal TV/Movie Setup

```yaml
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
ENABLE_JELLYFIN: "true"
ENABLE_QBITTORRENT: "true"
```

### Complete Media Stack

```yaml
# CONTENT Category
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
ENABLE_LIDARR: "true"
ENABLE_WHISPARR: "true"

# SEARCH Category
ENABLE_PROWLARR: "true"
ENABLE_SEERR: "true"
ENABLE_BAZARR: "true"

# USENET Category
ENABLE_SABNZBD: "true"

# TORRENTS Category
ENABLE_QBITTORRENT: "true"

# MEDIA Category
ENABLE_JELLYFIN: "true"
ENABLE_PLEX: "true"
ENABLE_TAUTULLI: "true"
```

### With Basic Authentication

```yaml
AUTHTYPE: basic
BASIC_AUTH_CREDENTIALS: "user1:password1|user2:password2"

# Services enabled above...
```

### With Entra ID (Azure AD)

```yaml
AUTHTYPE: entra
ENTRA_CLIENT_ID: "your-app-id"
ENTRA_CLIENT_SECRET: "your-app-secret"
ENTRA_REDIRECT_URI: "https://yourdomain.com/auth/oauth2/callback"
ENTRA_PROVIDER_METADATA_URL: "https://login.microsoftonline.com/your-tenant/v2.0/.well-known/openid-configuration"

# Services enabled above...
```

---

## 🎨 Dashboard Customization

### Change Theme

```yaml
STYLE: modern      # Recommended: React-based, feature-rich
STYLE: classic     # Original sidebar layout
STYLE: sleek       # Compact with gradient
STYLE: minimal     # Single-column design
```

### Custom Dashboard Name & Icon

```yaml
DASHBOARD_NAME: "My Homelab"
DASHBOARD_ICON: "/icons/apache-reverse-proxy.png"
```

### Custom Landing Page

```yaml
# Load Sonarr calendar on startup
DASHBOARD_LANDING: "sonarr/calendar"

# Or load Radarr
DASHBOARD_LANDING: "radarr"

# Or load Jellyfin
DASHBOARD_LANDING: "jellyfin"
```

### Reorder Service Categories

```yaml
# Default order
DASHBOARD_ORDER: CONTENT,SEARCH,USENET,TORRENTS,MEDIA

# Media servers first
DASHBOARD_ORDER: MEDIA,CONTENT,SEARCH,USENET,TORRENTS

# Downloads first
DASHBOARD_ORDER: USENET,TORRENTS,CONTENT,SEARCH,MEDIA
```

---

## 📁 Project Structure

```
apache-reverse-proxy/
├── 📚 Documentation
│   ├── README.md                      # This file
│   ├── ENVIRONMENT-VARIABLES.md       # All variables explained
│   ├── SERVICES.md                    # Service details
│   ├── SERVICE-URLS.md                # Backend URL setup
│   ├── AUTHENTICATION-SETUP.md        # Auth configuration
│   ├── QUICKSTART.md                  # Quick start guide
│   ├── TROUBLESHOOTING.md             # Problem solving
│   ├── COMPLETE-FEATURES.md           # Feature overview
│   └── CHANGELOG.md                   # Version history
│
├── 🐳 Docker
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── docker-entrypoint.sh           # Startup configuration
│   ├── generate-config.sh             # Apache config generator
│   ├── generate-html-menu.sh          # Dashboard menu generator
│   └── .env.example                   # Configuration template
│
├── 🔧 Apache Configuration
│   ├── apache-conf/
│   │   ├── reverse-proxy.conf.template
│   │   ├── services/                  # Individual service configs
│   │   │   ├── sonarr.conf
│   │   │   ├── radarr.conf
│   │   │   ├── bazarr.conf
│   │   │   ├── jellyfin.conf
│   │   │   └── ... (13 more)
│   │   ├── auth-basic.conf
│   │   ├── auth-entra-protect.conf
│   │   └── auth-google-protect.conf
│
└── 🎨 Web Assets (Generated at runtime)
    └── html/
        ├── dashboard.html             (Modern theme)
        ├── classic.template
        ├── sleek.template
        ├── minimal.template
        └── icons/
            └── (service icons)
```

---

## 🔐 Authentication Methods

### Method 1: No Authentication (Default)

```yaml
AUTHTYPE: none
```
Everyone can access all services.

### Method 2: Basic Authentication

```yaml
AUTHTYPE: basic
BASIC_AUTH_CREDENTIALS: "user1:pass1|user2:pass2"
```
Simple username/password authentication.

### Method 3: Entra ID (Azure AD / Office 365)

```yaml
AUTHTYPE: entra
ENTRA_CLIENT_ID: "..."
ENTRA_CLIENT_SECRET: "..."
ENTRA_REDIRECT_URI: "https://yourdomain.com/auth/oauth2/callback"
ENTRA_PROVIDER_METADATA_URL: "https://login.microsoftonline.com/{tenant-id}/v2.0/.well-known/openid-configuration"
```
Enterprise SSO via Microsoft.

### Method 4: Google OAuth

```yaml
AUTHTYPE: google
GOOGLE_CLIENT_ID: "..."
GOOGLE_CLIENT_SECRET: "..."
GOOGLE_REDIRECT_URI: "https://yourdomain.com"
```
Personal access via Google accounts.

---

## 🔧 Configuration Reference

### Essential Variables

```yaml
# Domain & Email (required for public deployments)
DOMAIN: yourdomain.com
EMAIL: admin@yourdomain.com
ACCESS_MODE: public              # public or private

# Dashboard
STYLE: modern                     # modern, classic, sleek, minimal
DASHBOARD_NAME: "My Media Server"
DASHBOARD_LANDING: ""             # Default service on startup
DASHBOARD_ORDER: "CONTENT,SEARCH,USENET,TORRENTS,MEDIA"

# Authentication
AUTHTYPE: none                    # none, basic, entra, google
```

### Enable Services

For each service you want to proxy:

```yaml
ENABLE_SONARR: "true"
SONARR_URL: "http://sonarr:8989"
```

Available services:
- `ENABLE_SONARR`, `ENABLE_RADARR`, `ENABLE_LIDARR`, `ENABLE_WHISPARR`
- `ENABLE_PROWLARR`, `ENABLE_SEERR`, `ENABLE_BAZARR`
- `ENABLE_SABNZBD`, `ENABLE_NZBGET`, `ENABLE_NZBHYDRA`
- `ENABLE_TRANSMISSION`, `ENABLE_QBITTORRENT`, `ENABLE_DELUGE`
- `ENABLE_JELLYFIN`, `ENABLE_EMBY`, `ENABLE_PLEX`, `ENABLE_TAUTULLI`

**See ENVIRONMENT-VARIABLES.md for complete reference**

---

## 🧪 Testing & Troubleshooting

### Check Service Connectivity

```bash
docker-compose exec apache-reverse-proxy curl -I http://sonarr:8989
# Should return 200 or 401 (if service requires auth)
```

### View Generated Apache Config

```bash
docker-compose exec apache-reverse-proxy cat /etc/apache2/sites-available/reverse-proxy.conf
```

### Check Logs

```bash
# Apache error logs
docker-compose logs -f apache-reverse-proxy | grep error

# Service health check logs
docker-compose logs -f apache-reverse-proxy | grep -E "(502|503|FAIL)"

# Auth logs
docker-compose logs -f apache-reverse-proxy | grep -i auth
```

### Test Configuration Syntax

```bash
docker-compose exec apache-reverse-proxy apache2ctl configtest
# Should show: Syntax OK
```

### Service Not Responding (502 Bad Gateway)

1. **Verify service is running:**
   ```bash
   docker-compose ps sonarr  # replace with service name
   ```

2. **Check service URL is correct:**
   - Verify in `.env` file
   - Check service is accessible: `curl http://sonarr:8989`

3. **Check Apache logs:**
   ```bash
   docker-compose logs apache-reverse-proxy | tail -100
   ```

See **TROUBLESHOOTING.md** for more solutions.

---

## 📊 Deployment Scenarios

### Home Server (Single User)
```yaml
ACCESS_MODE: private
AUTHTYPE: none
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
ENABLE_JELLYFIN: "true"
ENABLE_BAZARR: "true"
```

### Family (Multiple Users)
```yaml
ACCESS_MODE: public
AUTHTYPE: basic
BASIC_AUTH_CREDENTIALS: "dad:password1|mom:password2|kid:password3"
ENABLE_JELLYFIN: "true"
ENABLE_PLEX: "true"
```

### Enterprise (Company Network)
```yaml
ACCESS_MODE: public
AUTHTYPE: entra
ENTRA_CLIENT_ID: "..."  # Azure app ID
ENTRA_CLIENT_SECRET: "..."
# Services enabled...
```

### Content Creator (Full Stack)
```yaml
ACCESS_MODE: public
AUTHTYPE: google
GOOGLE_CLIENT_ID: "..."
GOOGLE_CLIENT_SECRET: "..."
# All services enabled
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
ENABLE_LIDARR: "true"
ENABLE_PROWLARR: "true"
ENABLE_SEERR: "true"
ENABLE_BAZARR: "true"
ENABLE_SABNZBD: "true"
ENABLE_JELLYFIN: "true"
```

---

## 🔒 Security Best Practices

✅ **HTTPS Only** - All traffic encrypted via Let's Encrypt  
✅ **Automatic Renewal** - Certificates renew daily  
✅ **Security Headers** - HSTS, X-Frame-Options enabled  
✅ **Path Protection** - Services only accessible through proxy  
✅ **Authentication** - Choose method appropriate for your use case  
✅ **Internal Network** - Services communicate via Docker network  
✅ **Exposed Ports** - Only 80/443 open, service ports internal  

---

## 📖 Documentation Index

| Document | Purpose |
|----------|---------|
| **QUICKSTART.md** | 5-minute setup guide |
| **ENVIRONMENT-VARIABLES.md** | All configuration options |
| **SERVICES.md** | Details on 17 supported services |
| **SERVICE-URLS.md** | Backend URL configuration |
| **AUTHENTICATION-SETUP.md** | Auth method setup guides |
| **TROUBLESHOOTING.md** | Problem solving |
| **COMPLETE-FEATURES.md** | Feature overview |
| **CHANGELOG.md** | Version history |

---

## 🆘 Need Help?

### Configuration Issues
→ Check **ENVIRONMENT-VARIABLES.md**

### Service Won't Proxy
→ See **SERVICE-URLS.md** and **TROUBLESHOOTING.md**

### Authentication Problems
→ Read **AUTHENTICATION-SETUP.md**

### General Questions
→ Start with **QUICKSTART.md**

### Docker/Technical Help
→ Check container logs: `docker-compose logs apache-reverse-proxy`

---

## 📦 Version Info - HomELabPortal (HeLP)

- **Project**: HomELabPortal (HeLP) - Unified Media Server Dashboard
- **Current Version**: 2.1.0
- **Release Date**: 2026-06-25
- **Services**: 17 total
- **Categories**: 5 (CONTENT, SEARCH, USENET, TORRENTS, MEDIA)
- **Docker Image**: Apache 2.4 + Certbot + mod_proxy

**See CHANGELOG.md for complete version history**

---

## 📝 License

MIT License - See LICENSE file for details

---

## 🚀 Getting Started with HeLP

1. **Read**: [QUICKSTART.md](QUICKSTART.md) (5 min)
2. **Configure**: Edit `.env` with your settings
3. **Deploy**: `docker-compose up -d`
4. **Access**: `https://yourdomain.com`
5. **Troubleshoot**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if needed

**You're ready to deploy HomELabPortal (HeLP)!** 🎉
