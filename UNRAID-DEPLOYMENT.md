# Deploying Apache Reverse Proxy on Unraid

Complete guide for installing and configuring via Unraid web UI.

---

## TL;DR (5 Minutes)

1. **Copy template to Unraid:**
   ```bash
   cp unraid/apache-reverse-proxy.xml \
      /boot/config/plugins/dockerManagement/templates-user/
   ```

2. **Go to Unraid web UI → Docker → Add Container**

3. **Fill in:**
   - DOMAIN: your-domain.com
   - EMAIL: admin@example.com
   - Enable services (set ENABLE_SONARR, etc. to true)

4. **Click APPLY**

5. **Done!** Access at `https://your-domain.com`

---

## Step-by-Step Setup

### Step 1: Copy Template to Unraid

You need to get the `apache-reverse-proxy.xml` file to your Unraid server.

#### Option A: Using SSH/Terminal

```bash
# On Unraid terminal or via SSH:
mkdir -p /boot/config/plugins/dockerManagement/templates-user

# Copy template from extracted zip
cp /path/to/apache-reverse-proxy/unraid/apache-reverse-proxy.xml \
   /boot/config/plugins/dockerManagement/templates-user/
```

#### Option B: Manual Copy via Web UI

1. Go to Unraid web UI
2. Tools → System Devices (or Main)
3. Share → Boot
4. Navigate to: `boot/config/plugins/dockerManagement/templates-user/`
5. Create folder if doesn't exist
6. Upload `apache-reverse-proxy.xml`

---

### Step 2: Open Unraid Docker Management

1. Go to your Unraid web address:
   - http://your-unraid-ip:6443 (secure)
   - or http://your-unraid-ip (if on same network)

2. Click **Docker** tab in top navigation

3. Click **Add Container**

---

### Step 3: Select Template

1. Look for **"apache-reverse-proxy"** in the dropdown or search
2. If not visible, click refresh or search for it
3. The template should load automatically

---

### Step 4: Configure Basic Settings

#### Container Name
Leave default: `auskentos-apache-reverse-proxy`
(or change if you prefer)

#### Repository (Image)
Should be auto-filled with the Docker image name

#### Network Type
Select: **custom: dockernet**
(This allows proxy to reach other containers)

---

### Step 5: Set Environment Variables (IMPORTANT!)

Scroll down to "Environment Variables" section.

#### REQUIRED Variables

**1. DOMAIN** (MUST SET!)
```
DOMAIN: media.example.com
```
- Replace with your actual domain
- This must be accessible from the internet
- Let's Encrypt will use this

**2. EMAIL** (MUST SET!)
```
EMAIL: admin@example.com
```
- Email for Let's Encrypt notifications
- Use a real email you check

#### OPTIONAL Variables - Choose Your Services

**Enable the services you want:**

```
ENABLE_SONARR: true        (TV show automation)
ENABLE_RADARR: true        (Movie automation)
ENABLE_JELLYFIN: true      (Media streaming)
ENABLE_WHISPARR: false     (Adult content)
ENABLE_LIDARR: false       (Music automation)
ENABLE_READARR: false      (Book automation)
ENABLE_PROWLARR: false     (Indexer manager)
ENABLE_OVERSEERR: false    (Request manager)
ENABLE_EMBY: false         (Media streaming)
ENABLE_PLEX: false         (Media streaming)
ENABLE_TAUTULLI: false     (Analytics)
ENABLE_TRANSMISSION: false (Torrent client)
ENABLE_QBITTORRENT: false  (Torrent client)
ENABLE_SABNZBD: false      (Usenet client)
ENABLE_DELUGE: false       (Torrent client)
```

**Optional - Custom Icons:**
```
ICON_URL_SONARR: https://url/to/icon.png
(Leave blank for colored placeholder)
```

**Optional - Authentication:**
```
ENABLE_AUTH_OFFICE365: false
(Set true if you want Office 365 login)
```

---

### Step 6: Configure Ports

Both should already be set:

| Port | Container | Host | Notes |
|------|-----------|------|-------|
| 80   | 80        | 80   | HTTP (redirects to HTTPS) |
| 443  | 443       | 443  | HTTPS (secure) |

**Important:** Make sure ports 80 and 443 are:
- Not used by another container
- Open in your firewall
- Port-forwarded if on different network

---

### Step 7: Configure Volumes

You need TWO volumes:

**Volume 1: SSL Certificates**
```
Container Path: /etc/letsencrypt
Host Path: /mnt/user/appdata/apache-reverse-proxy/letsencrypt
Access Mode: Read/Write
```

**Volume 2: Logs**
```
Container Path: /var/log/apache2
Host Path: /mnt/user/appdata/apache-reverse-proxy/logs
Access Mode: Read/Write
```

Click "Add another path" if you don't see Volume 2.

---

### Step 8: Advanced Settings

Leave most defaults:

