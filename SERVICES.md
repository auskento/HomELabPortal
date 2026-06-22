# Service Configuration Guide

This Apache reverse proxy setup includes pre-configured support for popular media server applications. You can enable or disable services using environment variables.

## Quick Enable/Disable

Edit `docker-compose.yml` and set environment variables to control which services are proxied:

```yaml
environment:
  # Media Server Managers (*arr applications)
  ENABLE_SONARR: "true"      # /sonarr - TV show automation
  ENABLE_RADARR: "true"      # /radarr - Movie automation
  ENABLE_WHISPARR: "false"   # /whisparr - Adult content collection manager
  ENABLE_LIDARR: "false"     # /lidarr - Music automation
  ENABLE_READARR: "false"    # /readarr - Book automation
  ENABLE_PROWLARR: "false"   # /prowlarr - Indexer manager
  ENABLE_OVERSEERR: "false"  # /overseerr - Request manager
  
  # Media Centers
  ENABLE_JELLYFIN: "false"   # /jellyfin - Open-source media server
  ENABLE_EMBY: "false"       # /emby - Emby media server
  ENABLE_PLEX: "false"       # /plex - Plex media server
  ENABLE_TAUTULLI: "false"   # /tautulli - Plex monitoring
  
  # Torrent Clients
  ENABLE_TRANSMISSION: "false" # /transmission - Transmission client
  ENABLE_QBITTORRENT: "false"  # /qbittorrent - qBittorrent client
```

## Available Services

### Media Server Managers (*arr Applications)

These applications automate downloading and organizing media:

#### Sonarr - TV Show Automation
- **URL Path**: `/sonarr`
- **Port**: 8989
- **Enable**: `ENABLE_SONARR=true`
- **Features**: 
  - TV show monitoring and downloading
  - Season/episode management
  - Integration with downloaders
  
**docker-compose example**:
```yaml
sonarr:
  image: lscr.io/linuxserver/sonarr:latest
  container_name: sonarr
  volumes:
    - /path/to/sonarr/config:/config
    - /path/to/media:/media
  ports:
    - "8989:8989"
```

#### Radarr - Movie Automation
- **URL Path**: `/radarr`
- **Port**: 7878
- **Enable**: `ENABLE_RADARR=true`
- **Features**:
  - Movie monitoring and downloading
  - Quality management
  - Integration with downloaders

**docker-compose example**:
```yaml
radarr:
  image: lscr.io/linuxserver/radarr:latest
  container_name: radarr
  volumes:
    - /path/to/radarr/config:/config
    - /path/to/media:/media
  ports:
    - "7878:7878"
```

#### Whisparr - Adult Content Collection Manager
- **URL Path**: `/whisparr`
- **Port**: 6969
- **Enable**: `ENABLE_WHISPARR=true`
- **Features**:
  - Adult content library management
  - Automated collection organization
  - Collection tracking and organization

⚠️ **Note**: Whisparr is designed for managing adult content collections. Enable only if you use this application.

**docker-compose example**:
```yaml
whisparr:
  image: lscr.io/linuxserver/whisparr:latest
  container_name: whisparr
  volumes:
    - /path/to/whisparr/config:/config
    - /path/to/media:/media
  ports:
    - "6969:6969"
```

#### Lidarr - Music Automation
- **URL Path**: `/lidarr`
- **Port**: 8686
- **Enable**: `ENABLE_LIDARR=true`
- **Features**:
  - Music album monitoring
  - Artist management
  - Quality control

#### Readarr - Book Automation
- **URL Path**: `/readarr`
- **Port**: 8787
- **Enable**: `ENABLE_READARR=true`
- **Features**:
  - Book/magazine automation
  - Author tracking
  - Download management

#### Prowlarr - Indexer Manager
- **URL Path**: `/prowlarr`
- **Port**: 9696
- **Enable**: `ENABLE_PROWLARR=true`
- **Features**:
  - Centralized indexer management
  - Shared across all *arr apps
  - Health monitoring

#### Overseerr - Request Manager
- **URL Path**: `/overseerr`
- **Port**: 5055
- **Enable**: `ENABLE_OVERSEERR=true`
- **Features**:
  - User request management
  - Approval workflows
  - Integration with Sonarr/Radarr

