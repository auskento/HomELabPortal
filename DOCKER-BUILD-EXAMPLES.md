# Docker Build Examples

This document provides practical examples of building and running the Apache Reverse Proxy container with different configurations.

## Building the Image

### Basic Build
```bash
docker build -t auskento/apache-reverse-proxy:latest .
```

### Build with Custom Tag
```bash
docker build -t myrepo/apache-reverse-proxy:v1.0 .
```

### Build with BuildKit (Faster)
```bash
DOCKER_BUILDKIT=1 docker build -t auskento/apache-reverse-proxy:latest .
```

---

## Running Examples

### Example 1: Public Deployment with Basic Auth

**docker-compose.yml:**
```yaml
version: '3.8'
services:
  apache-reverse-proxy:
    image: auskento/apache-reverse-proxy:latest
    ports:
      - "80:80"
      - "443:443"
    environment:
      ACCESS_MODE: public
      DOMAIN: yourdomain.com
      EMAIL: admin@yourdomain.com
      TZ: Australia/Melbourne
      STYLE: modern
      DASHBOARD_NAME: My Homelab
      DASHBOARD_ICON: /icons/apache-reverse-proxy.png
      DASHBOARD_LANDING: radarr
      DASHBOARD_ORDER: CONTENT,SEARCH,USENET,TORRENTS,MEDIA
      AUTHTYPE: basic
      BASIC_AUTH_CREDENTIALS: "admin:securepassword|user:password"
      ENABLE_RADARR: "true"
      RADARR_URL: http://radarr:7878
      ENABLE_SONARR: "true"
      SONARR_URL: http://sonarr:8989
      ENABLE_JELLYFIN: "true"
      JELLYFIN_URL: http://jellyfin:8096
    volumes:
      - /mnt/user/appdata/apache-reverse-proxy/letsencrypt:/etc/letsencrypt
      - /mnt/user/appdata/apache-reverse-proxy/logs:/var/log/apache2
    restart: unless-stopped
```

**Run:**
```bash
docker-compose up -d
```

---

### Example 2: Private/Internal Deployment (No SSL)

**docker-compose.yml:**
```yaml
version: '3.8'
services:
  apache-reverse-proxy:
    image: auskento/apache-reverse-proxy:latest
    ports:
      - "8080:80"
    environment:
      ACCESS_MODE: private
      DOMAIN: internal-proxy
      EMAIL: admin@local
      TZ: Australia/Melbourne
      STYLE: sleek
      DASHBOARD_NAME: Family Media
      DASHBOARD_LANDING: ""
      DASHBOARD_ORDER: MEDIA,USENET,TORRENTS,CONTENT,SEARCH
      AUTHTYPE: basic
      BASIC_AUTH_CREDENTIALS: "user:password"
      ENABLE_PLEX: "true"
      PLEX_URL: http://192.168.1.100:32400
      ENABLE_EMBY: "true"
      EMBY_URL: http://192.168.1.101:8096
      ENABLE_JELLYFIN: "true"
      JELLYFIN_URL: http://192.168.1.102:8096
    volumes:
      - /mnt/docker-data/apache-reverse-proxy/logs:/var/log/apache2
    restart: unless-stopped
```

---

### Example 3: OAuth2 with Entra ID (Azure AD)

**docker-compose.yml:**
```yaml
version: '3.8'
services:
  apache-reverse-proxy:
    image: auskento/apache-reverse-proxy:latest
    ports:
      - "80:80"
      - "443:443"
    environment:
      ACCESS_MODE: public
      DOMAIN: mycompany.com
      EMAIL: devops@mycompany.com
      TZ: Europe/London
      STYLE: modern
      DASHBOARD_NAME: Company Services
      DASHBOARD_LANDING: radarr/calendar
      DASHBOARD_ORDER: CONTENT,SEARCH,USENET,TORRENTS,MEDIA
      AUTHTYPE: entra
      ENTRA_CLIENT_ID: your-azure-app-id
      ENTRA_CLIENT_SECRET: your-azure-app-secret
      ENTRA_REDIRECT_URI: https://mycompany.com/auth/oauth2/callback
      ENTRA_PROVIDER_METADATA_URL: https://login.microsoftonline.com/your-tenant-id/v2.0/.well-known/openid-configuration
      ENTRA_CRYPTO_PASSPHRASE: your-secure-passphrase
      ENABLE_SONARR: "true"
      SONARR_URL: http://sonarr:8989
      ENABLE_RADARR: "true"
      RADARR_URL: http://radarr:7878
      ENABLE_PROWLARR: "true"
      PROWLARR_URL: http://prowlarr:9696
    volumes:
      - /data/apache-proxy/letsencrypt:/etc/letsencrypt
      - /data/apache-proxy/logs:/var/log/apache2
    restart: unless-stopped
```