- **Restart Policy:** `unless-stopped`
- **Health Check:** Enabled (should be default)
- **CPU/Memory:** Auto (don't limit unless needed)

---

### Step 9: Review and Apply

Double-check:
- ✅ DOMAIN is set to your domain
- ✅ EMAIL is set to real email
- ✅ Services you want are enabled (true)
- ✅ Ports 80 and 443 mapped
- ✅ Volumes configured
- ✅ Network is dockernet

**Then click: APPLY**

---

### Step 10: Watch Startup

The container will:
1. Build the Docker image (may take 2-5 minutes)
2. Create the container
3. Start the services
4. Acquire SSL certificate from Let's Encrypt
5. Start Apache

**Check the logs:**
- Docker tab → auskentos-apache-reverse-proxy → Logs
- Look for "Apache started successfully"

---

## First Access

Once running:

### Access the Dashboard
```
https://your-domain.com/
```

If you see a certificate warning, it's normal (first visit). Click "Advanced" → "Continue".

### Access Individual Services

If you enabled services:
```
https://your-domain.com/sonarr
https://your-domain.com/radarr
https://your-domain.com/jellyfin
```

---

## Troubleshooting

### Container won't start?

**Check logs:**
- Docker → auskentos-apache-reverse-proxy → Logs
- Look for error messages

**Common issues:**
1. **"DOMAIN not set"** → Go back and fill in DOMAIN
2. **"Port 80 already in use"** → Another container using it
3. **"Port 443 already in use"** → Another container using it

### Can't access https://your-domain.com?

**Check:**
1. DNS resolves: Open browser, check DNS
2. Ports 80/443 are open in firewall
3. Domain is correct in DOMAIN field
4. Certificate exists: `ls /mnt/user/appdata/apache-reverse-proxy/letsencrypt/`

### Certificate errors?

**Check certificate status:**
```bash
# Via Unraid Console
cd /mnt/user/appdata/apache-reverse-proxy/letsencrypt/live/
ls -la
```

Should show certificate files for your domain.

**Renew certificate:**
```bash
docker exec auskentos-apache-reverse-proxy \
  certbot renew --dry-run
```

---

## Updating Configuration

### Change Services

1. Docker → auskentos-apache-reverse-proxy → Settings
2. Edit Environment Variable (e.g., set ENABLE_RADARR to true)
3. Click Apply
4. Container restarts with new settings

### Change Domain or Email

1. Stop container: Docker tab → click stop icon
2. Edit container: click settings icon
3. Update DOMAIN or EMAIL
4. Click Apply

### View Live Logs

Docker → auskentos-apache-reverse-proxy → Logs (WebUI)

Or via console:
```bash
docker logs -f auskentos-apache-reverse-proxy
```

---

## File Locations on Unraid

All files stored in:
```
/mnt/user/appdata/apache-reverse-proxy/
```

### Important Folders

| Path | Purpose |
|------|---------|
| `/mnt/user/appdata/apache-reverse-proxy/letsencrypt/` | SSL certificates |
| `/mnt/user/appdata/apache-reverse-proxy/logs/` | Apache logs |
| `/mnt/user/appdata/apache-reverse-proxy/html/` | Dashboard and icons |

---

## Performance Tips

### For Lower-End Systems

The proxy is very lightweight, but if needed:

1. **Disable health checks** if causing overhead
   - Docker → Settings → Disable health check

2. **Limit memory:**
   - Docker → Edit → Memory reservation: 256M

3. **Only enable needed services**
   - Each enabled service = Apache config includes

### For Higher-End Systems

No changes needed - proxy is efficient regardless.

---

## Security Notes

1. **HTTPS is automatic** - Let's Encrypt handles it
2. **Certificates renew automatically** - Daily cron job
3. **Optional: Add authentication** - Enable Office 365 auth
4. **Ports: Open 80 and 443** - Only for HTTPS/HTTP redirect

---

## Backing Up Configuration

Your data is in:
```
/mnt/user/appdata/apache-reverse-proxy/
```

**Backup regularly:**
- Certificates folder (essential)
- Config files (if modified)
- HTML folder (custom icons)

---

## Uninstalling

If you want to remove:

1. Docker → auskentos-apache-reverse-proxy → Remove icon
2. Optionally delete: `/mnt/user/appdata/apache-reverse-proxy/`

That's it!

---

## Getting Help

**Check logs first:**
```bash
docker logs auskentos-apache-reverse-proxy | tail -50
```

**Common error messages:**
- "Port already in use" → Change to different port
- "Domain not found" → Check DNS settings
- "Certificate error" → Check email notifications

---

## What's Next?

1. **Enable services** you want to access
2. **Add domain to your DNS** pointing to Unraid IP
3. **Port forward** 80/443 on your router (if external)
4. **Access dashboard** at https://your-domain.com
5. **Click services** in menu to access each one

---

## Quick Reference Commands

```bash
# View container status
docker ps | grep apache

# View logs
docker logs auskentos-apache-reverse-proxy

# Restart container
docker restart auskentos-apache-reverse-proxy

# Renew SSL certificates
docker exec auskentos-apache-reverse-proxy \
  certbot renew --dry-run

# View Apache config
docker exec auskentos-apache-reverse-proxy \
  cat /etc/apache2/sites-enabled/reverse-proxy.conf
```

---

**That's everything you need to run Apache Reverse Proxy on Unraid!** 🚀

For more info, see the full documentation in this package.
