# Auto-Download App Icons from URLs

## Overview

The reverse proxy can **automatically download and resize icons from URLs**. Just provide icon links in environment variables, and the system handles everything:

- ✅ Downloads icons at container startup
- ✅ Validates they're real images
- ✅ Resizes to 100x100 pixels automatically
- ✅ Converts to PNG format
- ✅ Shows download status in logs
- ✅ Falls back to colored placeholders if download fails

# Finding Working Icon URLs

## How to Find Icons

Instead of relying on potentially broken sources, here's how to find working icons:

### Method 1: Direct from Official Sources

Search for the service's GitHub repository and look for Logo/icon files:

```bash
# Example: Find Sonarr logo
# Go to: github.com/Sonarr/Sonarr
# Look for: Logo folder or icon files
# Copy the raw GitHub link

# Test if URL works:
curl -I "https://url-to-icon.png"
# Should return: HTTP/1.1 200 OK
```

### Method 2: Docker Hub

Most services have Docker images with documentation containing logo links:

1. Visit hub.docker.com/r/[servicename]
2. Check README for icon/logo links
3. Test the link before using

### Method 3: Local Files

No icon URL working? Place icons manually:

```bash
# Place icon files in html/icons/ directory
cp my-sonarr-icon.png html/icons/sonarr.png
cp my-radarr-icon.png html/icons/radarr.png

# Restart (no icon URLs needed)
docker-compose restart apache-reverse-proxy
```

## Testing Icon URLs

Before adding to docker-compose, test the URL:

```bash
# Test URL is accessible
curl -I "https://your-icon-url.png"

# Should show:
# HTTP/1.1 200 OK
# Content-Type: image/png

# If you see 404 or other errors, URL doesn't work
```

## How to Verify a Working URL

1. Open URL in browser - should display an image
2. Run: `curl -I "https://url"` - should return 200 OK
3. Check Content-Type is `image/*` (png, jpeg, etc)

## If No URLs Work

**That's OK!** The system has a fallback:

```yaml
# Don't set any ICON_URL_* variables
# OR set them to empty strings

ICON_URL_SONARR: ""
ICON_URL_RADARR: ""
```

Menu will display **colored placeholders** instead of photos.  
This works perfectly fine!

## Getting Icons Manually

1. **Download from Docker repository**
   - Find service on Docker Hub
   - Look for icon/logo in README
   - Download and place in `html/icons/`

2. **Create your own**
   - Use Figma, Inkscape, GIMP
   - Save as PNG 256x256+
   - Place in `html/icons/`

3. **Find from Unraid apps** (if available)
   - Search unraid-community-apps repository
   - Download PNG directly
   - Place in `html/icons/`

## Example: Manual Icon Setup

```bash
# Create icons directory
mkdir -p html/icons

# Download icons from your preferred sources
cd html/icons/

# For each service, download an icon
wget "https://source1/sonarr-icon.png" -O sonarr.png
wget "https://source2/radarr-icon.png" -O radarr.png
wget "https://source3/jellyfin-icon.png" -O jellyfin.png

# Verify they exist
ls -lh

# Restart container
docker-compose restart apache-reverse-proxy
```

Dashboard will automatically use the icons!

## Don't Set Icon URLs if They Don't Work

The system works fine without custom icons:

```yaml
environment:
  ENABLE_SONARR: "true"
  ENABLE_RADARR: "true"
  # Don't add ICON_URL_* variables
  # Menu will show colored placeholders - perfectly fine!
```

---

**Bottom line:** The icon feature is optional. Without URLs:
- ✅ Colored placeholders appear in menu
- ✅ Everything works normally
- ✅ No errors or issues
- ✅ You can add icons later by placing files in `html/icons/`


---

## Icon URLs Reference

### Official Icons

**Sonarr**
```yaml
ICON_URL_SONARR: "https://github.com/Sonarr/Sonarr/raw/develop/Logo/256.png"
```

**Radarr**
```yaml
ICON_URL_RADARR: "https://github.com/Radarr/Radarr/raw/develop/Logo/256.png"
```

**Jellyfin**
```yaml
ICON_URL_JELLYFIN: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/jellyfin-icon.png"
```

**Plex**
```yaml
ICON_URL_PLEX: "https://www.plex.tv/downloads/Plex-icon.png"
```

**Transmission**
```yaml
ICON_URL_TRANSMISSION: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/linuxserver.io/img/transmission-icon.png"
```

**qBittorrent**
```yaml
ICON_URL_QBITTORRENT: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/linuxserver.io/img/qbittorrent-icon.png"
```

### Docker Hub Official Images

Most services have official Docker images with logos available:

