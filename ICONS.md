# Adding Custom App Icons

## Overview

The dashboard supports **custom icons for each service**. You can use:
- Official app logos
- Fan-made icons
- Custom designs
- Or auto-generated colored placeholders (default)

## How It Works

The system checks for icon files in this order:

1. **Custom PNG** - `html/icons/servicename.png`
2. **Custom JPG** - `html/icons/servicename.jpg`
3. **Custom SVG** - `html/icons/servicename.svg`
4. **Fallback** - Auto-generated colored SVG

If a custom icon exists, it's used. Otherwise, a colored placeholder is auto-generated.

## Quick Start: Add Icons

### Step 1: Find Icons

Download icons for your services (see sources below).

### Step 2: Place Icons

Put icons in the `html/icons/` directory:

```
html/icons/
├── sonarr.png          # Icon for Sonarr
├── radarr.png          # Icon for Radarr
├── jellyfin.png        # Icon for Jellyfin
├── prowlarr.png        # Icon for Prowlarr
├── bazarr.png          # Icon for Bazarr
├── radarr.jpg          # JPG also works
└── plex.svg            # SVG also works
```

### Step 3: Restart

```bash
docker-compose restart apache-reverse-proxy
```

Icons are now displayed in the menu!

## Icon Naming Convention

Each service has a specific filename pattern. Use **lowercase** service names:

| Service | Icon Filename |
|---------|---|
| Sonarr | `sonarr.png` or `sonarr.jpg` or `sonarr.svg` |
| Radarr | `radarr.png` or `radarr.jpg` or `radarr.svg` |
| Whisparr | `whisparr.png` or `whisparr.jpg` or `whisparr.svg` |
| Lidarr | `lidarr.png` or `lidarr.jpg` or `lidarr.svg` |
| Prowlarr | `prowlarr.png` or `prowlarr.jpg` or `prowlarr.svg` |
| Seerr | `seerr.png` or `seerr.jpg` or `seerr.svg` |
| Bazarr | `bazarr.png` or `bazarr.jpg` or `bazarr.svg` |
| Jellyfin | `jellyfin.png` or `jellyfin.jpg` or `jellyfin.svg` |
| Emby | `emby.png` or `emby.jpg` or `emby.svg` |
| Plex | `plex.png` or `plex.jpg` or `plex.svg` |
| Tautulli | `tautulli.png` or `tautulli.jpg` or `tautulli.svg` |
| SABnzbd | `sabnzbd.png` or `sabnzbd.jpg` or `sabnzbd.svg` |
| NZBGet | `nzbget.png` or `nzbget.jpg` or `nzbget.svg` |
| NZBHydra | `nzbhydra.png` or `nzbhydra.jpg` or `nzbhydra.svg` |
| Transmission | `transmission.png` or `transmission.jpg` or `transmission.svg` |
| qBittorrent | `qbittorrent.png` or `qbittorrent.jpg` or `qbittorrent.svg` |
| Deluge | `deluge.png` or `deluge.jpg` or `deluge.svg` |

## Icon Sources

### Official/Recommended

**Sonarr** - https://github.com/Sonarr/Sonarr/raw/develop/Logo/256.png  
**Radarr** - https://github.com/Radarr/Radarr/raw/develop/Logo/256.png  
**Jellyfin** - https://github.com/jellyfin/jellyfin/raw/master/Logo.png  
**Plex** - https://www.plex.tv/ (brand guidelines)  
**Transmission** - https://transmissionbt.com/ (download page)  
**qBittorrent** - https://www.qbittorrent.org/ (logo page)  

### Community Packs

**Linuxserver Logos** - https://github.com/linuxserver/docker-templates/tree/master/linuxserver.io/img/  
Great collection of service logos in 256x256 PNG format.

**Unraid Community Apps** - https://github.com/selfhosted/unraid-community-apps/tree/master/source/community/  
Unraid app icons (many are excellent quality).

**Docker Hub Logos** - Search for "[service name] docker" on Docker Hub, usually has logos in README.

### Create Your Own

