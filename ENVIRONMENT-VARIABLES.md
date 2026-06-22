# Environment Variables Reference

Complete reference guide for all environment variables supported by the Apache Reverse Proxy.

## Required Variables

These **must** be set for the system to work properly:

### DOMAIN
- **Type:** String
- **Example:** `yourdomain.com`
- **Description:** Your domain name for Let's Encrypt SSL certificate
- **Default:** `example.com` (will fail if not changed)
- **Note:** Must be a valid registered domain with DNS pointing to your server

### EMAIL
- **Type:** String
- **Example:** `admin@example.com`
- **Description:** Email address for Let's Encrypt certificate notifications
- **Default:** `admin@example.com`
- **Note:** You'll receive renewal notifications at this email

---

## Optional Settings

### Timezone
- **Variable:** `TZ`
- **Type:** String
- **Default:** `Australia/Melbourne`
- **Example:** `Australia/Sydney`, `UTC`, `US/Eastern`
- **Description:** Container timezone for logs and cron jobs

### SSL/Security
- **Variable:** `SSL_PROTOCOLS`
- **Type:** String
- **Default:** `all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1`
- **Description:** Allowed SSL/TLS versions

- **Variable:** `SSL_CIPHERS`
- **Type:** String
- **Default:** `HIGH:!aNULL:!MD5`
- **Description:** Allowed SSL cipher suites

---

## Service Configuration (15 Services)

### Enable/Disable Services

For each service, use `ENABLE_*` variables:

```
ENABLE_SONARR=true/false
ENABLE_RADARR=true/false
ENABLE_WHISPARR=true/false
ENABLE_JELLYFIN=true/false
ENABLE_LIDARR=true/false
ENABLE_READARR=true/false
ENABLE_PROWLARR=true/false
ENABLE_OVERSEERR=true/false
ENABLE_EMBY=true/false
ENABLE_PLEX=true/false
ENABLE_TAUTULLI=true/false
ENABLE_TRANSMISSION=true/false
ENABLE_QBITTORRENT=true/false
ENABLE_SABNZBD=true/false
ENABLE_DELUGE=true/false
```

**Type:** Boolean (`true` or `false`)  
**Default:** `false` (all disabled by default)  
**Description:** Enable the service to make it accessible through the proxy

---

### Service Backend URLs

For each enabled service, specify the backend address:

```
SONARR_URL=http://sonarr:8989
RADARR_URL=http://radarr:7878
WHISPARR_URL=http://whisparr:6969
JELLYFIN_URL=http://jellyfin:8096
LIDARR_URL=http://lidarr:8686
READARR_URL=http://readarr:8787
PROWLARR_URL=http://prowlarr:9696
OVERSEERR_URL=http://overseerr:5055
EMBY_URL=http://emby:8096
PLEX_URL=http://plex:32400
TAUTULLI_URL=http://tautulli:8181
TRANSMISSION_URL=http://transmission:6969
QBITTORRENT_URL=http://qbittorrent:8080
SABNZBD_URL=http://sabnzbd:8080
DELUGE_URL=http://deluge:8112
```

**Type:** URL  
**Default:** Docker container name URLs (e.g., `http://sonarr:8989`)  
**Examples:**
- Local IP: `http://192.168.1.100:8989`
- Hostname: `http://sonarr.local:8989`
- Docker container: `http://sonarr:8989`

---

### Service Icon URLs

Customize icons for each service:

```
ICON_URL_SONARR=
ICON_URL_RADARR=
ICON_URL_WHISPARR=
ICON_URL_JELLYFIN=
ICON_URL_LIDARR=
ICON_URL_READARR=
ICON_URL_PROWLARR=
ICON_URL_OVERSEERR=
ICON_URL_EMBY=
ICON_URL_PLEX=
ICON_URL_TAUTULLI=
ICON_URL_TRANSMISSION=
ICON_URL_QBITTORRENT=
ICON_URL_SABNZBD=
ICON_URL_DELUGE=
```

**Type:** URL  
**Default:** Empty (uses bundled icons)  
**Examples:**
- `https://example.com/my-sonarr-icon.png`
- `https://github.com/Sonarr/Sonarr/raw/develop/Logo/256.png`

**Smart System:**
1. If custom URL provided → Downloads and uses it
2. If custom URL fails → Falls back to bundled PNG
3. If no custom URL → Uses bundled PNG default
4. If no PNG available → Generates SVG placeholder

---