```yaml
ICON_URL_SONARR: "https://raw.githubusercontent.com/Sonarr/Sonarr/develop/Logo/256.png"
ICON_URL_RADARR: "https://raw.githubusercontent.com/Radarr/Radarr/develop/Logo/256.png"
ICON_URL_JELLYFIN: "https://raw.githubusercontent.com/jellyfin/jellyfin/master/Logo.png"
ICON_URL_LIDARR: "https://raw.githubusercontent.com/Lidarr/Lidarr/develop/Logo/256.png"
ICON_URL_READARR: "https://raw.githubusercontent.com/Readarr/Readarr/develop/Logo/256.png"
ICON_URL_TRANSMISSION: "https://raw.githubusercontent.com/transmission/transmission-web/master/src/images/logo.png"
ICON_URL_QBITTORRENT: "https://raw.githubusercontent.com/qbittorrent/qBittorrent/master/src/gui/resources/icons/app/qbittorrent-tray.png"
```

### Unraid Community Apps (Verified Working)

All services available with high-quality icons:

```yaml
ICON_URL_SONARR: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/sonarr-icon.png"
ICON_URL_RADARR: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/radarr-icon.png"
ICON_URL_WHISPARR: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/whisparr-icon.png"
ICON_URL_JELLYFIN: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/jellyfin-icon.png"
ICON_URL_LIDARR: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/lidarr-icon.png"
ICON_URL_READARR: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/readarr-icon.png"
ICON_URL_PROWLARR: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/prowlarr-icon.png"
ICON_URL_OVERSEERR: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/overseerr-icon.png"
ICON_URL_TAUTULLI: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/tautulli-icon.png"
ICON_URL_TRANSMISSION: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/transmission-icon.png"
ICON_URL_QBITTORRENT: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/qbittorrent-icon.png"
ICON_URL_PLEX: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/plex-icon.png"
ICON_URL_EMBY: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/emby-icon.png"
```

### Unraid Community Apps Collection

Available at:
```
https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/{SERVICE}-icon.png
```

---

## Complete Example Setup

```yaml
# docker-compose.yml
services:
  apache-reverse-proxy:
    image: apache-reverse-proxy:latest
    ports:
      - "80:80"
      - "443:443"
    environment:
      DOMAIN: media.example.com
      EMAIL: admin@example.com
      
      # Services to proxy
      ENABLE_SONARR: "true"
      ENABLE_RADARR: "true"
      ENABLE_JELLYFIN: "true"
      ENABLE_PROWLARR: "true"
      
      # Auto-download icons from URLs
      ICON_URL_SONARR: "https://github.com/Sonarr/Sonarr/raw/develop/Logo/256.png"
      ICON_URL_RADARR: "https://github.com/Radarr/Radarr/raw/develop/Logo/256.png"
      ICON_URL_JELLYFIN: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/jellyfin-icon.png"
      ICON_URL_PROWLARR: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/linuxserver.io/img/prowlarr-icon.png"
    
    volumes:
      - ./letsencrypt:/etc/letsencrypt
      - ./logs:/var/log/apache2
```

When you run `docker-compose up -d`:
1. Icons download from URLs
2. Icons resize to 100x100
3. Icons appear in menu
4. Visit dashboard - see professional logos! 🎨

---

## Checking Download Status

### View Logs

```bash
docker-compose logs apache-reverse-proxy | grep -A 20 "Downloading and Processing"
```

Example output:
```
=== Downloading and Processing App Icons ===

Processing SONARR...
  ✓ Downloaded and resized to 100x100 (4.2K)
Processing RADARR...
  ✓ Downloaded and resized to 100x100 (3.8K)
Processing JELLYFIN...
  ✓ Downloaded and resized to 100x100 (5.1K)

✓ Icon Processing Complete
  Downloaded: 3 / 3
  Status: All icons downloaded successfully! ✓

Icon directory contents:
  /var/www/html/icons/sonarr.png (4.2K)
  /var/www/html/icons/radarr.png (3.8K)
  /var/www/html/icons/jellyfin.png (5.1K)
```

### Check Downloaded Icons

```bash
docker exec apache-reverse-proxy ls -lh /var/www/html/icons/
```

Output:
```
total 13K
-rw-r--r-- 1 root root 4.2K sonarr.png
-rw-r--r-- 1 root root 3.8K radarr.png
-rw-r--r-- 1 root root 5.1K jellyfin.png
```

All resized to exactly 100x100 pixels! ✓

---

## All Available Icon URLs

### Variable Name → Service

```
ICON_URL_SONARR         → Sonarr (TV shows)
ICON_URL_RADARR         → Radarr (Movies)
ICON_URL_WHISPARR       → Whisparr (Adult content)
ICON_URL_LIDARR         → Lidarr (Music)
ICON_URL_READARR        → Readarr (Books)
ICON_URL_PROWLARR       → Prowlarr (Indexer)
ICON_URL_OVERSEERR      → Overseerr (Requests)
ICON_URL_JELLYFIN       → Jellyfin (Streaming)
ICON_URL_EMBY           → Emby (Streaming)
ICON_URL_PLEX           → Plex (Streaming)
ICON_URL_TAUTULLI       → Tautulli (Analytics)
ICON_URL_TRANSMISSION   → Transmission (Torrents)
ICON_URL_QBITTORRENT    → qBittorrent (Torrents)
```