**Tools for custom icons:**
- Figma (free) - https://figma.com
- Inkscape (free) - https://inkscape.org
- Photoshop - https://adobe.com
- GIMP (free) - https://gimp.org
- Canva (free) - https://canva.com

## Icon Specifications

### Recommended Size
- **256x256 pixels** - Works well at any scale
- **Minimum: 64x64** - Will look pixelated if smaller
- **Maximum: 512x512** - No need to be larger

### Recommended Format
- **PNG** - Best for logos (transparency support)
- **JPG** - OK for photos/complex images
- **SVG** - Best for scalable graphics (no pixelation)

### Tips
- ✅ Transparent background (PNG)
- ✅ Clean, simple design
- ✅ High contrast (visible on dark background)
- ✅ Square aspect ratio (1:1)
- ❌ Don't use gradients (may look blurry)
- ❌ Don't use very thin lines (may disappear)

## Examples

### Using Official Icons

**Download Sonarr logo:**
```bash
cd html/icons/
curl -o sonarr.png https://github.com/Sonarr/Sonarr/raw/develop/Logo/256.png
```

**Download from Linuxserver:**
```bash
curl -o radarr.png https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/radarr-icon.png
```

**Download from Unraid:**
```bash
curl -o jellyfin.png https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/jellyfin-icon.png
```

### Using Multiple Formats

You can use PNG, JPG, and SVG together:

```bash
html/icons/
├── sonarr.png          # Official PNG
├── radarr.svg          # Official SVG
└── jellyfin.jpg        # Custom JPG
```

Each service will use whatever format you provide.

## Viewing Icon Status

When the container starts, it shows which icons are being used:

```bash
docker-compose logs apache-reverse-proxy | grep -A 20 "Icon Status"
```

Output example:
```
Icon Status:
  SONARR: ✓ PNG icon found
  RADARR: ✓ PNG icon found
  JELLYFIN: ❌ Using generated SVG
  PLEX: ✓ PNG icon found
```

Green checkmark = custom icon found  
Red X = using auto-generated placeholder

## Installation Methods

### Method 1: Manual Download (Easiest)

1. Download icons to your computer
2. Place in `html/icons/` directory
3. Restart container

### Method 2: Docker Copy

```bash
# Copy icon file into running container
docker cp my-icon.png apache-reverse-proxy:/var/www/html/icons/sonarr.png

# Restart to regenerate menu
docker-compose restart apache-reverse-proxy
```

### Method 3: Volume Mount

```yaml
volumes:
  - ./html:/var/www/html
```

Then edit icons directly on your host:
```bash
cp ~/Downloads/sonarr.png html/icons/
docker-compose restart apache-reverse-proxy
```

### Method 4: Via Docker Build

Create a Dockerfile with icons:

```dockerfile
FROM apache-reverse-proxy:latest

# Copy custom icons
COPY icons/ /var/www/html/icons/
```

Build and run:
```bash
docker build -t apache-reverse-proxy:custom .
docker-compose up -d
```

## Customizing Icons After Deployment

### Add Icons to Running Container

```bash
# Copy icon into container
docker cp sonarr.png apache-reverse-proxy:/var/www/html/icons/

# Restart container (menu regenerates)
docker-compose restart apache-reverse-proxy
```

### Replace Existing Icons

```bash
# Copy new version
docker cp new-radarr.png apache-reverse-proxy:/var/www/html/icons/radarr.png

# Restart
docker-compose restart apache-reverse-proxy
```

### Remove Icon (Fall Back to SVG)

```bash
# Delete icon file
docker exec apache-reverse-proxy rm /var/www/html/icons/jellyfin.png

# Restart (will use generated SVG)
docker-compose restart apache-reverse-proxy
```

## Troubleshooting

### Icons Not Showing

**Check icon existence:**
```bash
docker exec apache-reverse-proxy ls -la /var/www/html/icons/
```

**Check icon status in logs:**
```bash
docker-compose logs apache-reverse-proxy | grep "Icon Status" -A 20
```

**Verify permissions:**
```bash
docker exec apache-reverse-proxy stat /var/www/html/icons/sonarr.png
# Should show readable by www-data user
```

### Icons Look Blurry