---

### Example 4: Google OAuth2

**Important:** The `GOOGLE_REDIRECT_URI` must **exactly match** the authorized redirect URI configured in your Google Cloud Console. If they don't match, authentication will fail with `Error 400: redirect_uri_mismatch`.

**docker-compose.yml:**
```yaml
version: '3.8'
services:
  apache-reverse-proxy:
    image: auskento/apache-reverse-proxy:latest
    ports:
      - "80:80"
      - "443:443"
    environment:
      ACCESS_MODE: public
      DOMAIN: services.example.com
      EMAIL: admin@example.com
      TZ: America/New_York
      STYLE: minimal
      DASHBOARD_NAME: Dashboard
      DASHBOARD_LANDING: ""
      DASHBOARD_ORDER: CONTENT,SEARCH,USENET,TORRENTS,MEDIA
      AUTHTYPE: google
      GOOGLE_CLIENT_ID: your-client-id.apps.googleusercontent.com
      GOOGLE_CLIENT_SECRET: your-client-secret
      GOOGLE_REDIRECT_URI: https://services.example.com  # Must match Google Cloud Console config
      ENABLE_SABNZBD: "true"
      SABNZBD_URL: http://sabnzbd:8080
      ENABLE_NZBGET: "true"
      NZBGET_URL: http://nzbget:6789
      ENABLE_NZBHYDRA: "true"
      NZBHYDRA_URL: http://nzbhydra:5076
      ENABLE_DELUGE: "true"
      DELUGE_URL: http://deluge:8112
      ENABLE_TRANSMISSION: "true"
      TRANSMISSION_URL: http://transmission:6969
      ENABLE_QBITTORRENT: "true"
      QBITTORRENT_URL: http://qbittorrent:8080
      ENABLE_RADARR: "true"
      RADARR_URL: http://radarr:7878
      ENABLE_SONARR: "true"
      SONARR_URL: http://sonarr:8989
      ENABLE_PROWLARR: "true"
      PROWLARR_URL: http://prowlarr:9696
      ENABLE_SEERR: "true"
      SEERR_URL: http://seerr:5055
      ENABLE_LIDARR: "true"
      LIDARR_URL: http://lidarr:8686
      ENABLE_WHISPARR: "true"
      WHISPARR_URL: http://whisparr:6969
      ENABLE_PLEX: "true"
      PLEX_URL: http://plex:32400
      ENABLE_EMBY: "true"
      EMBY_URL: http://emby:8096
      ENABLE_JELLYFIN: "true"
      JELLYFIN_URL: http://jellyfin:8096
      ENABLE_TAUTULLI: "true"
      TAUTULLI_URL: http://tautulli:8181
    volumes:
      - /docker/apache-proxy/letsencrypt:/etc/letsencrypt
      - /docker/apache-proxy/logs:/var/log/apache2
    restart: unless-stopped
```

---

### Example 5: Using .env File

**docker-compose.yml:**
```yaml
version: '3.8'
services:
  apache-reverse-proxy:
    image: auskento/apache-reverse-proxy:latest
    ports:
      - "80:80"
      - "443:443"
    env_file:
      - .env
    volumes:
      - /mnt/appdata/apache-proxy/letsencrypt:/etc/letsencrypt
      - /mnt/appdata/apache-proxy/logs:/var/log/apache2
    restart: unless-stopped
```

**.env:**
```bash
ACCESS_MODE=public
DOMAIN=myservices.com
EMAIL=admin@myservices.com
TZ=Australia/Sydney
STYLE=modern
DASHBOARD_NAME=Services Dashboard
DASHBOARD_ICON=/icons/apache-reverse-proxy.png
DASHBOARD_LANDING=radarr
DASHBOARD_ORDER=USENET,TORRENTS,CONTENT,SEARCH,MEDIA
AUTHTYPE=basic
BASIC_AUTH_CREDENTIALS=admin:password123
ENABLE_RADARR=true
RADARR_URL=http://radarr:7878
ENABLE_SONARR=true
SONARR_URL=http://sonarr:8989
ENABLE_JELLYFIN=true
JELLYFIN_URL=http://jellyfin:8096
```

---

### Example 6: Different Dashboard Orders

**Custom Media-First Order:**
```yaml
environment:
  DASHBOARD_ORDER: MEDIA,USENET,TORRENTS,CONTENT,SEARCH
```

