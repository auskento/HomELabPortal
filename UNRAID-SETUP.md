# HomELabPortal (HeLP) - Unraid Installation Guide

## Overview

This is **HomELabPortal (HeLP)** - a unified media server dashboard Docker container designed specifically for Unraid. It does NOT include any media applications - it proxies to your existing containers and services.

## Features

✅ **Unified Dashboard** - All your homelab services in one place  
✅ **17 Services Supported** - Sonarr, Radarr, Jellyfin, Plex, qBittorrent, Bazarr, and more  
✅ **Automatic HTTPS** - Let's Encrypt with daily auto-renewal  
✅ **Flexible Authentication** - None, Basic, Entra ID, or Google OAuth  
✅ **4 Dashboard Themes** - Customize your interface  
✅ **Custom Service Ordering** - Reorder categories as you like  
✅ **Unraid Native** - Full Unraid template support  

## Prerequisites

1. **Unraid Server** - Running latest Unraid version
2. **Domain Name** - Required for Let's Encrypt SSL certificates
3. **Existing Docker Services** - (Sonarr, Radarr, Jellyfin, etc.)
4. **Port 80/443 Available** - On your Unraid server

## Installation

### Method 1: Via Unraid GUI (Easiest)

1. **Add Repository**
   - Go to `Settings` → `Docker` 
   - Add custom registry template URL:
     ```
     https://raw.githubusercontent.com/yourusername/unraid-templates/main/
     ```

2. **Add Container**
   - Click `Add Container`
   - Search for `apache-reverse-proxy`
   - Select it from the template
   - Fill in required fields:
     - `DOMAIN`: Your domain (e.g., `media.example.com`)
     - `EMAIL`: Your email for SSL (e.g., `admin@example.com`)
   - Click `Apply`

### Method 2: Manual Installation

1. **Create Directories**
   ```bash
   mkdir -p /mnt/user/appdata/apache-reverse-proxy/{letsencrypt,logs,html}
   chmod -R 755 /mnt/user/appdata/apache-reverse-proxy
   ```

2. **Download Template**
   - Download `homelabportal.xml` from the repository
   - Copy to `/boot/config/plugins/dockerManagement/templates-user/` directory

3. **Add Container**
   - In Unraid WebUI: `Docker` → `Add Container`
   - Browse to the template
   - Configure settings
   - Click `Create`

## Configuration

### Basic Setup

1. **Set Required Variables**
   - `DOMAIN`: `media.yourdomain.com` (or your domain)
   - `EMAIL`: `admin@yourdomain.com` (for SSL notifications)

2. **Enable Services**
   - Check boxes for services you want to proxy
   - Common: `ENABLE_SONARR`, `ENABLE_RADARR`, `ENABLE_JELLYFIN`

3. **Save & Start**
   - Click `Apply` 
   - Container will download and start
   - First start may take 1-2 minutes for SSL cert acquisition

### Advanced Configuration

#### Office 365 Authentication
```
ENABLE_AUTH_OFFICE365: true
OAUTH2_CLIENT_ID: your-azure-app-id
OAUTH2_CLIENT_SECRET: your-azure-secret
OAUTH2_REDIRECT_URI: https://media.yourdomain.com/oauth2callback
OAUTH2_ALLOWED_DOMAINS: yourdomain.com
OAUTH2_CRYPTO_PASSPHRASE: (generate with: openssl rand -base64 24)
```

#### Custom Services
Edit template to add additional service proxy locations

## Port Configuration

| Port | Protocol | Purpose |
|------|----------|---------|
| 80 | TCP | HTTP (auto-redirects to HTTPS) |
| 443 | TCP | HTTPS (main port) |

**Important**: Unraid's default ports may conflict. Configure accordingly.

## Storage/Volumes

| Location | Purpose | Notes |
|----------|---------|-------|
| `/mnt/user/appdata/apache-reverse-proxy/letsencrypt` | SSL Certificates | Persists across restarts |
| `/mnt/user/appdata/apache-reverse-proxy/logs` | Apache Logs | View for troubleshooting |
| `/mnt/user/appdata/apache-reverse-proxy/html` | Dashboard HTML | Customize your UI |

## Accessing Services

Once running, access services at:

```
https://yourdomain.com/sonarr       # Sonarr
https://yourdomain.com/radarr       # Radarr
https://yourdomain.com/jellyfin     # Jellyfin
https://yourdomain.com/plex         # Plex
https://yourdomain.com/transmission # Transmission
https://yourdomain.com/qbittorrent  # qBittorrent
```

## Dashboard

The included dashboard provides a frame-based interface similar to classic Unraid designs:

- **Top Menu Bar** (140px) - Service icons
- **Main Content Area** - Service views
- **Click icons** to load service in main area

Customize by editing `/mnt/user/appdata/apache-reverse-proxy/html/index.html`

## Troubleshooting

### Container Won't Start