- Icons are too small (less than 64x64)
- Use PNG or SVG instead of JPG
- Check that icon format is supported

**Fix:** Download or create larger icons (256x256 or larger).

### Icon File Not Found

**Problem:** Icon file exists but isn't showing

**Causes:**
1. Wrong filename (must be lowercase)
2. Wrong directory (`html/icons/` not `html/` or elsewhere)
3. Wrong format (must be .png, .jpg, or .svg)
4. File permissions (must be readable by www-data)

**Solution:**
```bash
# Verify file location and name
docker exec apache-reverse-proxy ls -la /var/www/html/icons/

# Fix permissions if needed
docker exec apache-reverse-proxy chmod 644 /var/www/html/icons/*.png

# Restart
docker-compose restart apache-reverse-proxy
```

### Mixed Icons and SVG Placeholders

This is normal! You can have:
- Sonarr: PNG icon
- Radarr: PNG icon
- Jellyfin: Generated SVG (no icon provided)
- Plex: PNG icon

All coexist perfectly.

## Icon Collections You Can Use

### Pre-packaged Collections

**1. Linuxserver** (Recommended)
- Download: https://github.com/linuxserver/docker-templates/archive/master.zip
- Path: `/linuxserver.io/img/`
- Format: PNG 256x256
- Quality: Excellent

**2. Unraid Community Apps**
- Download: https://github.com/selfhosted/unraid-community-apps/archive/master.zip
- Path: `/source/community/img/`
- Format: PNG 256x256
- Quality: Very good

**3. CloudBox**
- Download: https://github.com/cloudbox/cloudbox/archive/master.zip
- Path: `/roles/*/defaults/`
- Format: PNG various sizes
- Quality: Good

### Downloading Pre-packaged Collections

```bash
# Download Linuxserver pack
cd html/icons/
wget https://github.com/linuxserver/docker-templates/raw/master/linuxserver.io/img/sonarr-icon.png
wget https://github.com/linuxserver/docker-templates/raw/master/linuxserver.io/img/radarr-icon.png
wget https://github.com/linuxserver/docker-templates/raw/master/linuxserver.io/img/jellyfin-icon.png
# ... and more
```

## FAQ

**Q: Do I have to use custom icons?**
A: No! Auto-generated SVG placeholders work fine. Custom icons are optional for better appearance.

**Q: Can I mix custom and auto-generated icons?**
A: Yes! Any service without a custom icon will use the colored placeholder.

**Q: What if I add icons after deployment?**
A: Restart the container - menu regenerates automatically and will use new icons.

**Q: Can I use different formats for different services?**
A: Yes! Use PNG for some, JPG for others, SVG for others - all supported.

**Q: Are icons cached?**
A: Icons are served directly from disk, no caching. Changes appear after refresh.

**Q: What size should icons be?**
A: 256x256 is ideal, but any size from 64x64 to 512x512 works well.

**Q: Can I use animated GIFs?**
A: Technically yes, but it's not recommended (uses more resources, can be distracting).

## Complete Example

### Setup with Icons

```bash
# 1. Create icons directory (if not exists)
mkdir -p html/icons

# 2. Download icons
cd html/icons/
curl -o sonarr.png https://github.com/Sonarr/Sonarr/raw/develop/Logo/256.png
curl -o radarr.png https://github.com/Radarr/Radarr/raw/develop/Logo/256.png
curl -o jellyfin.png https://raw.githubusercontent.com/selfhosted/unraid-community-apps/master/source/community/img/jellyfin-icon.png
curl -o plex.png https://plex.tv/downloads/Plex-icon.png

# 3. Verify files
ls -la

# 4. Start container
cd ../..
docker-compose up -d

# 5. Check logs
docker-compose logs apache-reverse-proxy | grep "Icon Status" -A 20
```

Expected output:
```
Icon Status:
  SONARR: ✓ PNG icon found
  RADARR: ✓ PNG icon found
  JELLYFIN: ✓ PNG icon found
  PLEX: ✓ PNG icon found
```

Then visit `https://yourdomain.com` and see your custom icons in the menu!

---

**Your dashboard menu now supports professional app icons!** 🎨✨