**Infrastructure-First Order:**
```yaml
environment:
  DASHBOARD_ORDER: CONTENT,SEARCH,USENET,TORRENTS,MEDIA
```

**Downloads-Only Visible First:**
```yaml
environment:
  DASHBOARD_ORDER: DOWNLOADS,MEDIA,INFRA
```

---

### Example 7: Custom Icons from URL

```yaml
environment:
  ENABLE_RADARR: "true"
  RADARR_URL: http://radarr:7878
  ICON_URL_RADARR: https://raw.githubusercontent.com/Radarr/Radarr/develop/Logo/512.png
  
  ENABLE_SONARR: "true"
  SONARR_URL: http://sonarr:8989
  ICON_URL_SONARR: https://raw.githubusercontent.com/Sonarr/Sonarr/develop/Logo/512.png
```

---

### Example 8: Different Dashboard Styles

**Classic Style (Traditional menu):**
```yaml
environment:
  STYLE: classic
```

**Modern Style (React, recommended):**
```yaml
environment:
  STYLE: modern
```

**Sleek Style (Compact sidebar):**
```yaml
environment:
  STYLE: sleek
```

**Minimal Style (Single column):**
```yaml
environment:
  STYLE: minimal
```

---

## Command Line Examples

### Run with Basic Auth
```bash
docker run -d \
  -p 80:80 \
  -p 443:443 \
  -e DOMAIN=example.com \
  -e EMAIL=admin@example.com \
  -e AUTHTYPE=basic \
  -e BASIC_AUTH_CREDENTIALS="user:pass" \
  -e ENABLE_RADARR=true \
  -e RADARR_URL=http://radarr:7878 \
  -v /data/letsencrypt:/etc/letsencrypt \
  -v /data/logs:/var/log/apache2 \
  auskento/apache-reverse-proxy:latest
```

### Run with Google OAuth
```bash
docker run -d \
  -p 80:80 \
  -p 443:443 \
  -e DOMAIN=services.com \
  -e EMAIL=admin@services.com \
  -e AUTHTYPE=google \
  -e GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com \
  -e GOOGLE_CLIENT_SECRET=your-secret \
  -e GOOGLE_REDIRECT_URI=https://services.com \
  -e ENABLE_JELLYFIN=true \
  -e JELLYFIN_URL=http://jellyfin:8096 \
  -v /data/letsencrypt:/etc/letsencrypt \
  -v /data/logs:/var/log/apache2 \
  auskento/apache-reverse-proxy:latest
```

### Run Private/Internal
```bash
docker run -d \
  -p 8080:80 \
  -e ACCESS_MODE=private \
  -e DOMAIN=internal-proxy \
  -e AUTHTYPE=basic \
  -e BASIC_AUTH_CREDENTIALS="user:password" \
  -e STYLE=sleek \
  -e ENABLE_PLEX=true \
  -e PLEX_URL=http://192.168.1.100:32400 \
  -v /data/logs:/var/log/apache2 \
  auskento/apache-reverse-proxy:latest
```

---

## Unraid Installation

### Via Community Applications
1. Search for "Apache Reverse Proxy" in Community Applications
2. Click Install
3. Configure environment variables and volumes
4. Start the container

### Manual Template Installation
1. Navigate to Unraid Dashboard → Docker
2. Add Container → Template URL
3. Enter: `https://raw.githubusercontent.com/auskento/apache-reverse-proxy/main/apache-reverse-proxy.xml`
4. Fill in required fields (DOMAIN, EMAIL, authentication)
5. Configure services
6. Create

---

## Troubleshooting Examples

### Check Logs
```bash
docker logs apache-reverse-proxy
```

### Check Certificate
```bash
docker exec apache-reverse-proxy certbot certificates
```

### Renew Certificates Manually
```bash
docker exec apache-reverse-proxy certbot renew --dry-run
```

### Inspect Configuration
```bash
docker exec apache-reverse-proxy cat /etc/apache2/sites-available/reverse-proxy.conf
```

### Check Service Health
```bash
docker exec apache-reverse-proxy curl -I http://localhost/health
```

---

## Notes

- Always use strong passwords for `BASIC_AUTH_CREDENTIALS`
- Store OAuth secrets securely (use `.env` files not in version control)
- Ensure backend services are accessible from the container network
- For public deployments, ensure ports 80 and 443 are accessible and DOMAIN points to your server
- For private deployments, only ports accessible on local network are needed
- Custom icons must be accessible via HTTP/HTTPS URL
- Dashboard styles can be changed at any time without rebuilding