## Office 365 / Azure AD Authentication (Optional)

### Enable/Disable
- **Variable:** `ENABLE_AUTH_OFFICE365`
- **Type:** Boolean (`true` or `false`)
- **Default:** `false`
- **Description:** Enable Office 365 authentication

### Configuration
- **Variable:** `OAUTH2_CLIENT_ID`
- **Type:** String
- **Description:** Azure AD Application Client ID
- **Required if:** `ENABLE_AUTH_OFFICE365=true`

- **Variable:** `OAUTH2_CLIENT_SECRET`
- **Type:** String
- **Description:** Azure AD Application Client Secret
- **Required if:** `ENABLE_AUTH_OFFICE365=true`
- **Security:** Keep this secret!

- **Variable:** `OAUTH2_REDIRECT_URI`
- **Type:** URL
- **Default:** `https://yourdomain.com/oauth2callback`
- **Description:** OAuth2 callback URL (must match Azure AD config)

- **Variable:** `OAUTH2_ALLOWED_DOMAINS`
- **Type:** String (comma-separated)
- **Default:** `example.com`
- **Example:** `company.com,partner.com`
- **Description:** Email domains allowed to authenticate

- **Variable:** `OAUTH2_CRYPTO_PASSPHRASE`
- **Type:** String
- **Default:** Auto-generated if empty
- **Description:** Session encryption passphrase (for security)

---

## Complete Example Configuration

### docker-compose.yml
```yaml
environment:
  # Required - MUST SET THESE!
  DOMAIN: yourdomain.com
  EMAIL: admin@yourdomain.com
  
  # Optional - Timezone
  TZ: Australia/Melbourne
  
  # Enable services you want
  ENABLE_SONARR: "true"
  ENABLE_RADARR: "true"
  ENABLE_JELLYFIN: "true"
  ENABLE_PLEX: "false"
  
  # Set backend URLs for enabled services
  SONARR_URL: http://sonarr:8989
  RADARR_URL: http://radarr:7878
  JELLYFIN_URL: http://jellyfin:8096
  
  # Optional custom icons (leave empty to use defaults)
  ICON_URL_SONARR: ""
  ICON_URL_RADARR: https://example.com/my-radarr-icon.png
  ICON_URL_JELLYFIN: ""
```

### .env File
```bash
# Required
DOMAIN=yourdomain.com
EMAIL=admin@yourdomain.com

# Timezone
TZ=Australia/Melbourne

# Services
ENABLE_SONARR=true
SONARR_URL=http://sonarr:8989

ENABLE_RADARR=true
RADARR_URL=http://radarr:7878

# Icons (optional)
ICON_URL_SONARR=
ICON_URL_RADARR=https://example.com/radarr.png
```

---

## Environment Variable Validation

The system will verify:
- ✅ `DOMAIN` is not `example.com`
- ✅ `EMAIL` is a valid email format
- ✅ `TZ` is a valid timezone (if provided)
- ✅ `ENABLE_*` are boolean (`true` or `false`)
- ✅ `*_URL` are valid URLs (if provided)
- ✅ `ICON_URL_*` are valid URLs (if provided)

If validation fails, check the container logs:
```bash
docker-compose logs apache-reverse-proxy
```

---

## Setting Variables

### Method 1: docker-compose.yml
Edit the `environment:` section directly

### Method 2: .env File
Create a `.env` file in the project directory:
```bash
cp .env.example .env
# Edit .env with your values
```

### Method 3: Command Line
```bash
docker run \
  -e DOMAIN=yourdomain.com \
  -e EMAIL=admin@yourdomain.com \
  -e ENABLE_SONARR=true \
  auskento/apache-reverse-proxy:latest
```

### Method 4: Unraid Template
Fill in the form fields in Unraid UI (variables are passed automatically)

---

## Troubleshooting

### Variables Not Being Used
1. Check that you've restarted the container
2. Verify variables are in the correct `environment:` section
3. Check container logs: `docker-compose logs apache-reverse-proxy`
4. Look for `Domain: yourdomain.com` in startup output

### Wrong Domain Still Being Used
- Ensure `DOMAIN` is set to your actual domain
- Remove old containers: `docker-compose down`
- Rebuild: `docker-compose up -d`

### Services Not Proxying
- Check `ENABLE_*` variable is set to `true`
- Check `*_URL` variable is correct
- Verify backend service is running and accessible
- Check logs for errors

---

**For more help, see TROUBLESHOOTING.md**