---

## Features

✅ **Automatic Download** - No manual work needed  
✅ **Auto-Resize** - All icons resized to exactly 100x100  
✅ **Format Conversion** - Any format converted to PNG  
✅ **Validation** - Checks files are real images  
✅ **Fallback** - Uses colored placeholders if download fails  
✅ **Status Logging** - Shows what was downloaded  
✅ **No Manual Setup** - Just set URLs and restart  
✅ **Network Friendly** - Downloads only at startup  

---

## Troubleshooting

### Icons Not Downloading

**Problem**: Icon URL provided but icon not appearing in menu

**Check logs:**
```bash
docker-compose logs apache-reverse-proxy | grep -i "icon\|download"
```

**Look for:**
- ❌ "Failed to download from:" - URL is wrong
- ❌ "Not a valid image file" - URL is not an image
- ❌ "Downloaded file is empty" - URL returned nothing

**Solutions:**
1. Test URL in browser - does it show an image?
2. Check URL doesn't require authentication
3. Verify URL is direct link to image file (not HTML page)
4. Try a different icon source

### URL Returns 404

**Problem**: Icon URL gives 404 error

**Solution**: Verify URL is still valid
```bash
curl -I "https://your-icon-url.png"
# Should show: HTTP/1.1 200 OK
```

### Icon URL Requires Authentication

**Problem**: Private icon URL behind login

**Solution**: This is not supported - only public URLs work

**Alternative:** 
1. Download icon manually to `html/icons/`
2. Don't set ICON_URL_* variable
3. Menu uses manual icon file

### Mixed Icons and Placeholders

**Normal and expected!** If you set some ICON_URL_* but not others:

```yaml
ICON_URL_SONARR: "https://..."     # Downloads → uses real icon
ICON_URL_RADARR: ""                # Empty → uses colored placeholder
ICON_URL_JELLYFIN: "https://..."   # Downloads → uses real icon
```

Menu shows: Real Sonarr icon + Colored Radarr box + Real Jellyfin icon ✓

---

## Manual Icon File Fallback

If an icon URL download fails, you can manually place the file:

```bash
# Place icon file in icons directory
cp ~/Downloads/sonarr.png html/icons/sonarr.png

# Restart container
docker-compose restart apache-reverse-proxy

# Menu uses manual file instead
```

---

## Performance

- **Download time** - ~1-5 seconds (depends on internet)
- **Resize time** - <100ms per icon
- **Total startup delay** - Usually <10 seconds
- **File size** - Each icon ~3-5KB after resizing

First startup is slower (downloads icons).  
Subsequent restarts use cached icons (still downloaded but from local volume).

---

## Complete Docker-Compose Example with Icons

```yaml
version: '3.8'

services:
  apache-reverse-proxy:
    image: apache-reverse-proxy:latest
    container_name: apache-reverse-proxy
    restart: unless-stopped
    
    ports:
      - "80:80"
      - "443:443"
    
    environment:
      # Required
      DOMAIN: media.example.com
      EMAIL: admin@example.com
      
      # Services
      ENABLE_SONARR: "true"
      ENABLE_RADARR: "true"
      ENABLE_JELLYFIN: "true"
      ENABLE_PROWLARR: "true"
      ENABLE_OVERSEERR: "true"
      ENABLE_QBITTORRENT: "true"
      ENABLE_TAUTULLI: "true"
      
      # Auto-download icons
      ICON_URL_SONARR: "https://github.com/Sonarr/Sonarr/raw/develop/Logo/256.png"
      ICON_URL_RADARR: "https://github.com/Radarr/Radarr/raw/develop/Logo/256.png"
      ICON_URL_JELLYFIN: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/jellyfin-icon.png"
      ICON_URL_PROWLARR: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/linuxserver.io/img/prowlarr-icon.png"
      ICON_URL_OVERSEERR: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/linuxserver.io/img/overseerr-icon.png"
      ICON_URL_QBITTORRENT: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/linuxserver.io/img/qbittorrent-icon.png"
      ICON_URL_TAUTULLI: "https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/linuxserver.io/img/tautulli-icon.png"
      
      # Optional: Office 365 Auth
      ENABLE_AUTH_OFFICE365: "false"
    
    volumes:
      - ./letsencrypt:/etc/letsencrypt
      - ./logs:/var/log/apache2
      - ./html:/var/www/html

networks:
  default:
    name: media-network
```

Deploy:
```bash
docker-compose up -d
```

Check logs:
```bash
docker-compose logs -f apache-reverse-proxy | grep -i "icon"
```

Visit dashboard:
```
https://media.example.com
```

See professional app logos automatically downloaded and sized! 🎨

---

**Your dashboard now has beautiful professional icons, automatically downloaded and optimized!** ✨
