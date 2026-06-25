# Service Backend URL Configuration

Guide for configuring backend URLs for your 17 supported services.

## Overview

Each service needs two variables:
1. **`ENABLE_*`** - Turn service on/off (`true`/`false`)
2. **`*_URL`** - Where the service is located

## All 17 Services

### Automation Services

#### Sonarr (TV Shows)
```yaml
ENABLE_SONARR: "true"
SONARR_URL: "http://sonarr:8989"
```
- **Default Port:** 8989
- **Docker Container Name:** `sonarr`
- **Path on Dashboard:** `/sonarr/`

#### Radarr (Movies)
```yaml
ENABLE_RADARR: "true"
RADARR_URL: "http://radarr:7878"
```
- **Default Port:** 7878
- **Docker Container Name:** `radarr`
- **Path on Dashboard:** `/radarr/`

#### Whisparr (Adult Content)
```yaml
ENABLE_WHISPARR: "true"
WHISPARR_URL: "http://whisparr:6969"
```
- **Default Port:** 6969
- **Docker Container Name:** `whisparr`
- **Path on Dashboard:** `/whisparr/`

#### Lidarr (Music)
```yaml
ENABLE_LIDARR: "true"
LIDARR_URL: "http://lidarr:8686"
```
- **Default Port:** 8686
- **Docker Container Name:** `lidarr`
- **Path on Dashboard:** `/lidarr/`

#### Prowlarr (Indexer Manager)
```yaml
ENABLE_PROWLARR: "true"
PROWLARR_URL: "http://prowlarr:9696"
```
- **Default Port:** 9696
- **Docker Container Name:** `prowlarr`
- **Path on Dashboard:** `/prowlarr/`

#### Seerr (Request Manager)
```yaml
ENABLE_SEERR: "true"
SEERR_URL: "http://seerr:5055"
```
- **Default Port:** 5055
- **Docker Container Name:** `seerr`
- **Path on Dashboard:** `/seerr/`

#### Bazarr (Subtitle Management)
```yaml
ENABLE_BAZARR: "true"
BAZARR_URL: "http://bazarr:6767"
```
- **Default Port:** 6767
- **Docker Container Name:** `bazarr`
- **Path on Dashboard:** `/bazarr/`

---

### Media Streaming Services

#### Jellyfin (Open Source Streaming)
```yaml
ENABLE_JELLYFIN: "true"
JELLYFIN_URL: "http://jellyfin:8096"
```
- **Default Port:** 8096
- **Docker Container Name:** `jellyfin`
- **Path on Dashboard:** `/jellyfin/`
- **Note:** Open source alternative to Plex

#### Emby (Commercial Streaming)
```yaml
ENABLE_EMBY: "true"
EMBY_URL: "http://emby:8096"
```
- **Default Port:** 8096
- **Docker Container Name:** `emby`
- **Path on Dashboard:** `/emby/`
- **Note:** Can't run Jellyfin AND Emby on same port

#### Plex (Commercial Streaming)
```yaml
ENABLE_PLEX: "true"
PLEX_URL: "http://plex:32400"
```
- **Default Port:** 32400
- **Docker Container Name:** `plex`
- **Path on Dashboard:** `/plex/`

---

### Monitoring/Analytics Services

#### Tautulli (Plex Analytics)
```yaml
ENABLE_TAUTULLI: "true"
TAUTULLI_URL: "http://tautulli:8181"
```
- **Default Port:** 8181
- **Docker Container Name:** `tautulli`
- **Path on Dashboard:** `/tautulli/`
- **Note:** Requires Plex to be running

---

### Download Services

#### Transmission (Torrent Client)
```yaml
ENABLE_TRANSMISSION: "true"
TRANSMISSION_URL: "http://transmission:6969"
```
- **Default Port:** 6969
- **Docker Container Name:** `transmission`
- **Path on Dashboard:** `/transmission/`

#### qBittorrent (Torrent Client)
```yaml
ENABLE_QBITTORRENT: "true"
QBITTORRENT_URL: "http://qbittorrent:8080"
```
- **Default Port:** 8080
- **Docker Container Name:** `qbittorrent`
- **Path on Dashboard:** `/qbittorrent/`

#### SABnzbd (Usenet Client)
```yaml
ENABLE_SABNZBD: "true"
SABNZBD_URL: "http://sabnzbd:8080"
```
- **Default Port:** 8080
- **Docker Container Name:** `sabnzbd`
- **Path on Dashboard:** `/sabnzbd/`
- **Note:** Can't run qBittorrent AND SABnzbd on same port

#### NZBGet (Usenet Client)
```yaml
ENABLE_NZBGET: "true"
NZBGET_URL: "http://nzbget:6789"
```
- **Default Port:** 6789
- **Docker Container Name:** `nzbget`
- **Path on Dashboard:** `/nzbget/`

#### NZBHydra (NZB Indexer)
```yaml
ENABLE_NZBHYDRA: "true"
NZBHYDRA_URL: "http://nzbhydra:5076"
```
- **Default Port:** 5076
- **Docker Container Name:** `nzbhydra`
- **Path on Dashboard:** `/nzbhydra/`

