# HomELabPortal (HeLP) - What's New in v2.1

## ✨ Major Updates

### 1. Bazarr - Subtitle Management ⭐
Automatic subtitle downloads for your media library!

**Quick Enable:**
```yaml
ENABLE_BAZARR: "true"
BAZARR_URL: "http://bazarr:6767"
```

**Access at:** `https://yourdomain.com/bazarr`

**Features:**
- Automatic subtitle downloads
- Multiple language support
- Integration with Sonarr and Radarr
- Web-based interface

---

### 2. Service Reorganization
Services are now organized into 5 clear categories:

- **CONTENT** - Sonarr, Radarr, Lidarr, Whisparr
- **SEARCH** - Seerr, Prowlarr, Bazarr ⭐ NEW!
- **USENET** - SABnzbd, NZBGet, NZBHydra
- **TORRENTS** - Transmission, qBittorrent, Deluge
- **MEDIA** - Jellyfin, Emby, Plex, Tautulli

**Customize order:**
```yaml
DASHBOARD_ORDER: MEDIA,CONTENT,SEARCH,USENET,TORRENTS
```

---

### 3. Enhanced NZBGet Support
NZBGet authentication is now fully supported!

**With Authentication:**
```yaml
ENABLE_NZBGET: "true"
NZBGET_URL: "http://nzbget:6789"
NZBGET_USER: "your_username"
NZBGET_PASS: "your_password"
```

The proxy automatically:
- Encodes credentials in Base64
- Injects authentication header
- Passes through to NZBGet backend

---

### 4. Dashboard Improvements

#### Multiple Themes
Choose your preferred dashboard style:
- **modern** - React-based with full features (recommended)
- **classic** - Original sidebar layout
- **sleek** - Compact with gradient styling
- **minimal** - Single-column design

**Set theme:**
```yaml
STYLE: modern
```

#### Custom Dashboard Names
```yaml
DASHBOARD_NAME: "My Homelab"
DASHBOARD_ICON: "/icons/apache-reverse-proxy.png"
```

#### Custom Landing Pages
Set which service loads on startup:
```yaml
DASHBOARD_LANDING: "sonarr/calendar"
```

---

### 5. Updated Variable Naming
For consistency, variables were renamed:

| Old Name | New Name |
|----------|----------|
| `LANDING` | `DASHBOARD_LANDING` |
| `DASH_ORDER` | `DASHBOARD_ORDER` |

Update your `.env` file to use new names.

---

## 🔧 Files Updated

### Configuration Scripts
- ✅ `docker-entrypoint.sh` - Added Bazarr, reorganized variables
- ✅ `generate-config.sh` - NZBGet auth support, Bazarr service
- ✅ `generate-html-menu.sh` - New category structure, Bazarr integration
- ✅ `.env.example` - All 17 services, organized by category

### Apache Configuration
- ✅ `apache-conf/services/bazarr.conf` - NEW! Bazarr proxy config
- ✅ `apache-conf/reverse-proxy.conf.template` - Updated placeholders
- ✅ Updated all service configs with proper Location blocks

### Unraid Template
- ✅ `apache-reverse-proxy.xml` - Updated service list, new variables

### Documentation
- ✅ `ENVIRONMENT-VARIABLES.md` - Reorganized by category
- ✅ `SERVICES.md` - Added Bazarr, updated Seerr (was Overseerr)
- ✅ `SERVICE-URLS.md` - All 17 services documented
- ✅ `ICON-URLS.md` - Complete icon reference
- ✅ `ICONS.md` - Icon naming conventions
- ✅ `QUICKSTART-SERVICES.md` - Updated examples with Bazarr
- ✅ `COMPLETE-FEATURES.md` - Rewritten for v2.1

---

## 📊 Version Comparison

| Feature | v2.0 | v2.1 |
|---------|------|------|
| Services | 15 | 17 ⭐ |
| Categories | 3 | 5 ⭐ |
| Dashboard Themes | 1 | 4 ⭐ |
| Authentication Methods | 1 | 4 ⭐ |
| Custom Ordering | No | Yes ⭐ |
| NZBGet Auth | No | Yes ⭐ |
| Subtitle Management | No | Yes (Bazarr) ⭐ |

---

## 🚀 Quick Update Path

### If you're on v2.0.0

1. **Update your environment variables:**
   - Rename `LANDING` → `DASHBOARD_LANDING`
   - Rename `DASH_ORDER` → `DASHBOARD_ORDER`

2. **Add new services (optional):**
   ```yaml
   ENABLE_BAZARR: "true"
   BAZARR_URL: "http://bazarr:6767"
   ```

3. **Rebuild and restart:**
   ```bash
   docker-compose build
   docker-compose up -d
   ```

4. **Verify:**
   - Check dashboard loads: `https://yourdomain.com`
   - Test Bazarr: `https://yourdomain.com/bazarr`

---

## 💡 New Features Explained

### Bazarr Subtitle Management
Perfect for automating subtitle downloads:
```bash
# Automatically download subtitles for Sonarr/Radarr content
# Supports 60+ languages
# Works with most common subtitle providers
```

### Service Category Ordering
Reorder service groups without code changes:
```yaml
# Default order
DASHBOARD_ORDER: CONTENT,SEARCH,USENET,TORRENTS,MEDIA

# Or put media servers first
DASHBOARD_ORDER: MEDIA,CONTENT,SEARCH,USENET,TORRENTS

# Or downloads first
DASHBOARD_ORDER: USENET,TORRENTS,CONTENT,SEARCH,MEDIA
```

### Theme Selection
```yaml
STYLE: modern      # React-based, feature-rich
STYLE: classic     # Original sidebar layout
STYLE: sleek       # Compact with styling
STYLE: minimal     # Simple single-column
```

### NZBGet Authentication
If your NZBGet requires credentials:
```yaml
NZBGET_USER: "nzbget"
NZBGET_PASS: "your_secure_password"
# Proxy automatically authenticates requests
```

---

## 🔐 Security Notes

✅ All updates maintain security standards:
- HTTPS enforcement (Let's Encrypt)
- Secure credential handling (Base64 encoding)
- Proper authentication header injection
- No exposed service ports

---

## 📖 Next Steps

1. **Read the updated docs:**
   - `ENVIRONMENT-VARIABLES.md` - All variables explained
   - `SERVICES.md` - Details on each service
   - `COMPLETE-FEATURES.md` - Feature overview

2. **Update your configuration:**
   ```bash
   cp .env.example .env
   nano .env  # Apply your settings
   ```

3. **Deploy v2.1:**
   ```bash
   docker-compose build
   docker-compose up -d
   ```

4. **Verify everything works:**
   - Dashboard: `https://yourdomain.com`
   - Each enabled service
   - Log checking: `docker-compose logs -f apache-reverse-proxy`

---

## 🆘 Need Help?

**Variable questions?**
→ See `ENVIRONMENT-VARIABLES.md`

**Service not working?**
→ Check `TROUBLESHOOTING.md`

**Want to customize?**
→ Read `COMPLETE-FEATURES.md`

---

**Enjoy the improvements!** 🎉