### Media Centers

#### Jellyfin - Open Source Media Center
- **URL Path**: `/jellyfin`
- **Port**: 8096
- **Enable**: `ENABLE_JELLYFIN=true`
- **Features**:
  - Video/audio streaming
  - Library management
  - Web interface and apps

#### Emby - Emby Media Server
- **URL Path**: `/emby`
- **Port**: 8096
- **Enable**: `ENABLE_EMBY=true`
- **Features**:
  - Premium media streaming
  - Advanced features
  - Multi-platform support

#### Plex - Plex Media Server
- **URL Path**: `/plex`
- **Port**: 32400
- **Enable**: `ENABLE_PLEX=true`
- **Features**:
  - Cloud sync and remote access
  - Automatic metadata
  - Mobile apps

#### Tautulli - Plex Monitoring
- **URL Path**: `/tautulli`
- **Port**: 8181
- **Enable**: `ENABLE_TAUTULLI=true`
- **Features**:
  - Plex monitoring and stats
  - User activity tracking
  - Notifications

### Torrent Clients

#### Transmission
- **URL Path**: `/transmission`
- **Port**: 6969
- **Enable**: `ENABLE_TRANSMISSION=true`
- **Features**:
  - Lightweight torrent client
  - Web interface
  - Remote control

#### qBittorrent
- **URL Path**: `/qbittorrent`
- **Port**: 8080
- **Enable**: `ENABLE_QBITTORRENT=true`
- **Features**:
  - Advanced torrent client
  - Web UI with search
  - API support

## Custom Backend Service

You can also proxy to a custom backend service:

```yaml
environment:
  ENABLE_CUSTOM_BACKEND: "true"
  CUSTOM_BACKEND_PATH: /myapp
  CUSTOM_BACKEND_URL: http://myservice:8000
```

This will create a proxy at `/myapp` pointing to your custom service.

## How It Works

1. **Template Processing**: On startup, the entrypoint script reads `reverse-proxy.conf.template`
2. **Environment Variables**: Checks which services are enabled (ENABLE_* = "true")
3. **Config Generation**: Includes service configuration files only for enabled services
4. **Apache Load**: Loads the generated configuration and starts Apache

### Generated Configuration

The generated configuration is written to `/etc/apache2/sites-available/reverse-proxy.conf`.

You can view it:
```bash
docker-compose exec apache-reverse-proxy cat /etc/apache2/sites-available/reverse-proxy.conf
```

## Service Port Mapping

When using docker-compose with the provided services, they're connected via the `proxy-network`:

| Service | Container Port | Exposed Port | Notes |
|---------|----------------|--------------|-------|
| Sonarr | 8989 | 8989 | Optional: expose if needed |
| Radarr | 7878 | 7878 | Optional: expose if needed |
| Lidarr | 8686 | 8686 | Optional: expose if needed |
| Readarr | 8787 | 8787 | Optional: expose if needed |
| Prowlarr | 9696 | 9696 | Optional: expose if needed |
| Overseerr | 5055 | 5055 | Optional: expose if needed |
| Jellyfin | 8096 | 8096 | Optional: expose if needed |
| Plex | 32400 | 32400 | Optional: expose if needed |
| Transmission | 6969 | 6969 | Optional: expose if needed |
| qBittorrent | 8080 | 8080 | Optional: expose if needed |

## WebSocket Support

Services that use WebSockets for real-time updates are automatically configured:
- **Sonarr, Radarr, Lidarr, Readarr**: SignalR updates
- **Overseerr**: Socket.io notifications
- **Jellyfin/Emby**: WebSocket connections
- **qBittorrent**: Real-time status updates

## Adding Custom Services

To add a new service:

1. **Create config file**: `apache-conf/services/myservice.conf`
   ```apache
   <Location /myservice>
       ProxyPass http://myservice:9000/myservice
       ProxyPassReverse http://myservice:9000/myservice
       ProxyConnectTimeout 30
       ProxyTimeout 300
       ProxyPreserveHost On
       RequestHeader set X-Forwarded-Proto "https"
   </Location>
   ```