#### Deluge (Torrent Client)
```yaml
ENABLE_DELUGE: "true"
DELUGE_URL: "http://deluge:8112"
```
- **Default Port:** 8112
- **Docker Container Name:** `deluge`
- **Path on Dashboard:** `/deluge/`

---

## URL Format Options

### Docker Container (Recommended)
Use the container name if services are on the same Docker network:
```yaml
SONARR_URL: http://sonarr:8989
```

### Local IP Address
Use if services are on a different machine or network:
```yaml
SONARR_URL: http://192.168.1.100:8989
```

### Hostname
Use if services are accessible by hostname:
```yaml
SONARR_URL: http://media-server.local:8989
```

### External URL
If services are accessible externally:
```yaml
SONARR_URL: http://example.com:8989
```

### HTTPS
For services with SSL:
```yaml
SONARR_URL: https://sonarr.example.com:8989
```

---

## Complete Example Configuration

### docker-compose.yml Example
```yaml
services:
  apache-reverse-proxy:
    environment:
      # Domain and email
      DOMAIN: yourdomain.com
      EMAIL: admin@yourdomain.com
      
      # Automation services
      ENABLE_SONARR: "true"
      SONARR_URL: http://sonarr:8989
      
      ENABLE_RADARR: "true"
      RADARR_URL: http://radarr:7878
      
      ENABLE_WHISPARR: "true"
      WHISPARR_URL: http://whisparr:6969
      
      # Media streaming
      ENABLE_JELLYFIN: "true"
      JELLYFIN_URL: http://jellyfin:8096
      
      ENABLE_PLEX: "false"
      # PLEX_URL: (disabled)
      
      # Downloads
      ENABLE_SABNZBD: "true"
      SABNZBD_URL: http://192.168.1.50:8080
      
      ENABLE_QBITTORRENT: "false"
      # QBITTORRENT_URL: (disabled)
      
      # All others disabled by default
      ENABLE_LIDARR: "false"
      ENABLE_WHISPARR: "false"
      ENABLE_PROWLARR: "false"
      ENABLE_SEERR: "false"
      ENABLE_BAZARR: "false"
      ENABLE_EMBY: "false"
      ENABLE_TAUTULLI: "false"
      ENABLE_TRANSMISSION: "false"
      ENABLE_DELUGE: "false"
      ENABLE_NZBGET: "false"
      ENABLE_NZBHYDRA: "false"
```

---

## Verifying URLs Work

Test if a service URL is accessible:

```bash
# From the proxy container
docker-compose exec apache-reverse-proxy curl -I http://sonarr:8989

# Should return something like:
# HTTP/1.1 200 OK
# or
# HTTP/1.1 401 Unauthorized (if service requires auth)
```

If you get `Connection refused` or `Name resolution failed`, the URL is wrong.

---

## Common Issues

### Connection Refused
**Cause:** Service URL is wrong or service isn't running  
**Solution:** 
- Verify service is actually running: `docker-compose ps`
- Check if using wrong hostname/IP
- Verify port number is correct

### Name Resolution Failed
**Cause:** Using wrong container name  
**Solution:**
- Check container name: `docker-compose ps`
- Verify container is on same network as proxy
- Use IP address instead of container name

### Service Returns 401/403
**Cause:** Service requires authentication  
**Solution:**
- Check if service has API key requirement
- Verify credentials in proxy config
- Check service logs for auth errors

### Slow Response Times
**Cause:** Service URL is going over network instead of internal Docker network  
**Solution:**
- Use container name instead of IP (if possible)
- Ensure services are on same Docker network
- Check network performance

---

## Dashboard Access

Once configured and enabled, access services at:

```
https://yourdomain.com/servicename/

Examples:
https://yourdomain.com/sonarr/
https://yourdomain.com/radarr/
https://yourdomain.com/jellyfin/
https://yourdomain.com/plex/
https://yourdomain.com/sabnzbd/
```

---

## Service Combinations

### Minimal Setup
```yaml
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
ENABLE_JELLYFIN: "true"
```
(TV + Movies + Streaming)

### Complete Media Server
```yaml
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
ENABLE_WHISPARR: "true"
ENABLE_LIDARR: "true"
ENABLE_READARR: "true"
ENABLE_PROWLARR: "true"
ENABLE_JELLYFIN: "true"
ENABLE_SABNZBD: "true"
ENABLE_QBITTORRENT: "true"
ENABLE_TAUTULLI: "true"
```

### Torrent Setup
```yaml
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
ENABLE_TRANSMISSION: "true"
ENABLE_QBITTORRENT: "true"
ENABLE_JELLYFIN: "true"
```

### Usenet Setup
```yaml
ENABLE_SONARR: "true"
ENABLE_RADARR: "true"
ENABLE_SABNZBD: "true"
ENABLE_JELLYFIN: "true"
```

---

**See ENVIRONMENT-VARIABLES.md for complete variable reference**
