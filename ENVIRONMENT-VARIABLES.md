# Environment Variables Reference

Complete reference guide for all environment variables supported by the Apache Reverse Proxy.

## Deployment Mode

### ACCESS_MODE
- **Type:** String (public or private)
- **Default:** `public`
- **Description:** Deployment mode that determines certificate generation and feature availability
- **Options:**
  - `public`: Internet-facing deployment with Let's Encrypt HTTPS (requires DOMAIN and EMAIL)
  - `private`: Internal-only deployment without certificates (DOMAIN/EMAIL still in config but not used)
- **Note:** In private mode, only `none` or `basic` authentication types are supported

## Required Variables (Public Mode Only)

For `ACCESS_MODE=public`, these **must** be set:

### DOMAIN
- **Type:** String
- **Example:** `yourdomain.com`
- **Description:** Your domain name for Let's Encrypt SSL certificate
- **Default:** `example.com`
- **Note:** Must be a valid registered domain with DNS pointing to your server
- **Required for:** `ACCESS_MODE=public` only

### EMAIL
- **Type:** String
- **Example:** `admin@example.com`
- **Description:** Email address for Let's Encrypt certificate notifications
- **Default:** `admin@example.com`
- **Note:** You'll receive renewal notifications at this email
- **Required for:** `ACCESS_MODE=public` only

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

### Dashboard Customization
- **Variable:** `STYLE`
- **Type:** String (classic, modern, sleek, or minimal)
- **Default:** `modern`
- **Description:** Dashboard visual style
- **Options:**
  - `classic`: Original sidebar menu layout
  - `modern`: React-based UI with full features (recommended)
  - `sleek`: Compact sidebar with gradient styling
  - `minimal`: Minimal single-column design

- **Variable:** `DASHBOARD_NAME`
- **Type:** String
- **Default:** `Media Server`
- **Description:** Display name shown in dashboard header and page title
- **Example:** `My Homelab`, `Family Media`, `Media Center`

- **Variable:** `DASHBOARD_ICON`
- **Type:** URL path
- **Default:** `/icons/homelabportal.png`
- **Description:** Icon displayed in dashboard header (relative path or full URL)
- **Examples:** `/icons/my-logo.png`, `https://example.com/logo.png`
- **Note:** Place custom icon files in the `html/icons/` directory

- **Variable:** `DASHBOARD_LANDING`
- **Type:** String (service path or empty)
- **Default:** Empty (shows welcome screen)
- **Description:** Default page to load in dashboard iframe on startup
- **Examples:** `sonarr/calendar`, `radarr`, `plex/web`
- **Note:** Only used in modern, sleek, and minimal dashboard styles

- **Variable:** `DASHBOARD_ORDER`
- **Type:** String (comma-separated group names)
- **Default:** `CONTENT,SEARCH,USENET,TORRENTS,MEDIA`
- **Description:** Order of service category groups in dashboard
- **Service Groups:**
  - `CONTENT`: Sonarr, Radarr, Lidarr, Whisparr
  - `SEARCH`: Seerr, Prowlarr, Bazarr
  - `USENET`: SABnzbd, NZBGet, NZBHydra
  - `TORRENTS`: Deluge, Transmission, qBittorrent
  - `MEDIA`: Emby, Plex, Jellyfin, Tautulli
- **Examples:** 
  - `CONTENT,SEARCH,USENET,TORRENTS,MEDIA` (default order)
  - `MEDIA,CONTENT,USENET,TORRENTS,SEARCH` (Media servers first)
  - `USENET,TORRENTS,CONTENT,SEARCH,MEDIA` (Downloads first)
- **Valid Groups:** `CONTENT`, `SEARCH`, `USENET`, `TORRENTS`, `MEDIA` (case-insensitive)
- **Note:** Group names must be comma-separated with no extra spaces. Applies to all dashboard styles (modern, sleek, minimal, classic).

### Authentication
- **Variable:** `AUTHTYPE`
- **Type:** String (none, basic, entra, or google)
- **Default:** `none`
- **Description:** Authentication method for dashboard access
- **Options:**
  - `none`: No authentication required
  - `basic`: Simple username/password authentication
  - `entra`: Microsoft Entra ID (Azure AD) OAuth
  - `google`: Google OAuth2
- **Note:** In private deployments (SKIP_CERT_GENERATION=true), only `none` and `basic` are supported

---

## Service Configuration (16 Services)

### Enable/Disable Services

For each service, use `ENABLE_*` variables (grouped by DASHBOARD_ORDER category):

**USENET Category:**
```
ENABLE_SABNZBD=true/false
ENABLE_NZBGET=true/false
ENABLE_NZBHYDRA=true/false
```

**TORRENTS Category:**
```
ENABLE_DELUGE=true/false
ENABLE_TRANSMISSION=true/false
ENABLE_QBITTORRENT=true/false
```

**CONTENT Category:**
```
ENABLE_SONARR=true/false
ENABLE_RADARR=true/false
ENABLE_LIDARR=true/false
ENABLE_WHISPARR=true/false
```

**SEARCH Category:**
```
ENABLE_SEERR=true/false
ENABLE_PROWLARR=true/false
ENABLE_BAZARR=true/false
```

**MEDIA Category:**
```
ENABLE_EMBY=true/false
ENABLE_PLEX=true/false
ENABLE_JELLYFIN=true/false
ENABLE_TAUTULLI=true/false
```