2. **Add environment variable**: In `docker-compose.yml` and generation script
   ```bash
   # In generate-config.sh:
   ENABLE_MYSERVICE="${ENABLE_MYSERVICE:-false}"
   MYSERVICE_INCLUDE=$(generate_include "myservice" "$ENABLE_MYSERVICE")
   
   # In template:
   @@INCLUDE_MYSERVICE@@
   ```

3. **Update template**: Add placeholder to `reverse-proxy.conf.template`

4. **Test config**:
   ```bash
   docker-compose exec apache-reverse-proxy apache2ctl configtest
   ```

## Security Considerations

### Service Isolation

Enabled services should only be accessible through the reverse proxy:
- Don't expose service ports to the internet
- Keep only 80/443 open
- Services communicate over Docker internal network

### Authentication

For exposed services, consider adding:

**HTTP Basic Auth**:
```apache
<Location /sonarr>
    AuthType Basic
    AuthName "Sonarr"
    AuthUserFile /etc/apache2/.htpasswd
    Require valid-user
    
    ProxyPass http://sonarr:8989/sonarr
    ProxyPassReverse http://sonarr:8989/sonarr
</Location>
```

Generate htpasswd:
```bash
docker-compose exec apache-reverse-proxy htpasswd -c /etc/apache2/.htpasswd username
```

## Troubleshooting

### Service not responding (502 Bad Gateway)

1. **Check if service is running**:
   ```bash
   docker-compose ps servicename
   ```

2. **Check service network connectivity**:
   ```bash
   docker-compose exec apache-reverse-proxy ping servicename
   ```

3. **View Apache logs**:
   ```bash
   docker-compose exec apache-reverse-proxy tail -f /var/log/apache2/error.log
   ```

### Service shows in config but not working

1. **Verify environment variable is set to "true"** (case-sensitive)
2. **Check service configuration file exists**:
   ```bash
   docker-compose exec apache-reverse-proxy ls -la /etc/apache2/sites-available/services/
   ```
3. **Regenerate config** with correct variable:
   ```bash
   docker-compose restart apache-reverse-proxy
   ```

### Configuration validation errors

Test Apache config:
```bash
docker-compose exec apache-reverse-proxy apache2ctl configtest
```

Should show: `Syntax OK`

## Examples

### Complete Setup with Multiple Services

```yaml
environment:
  DOMAIN: media.example.com
  EMAIL: admin@example.com
  
  # Enabled services
  ENABLE_SONARR: "true"
  ENABLE_RADARR: "true"
  ENABLE_PROWLARR: "true"
  ENABLE_OVERSEERR: "true"
  ENABLE_JELLYFIN: "true"
  ENABLE_TAUTULLI: "true"
  ENABLE_QBITTORRENT: "true"
```

After restart, access at:
- `https://media.example.com/sonarr` - Sonarr
- `https://media.example.com/radarr` - Radarr
- `https://media.example.com/prowlarr` - Prowlarr
- `https://media.example.com/overseerr` - Overseerr
- `https://media.example.com/jellyfin` - Jellyfin
- `https://media.example.com/tautulli` - Tautulli
- `https://media.example.com/qbittorrent` - qBittorrent

### Minimal Setup (Just Sonarr and Radarr)

```yaml
environment:
  DOMAIN: media.example.com
  EMAIL: admin@example.com
  
  # Only these two enabled
  ENABLE_SONARR: "true"
  ENABLE_RADARR: "true"
  
  # Everything else disabled (default)
```

## Performance Tips

1. **Only enable needed services**: Fewer includes = faster config load
2. **Monitor resource usage**: Some services are memory-intensive
3. **Use dedicated volumes**: Store config/media on fast storage
4. **Network optimization**: Use Docker network for local services

## Migration from Static Config

If you have an existing static `reverse-proxy.conf`, the template system is backward compatible:

1. Make note of any custom modifications
2. Update `reverse-proxy.conf.template` with your changes
3. Add corresponding `@@INCLUDE_*@@` placeholders
4. The config generator will pick it up on next restart