**Check Logs:**
```bash
# In Unraid WebUI
Docker → apache-reverse-proxy → Logs
```

**Common Issues:**
1. **Port 80/443 already in use** - Check other containers
2. **Domain doesn't resolve** - Verify DNS is pointing to Unraid
3. **Certificate acquisition failed** - Check email/domain validity

### HTTPS Certificate Issues

**Check certificate status:**
```bash
docker exec apache-reverse-proxy certbot certificates
```

**Force renewal:**
```bash
docker exec apache-reverse-proxy certbot renew --force-renewal
```

### Services Return 502/503

1. **Verify service is running**
   - Check it's accessible directly on its port
   - Example: `http://localhost:8989` for Sonarr

2. **Check service container name**
   - Must match the one used in proxy config
   - Unraid usually names them: `sonarr`, `radarr`, etc.

3. **View Apache logs:**
   ```bash
   tail -f /mnt/user/appdata/apache-reverse-proxy/logs/error.log
   ```

### Can't Connect to Service Containers

**Ensure Docker Network:**
- Services need to be on the same Docker network as the proxy
- In Unraid, this is usually the default `bridge` network

**Check container network:**
```bash
docker inspect sonarr | grep NetworkMode
```

## Customization

### Change Dashboard Layout

Edit: `/mnt/user/appdata/apache-reverse-proxy/html/index.html`

Add/remove service icons by modifying the menu section.

### Add Custom Service

1. Edit the template to add new environment variable: `ENABLE_MYSERVICE`
2. Create configuration file in `/etc/apache2/sites-available/services/`
3. Update service list in dashboard HTML

## Monitoring

### View Container Logs

**In Unraid:**
- Docker → apache-reverse-proxy → Logs

**Via Terminal:**
```bash
docker logs apache-reverse-proxy
# Follow in real-time:
docker logs -f apache-reverse-proxy
```

### Check Service Status

Access the dashboard at `https://yourdomain.com` to verify services are accessible.

## Updating

### Update Container

1. **In Unraid WebUI:**
   - Docker → Repository → Check for Updates
   - Select apache-reverse-proxy
   - Click "Update"

2. **Via Terminal:**
   ```bash
   docker pull apache-reverse-proxy:latest
   ```

### Preserve Configuration

- Configuration is stored in environment variables (saved in template)
- SSL certificates are in `/mnt/user/appdata/apache-reverse-proxy/letsencrypt`
- Both are preserved during updates

## Performance

### Recommended Hardware

- **CPU**: 1-2 cores minimum
- **RAM**: 256MB minimum (512MB recommended)
- **Disk**: 1GB for logs and certs
- **Network**: 1Gbps recommended for streaming

### Optimization Tips

1. **Enable caching** - Configure in Apache if heavy use
2. **Monitor logs** - Check for slow responses
3. **Increase timeouts** - If backends are slow
4. **Load balance** - Distribute load across multiple backend instances

## Security

### Best Practices

1. **Keep domain updated** - DNS must point to Unraid
2. **Strong auth** - Enable Office 365 auth if available
3. **Firewall rules** - Only expose 80/443 to public
4. **Regular backups** - Backup `/appdata/apache-reverse-proxy`
5. **Monitor access** - Review Apache logs regularly

### HTTPS Status

- ✅ Automatic certificate acquisition
- ✅ Daily auto-renewal
- ✅ Strong TLS 1.2+ enforcement
- ✅ Security headers enabled by default

## Support & Resources

### Documentation

- **Detailed Setup**: See included documentation files
- **Services Guide**: Information on each proxy service
- **Troubleshooting**: Common issues and solutions
- **Office 365 Auth**: Complete authentication guide

### Helpful Links

- [Unraid Community](https://unraid.net/)
- [Docker Hub](https://hub.docker.com/)
- [Let's Encrypt](https://letsencrypt.org/)
- [Apache Documentation](https://httpd.apache.org/)

## Uninstall

### Remove Container

1. **In Unraid:**
   - Docker → apache-reverse-proxy
   - Click "Remove"

2. **Remove Data (Optional):**
   ```bash
   rm -rf /mnt/user/appdata/apache-reverse-proxy
   ```

## FAQ

**Q: Does this install media apps?**
A: No! This is a reverse proxy only. It proxies to your existing containers.

**Q: Can I use with internal domain?**
A: Let's Encrypt requires a public domain. For internal use, generate self-signed certs.

**Q: How do I add my own service?**
A: Edit the template to add environment variables and service config files.

**Q: What if I lose my SSL certificate?**
A: It's automatically renewed daily. Certificates are stored in appdata.

**Q: Can I use with Plex directly?**
A: Yes! Enable `ENABLE_PLEX` and proxy to `localhost:32400`

**Q: Does this work with UnRAID on ARM?**
A: Yes, if using ARM-compatible Docker image.

---

**Ready to deploy?** Start with the Unraid template installation above! 🚀

Need help? Check the included documentation or review container logs in Unraid.
