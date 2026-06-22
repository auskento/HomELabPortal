# Dynamic HTML Dashboard Menu

## Overview

The HTML dashboard menu is **automatically generated based on which services you enable** in `docker-compose.yml`.

- **No manual HTML editing needed** - Just toggle services on/off
- **Menu updates automatically** - Each restart regenerates the menu
- **Only enabled services appear** - Keeps interface clean
- **Dynamic service discovery** - New services can be easily added

## How It Works

### 1. Template System
- **Template file**: `html/index.html.template`
- **Generator script**: `generate-html-menu.sh`
- **Output file**: `html/index.html` (auto-generated, don't edit!)

### 2. Generation Process

At container startup:

```
docker-entrypoint.sh runs
    ↓
docker-entrypoint.sh calls generate-html-menu.sh
    ↓
Script reads ENABLE_* environment variables
    ↓
Script reads template and generates placeholders
    ↓
Dynamic index.html created with only enabled services
    ↓
Apache serves the custom dashboard
```

### 3. Service Menu Items

Each enabled service gets:
- **Colored icon** - Auto-generated SVG with service color
- **Service name** - Links to `/servicename/`
- **Tooltip** - Shows full service name and description
- **Responsive layout** - Wraps on mobile devices

## Enabling/Disabling Services

### Edit docker-compose.yml

```yaml
environment:
  # Services will appear in menu if set to "true"
  ENABLE_SONARR: "true"       # ✓ Will appear
  ENABLE_RADARR: "true"       # ✓ Will appear
  ENABLE_WHISPARR: "false"    # ✗ Will NOT appear
  ENABLE_JELLYFIN: "true"     # ✓ Will appear
  ENABLE_PLEX: "false"        # ✗ Will NOT appear
```

### Restart Container

```bash
# Menu will be regenerated automatically
docker-compose restart apache-reverse-proxy
```

### Check Logs

```bash
# Verify menu was generated
docker-compose logs apache-reverse-proxy | grep "Generated dashboard"
```

Example output:
```
Generating dashboard menu based on enabled services...
✓ Dashboard generated with 5 enabled service(s)
```

## Services Supported

| Service | Enable Variable | Port | Category |
|---------|---|---|---|
| Prowlarr | ENABLE_PROWLARR | 9696 | Indexer Manager |
| Sonarr | ENABLE_SONARR | 8989 | TV Automation |
| Radarr | ENABLE_RADARR | 7878 | Movie Automation |
| Whisparr | ENABLE_WHISPARR | 6969 | Adult Collections |
| Lidarr | ENABLE_LIDARR | 8686 | Music Automation |
| Readarr | ENABLE_READARR | 8787 | Book Automation |
| Overseerr | ENABLE_OVERSEERR | 5055 | Request Manager |
| Jellyfin | ENABLE_JELLYFIN | 8096 | Media Streaming |
| Emby | ENABLE_EMBY | 8096 | Media Streaming |
| Plex | ENABLE_PLEX | 32400 | Media Streaming |
| Tautulli | ENABLE_TAUTULLI | 8181 | Analytics |
| Transmission | ENABLE_TRANSMISSION | 6969 | Torrent Client |
| qBittorrent | ENABLE_QBITTORRENT | 8080 | Torrent Client |

## Quick Examples

### Minimal Setup (Just TV & Movies)
```yaml
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
# All others: "false"
```
Menu shows: 2 icons

### Complete Media Server
```yaml
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
ENABLE_PROWLARR: "true"
ENABLE_OVERSEERR: "true"
ENABLE_JELLYFIN: "true"
ENABLE_QBITTORRENT: "true"
ENABLE_TAUTULLI: "true"
```
Menu shows: 7 service icons

### Only Torrents
```yaml
ENABLE_TRANSMISSION: "true"
ENABLE_QBITTORRENT: "true"
# All others: "false"
```
Menu shows: 2 torrent icons only

## Workflow

### Change Enabled Services

1. **Edit docker-compose.yml**
   ```bash
   vim docker-compose.yml
   # Toggle ENABLE_* variables
   ```

2. **Restart container**
   ```bash
   docker-compose restart apache-reverse-proxy
   ```

3. **Menu regenerates automatically**
   - Script runs on startup
   - Reads enabled services
   - Generates new index.html
   - Apache serves updated dashboard

4. **Verify changes**
   - Visit `https://yourdomain.com`
   - Check if menu icons match your settings

## Service Menu Colors

Each service has a unique color for quick identification:

```
Prowlarr      - #4a9eff (Blue)
Sonarr        - #08a3d4 (Teal)
Radarr        - #65b342 (Green)
Whisparr      - #d45ba0 (Pink)
Lidarr        - #d45b9d (Magenta)
Readarr       - #d48d4c (Orange)
Overseerr     - #00a4dc (Cyan)
Jellyfin      - #00a4dc (Cyan)
Emby          - #9146FF (Purple)
Plex          - #e5a00d (Gold)
Tautulli      - #4a9eff (Blue)
Transmission  - #343434 (Gray)
qBittorrent   - #3683b6 (Blue-Gray)
```

## Customization

### Change Service Colors

Edit `generate-html-menu.sh` and modify the SERVICES array:

```bash
[SONARR]="Sonarr|8989|#FF0000|TV Shows"  # Change color to #FF0000 (red)
```

Then restart:
```bash
docker-compose restart apache-reverse-proxy
```

### Change Menu Height

Edit `html/index.html.template` CSS section:

```css
.header {
    min-height: 140px;  /* Change this value */
}
```

Then restart to regenerate.

### Change Icon Size

Edit `html/index.html.template` CSS:

```css
.menu-item img {
    max-width: 100px;   /* Increase from 80px */
    max-height: 75px;   /* Increase from 60px */
}
```

Then restart.

## Files

| File | Purpose |
|------|---------|
| `html/index.html.template` | Menu template with placeholders |
| `generate-html-menu.sh` | Generator script (reads env vars) |
| `html/index.html` | Generated output (auto-created) |
| `docker-entrypoint.sh` | Calls generator at startup |
| `Dockerfile` | Copies scripts and template |

## Troubleshooting

### Menu Not Updating After Changing Services

**Problem**: Changed ENABLE_* but menu shows old services

**Solution**:
```bash
# Force restart
docker-compose restart apache-reverse-proxy

# Check generation log
docker-compose logs apache-reverse-proxy | grep -i "dashboard\|generating"
```

### Service Icon in Menu But Service Returns 502

**Problem**: Clicked service icon, got "502 Bad Gateway"

**Causes**:
1. Service container not running
2. Service name mismatch in config
3. Service port incorrect
4. Service container not on same Docker network

**Fix**:
```bash
# Verify service is running
docker ps | grep sonarr

# Check Apache logs for details
docker-compose logs apache-reverse-proxy -f
```

### Menu Shows Wrong Service Colors

**Solution**: Edit colors in `generate-html-menu.sh` SERVICES array, then restart.

### Text is Hard to Read on Small Screens

Edit CSS in template:
```css
@media (max-width: 768px) {
    .menu-item .label {
        display: block;  /* Show labels on mobile */
        font-size: 0.7em;
    }
}
```

## Performance

- **Generation time**: <100ms
- **File size**: ~5-10KB
- **Browser load**: <1 second
- **No impact on proxy performance**

## Security

✅ Server-side generation (safe)  
✅ Service paths validated  
✅ SVG icons (no external scripts)  
✅ HTTPS enforced  
✅ No sensitive data exposed  

## Advanced: Add Custom Service

To add a new service to the system:

### 1. Edit generate-html-menu.sh

Add to SERVICES array:
```bash
[MYSERVICE]="My Service|9999|#FF00FF|My Service Description"
```

### 2. Create Service Config

Create `apache-conf/services/myservice.conf`:
```apache
<Location /myservice>
    ProxyPass http://myservice:9999/
    ProxyPassReverse http://myservice:9999/
    ProxyConnectTimeout 30
    ProxyTimeout 300
</Location>
```

### 3. Update Environment

Add to docker-compose.yml:
```yaml
ENABLE_MYSERVICE: "true"
```

### 4. Rebuild

```bash
docker-compose build
docker-compose up -d
```

Menu will automatically include the new service!

---

**The dashboard menu is fully dynamic and automatically reflects your configuration!** 🎨