**Type:** Boolean (`true` or `false`)  
**Default:** `false` (all disabled by default)  
**Description:** Enable the service to make it accessible through the proxy

---

### Service Backend URLs

For each enabled service, specify the backend address (grouped by category):

**USENET Category:**
```
SABNZBD_URL=http://sabnzbd:8080
NZBGET_URL=http://nzbget:6789
NZBHYDRA_URL=http://nzbhydra:5076
```

**TORRENTS Category:**
```
DELUGE_URL=http://deluge:8112
TRANSMISSION_URL=http://transmission:6969
QBITTORRENT_URL=http://qbittorrent:8080
```

**CONTENT Category:**
```
SONARR_URL=http://sonarr:8989
RADARR_URL=http://radarr:7878
LIDARR_URL=http://lidarr:8686
WHISPARR_URL=http://whisparr:6969
```

**SEARCH Category:**
```
SEERR_URL=http://seerr:5055
PROWLARR_URL=http://prowlarr:9696
BAZARR_URL=http://bazarr:6767
```

**MEDIA Category:**
```
EMBY_URL=http://emby:8096
PLEX_URL=http://plex:32400
JELLYFIN_URL=http://jellyfin:8096
TAUTULLI_URL=http://tautulli:8181
```

**Type:** URL  
**Default:** Docker container name URLs (e.g., `http://sonarr:8989`)  
**Examples:**
- Local IP: `http://192.168.1.100:8989`
- Hostname: `http://sonarr.local:8989`
- Docker container: `http://sonarr:8989`

---

### Service Icon URLs

Customize icons for each service (grouped by category):

**USENET Category:**
```
ICON_URL_SABNZBD=
ICON_URL_NZBGET=
ICON_URL_NZBHYDRA=
```

**TORRENTS Category:**
```
ICON_URL_DELUGE=
ICON_URL_TRANSMISSION=
ICON_URL_QBITTORRENT=
```

**CONTENT Category:**
```
ICON_URL_SONARR=
ICON_URL_RADARR=
ICON_URL_LIDARR=
ICON_URL_WHISPARR=
```

**SEARCH Category:**
```
ICON_URL_SEERR=
ICON_URL_PROWLARR=
ICON_URL_BAZARR=
```

**MEDIA Category:**
```
ICON_URL_EMBY=
ICON_URL_PLEX=
ICON_URL_JELLYFIN=
ICON_URL_TAUTULLI=
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

## Google OAuth Configuration

### Important: Redirect URI Matching
The `GOOGLE_REDIRECT_URI` **must exactly match** the authorized redirect URI configured in your Google Cloud Console OAuth 2.0 credentials. If they don't match, you'll get an `Error 400: redirect_uri_mismatch`.

**Steps:**
1. Go to Google Cloud Console → Credentials → Your OAuth 2.0 Client ID
2. Find "Authorized redirect URIs" section
3. Note the exact URI (with any path included)
4. Set `GOOGLE_REDIRECT_URI` to match that exactly

**Examples:**
- If Google has: `https://example.com` → Use `GOOGLE_REDIRECT_URI=https://example.com`
- If Google has: `https://example.com/oauth2callback` → Use `GOOGLE_REDIRECT_URI=https://example.com/oauth2callback`

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

### docker-compose.yml (Public Deployment)
```yaml
environment:
  # Deployment mode
  ACCESS_MODE: public
  
  # Required for Let's Encrypt HTTPS (public mode only)
  DOMAIN: yourdomain.com
  EMAIL: admin@yourdomain.com
  
  # Optional - Timezone and dashboard customization
  TZ: Australia/Melbourne
  STYLE: modern
  DASHBOARD_NAME: My Homelab
  DASHBOARD_ICON: /icons/homelabportal.png
  DASHBOARD_LANDING: sonarr/calendar
  
  # Authentication
  AUTHTYPE: basic
  BASIC_AUTH_CREDENTIALS: "user1:password1|user2:password2"
  
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

### docker-compose.yml (Private/Internal Deployment)
```yaml
environment:
  # Deployment mode - private disables certificate generation
  ACCESS_MODE: private
  
  # DOMAIN and EMAIL required in config but not used for certificates
  DOMAIN: internal-proxy
  EMAIL: admin@local
  
  # Dashboard customization
  TZ: Australia/Melbourne
  STYLE: modern
  DASHBOARD_NAME: Family Media
  DASHBOARD_ICON: /icons/homelabportal.png
  DASHBOARD_LANDING: ""
  
  # Authentication - only none or basic allowed in private mode
  AUTHTYPE: basic
  BASIC_AUTH_CREDENTIALS: "user1:password1"
  
  # Services enabled (same as public mode)
  ENABLE_SONARR: "true"
  SONARR_URL: http://sonarr:8989
  ENABLE_RADARR: "true"
  RADARR_URL: http://radarr:7878
```

### .env File
```bash
# Deployment mode (public or private)
ACCESS_MODE=public

# Required for public deployments
DOMAIN=yourdomain.com
EMAIL=admin@yourdomain.com

# Timezone
TZ=Australia/Melbourne

# Dashboard customization
STYLE=modern
DASHBOARD_NAME=My Homelab
DASHBOARD_ICON=/icons/homelabportal.png
DASHBOARD_LANDING=sonarr/calendar

# Authentication
AUTHTYPE=basic
BASIC_AUTH_CREDENTIALS=user1:password1|user2:password2

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
