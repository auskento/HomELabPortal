# Troubleshooting Service Configuration

## Configuration Not Regenerating

### Issue: Changed environment variables but services not appearing

**Check 1: Verify environment variables are set correctly**

```bash
# Check what's actually set
docker-compose exec apache-reverse-proxy env | grep ENABLE_

# Should show something like:
# ENABLE_SONARR=true
# ENABLE_RADARR=true
# ENABLE_LIDARR=false
```

**Check 2: Verify the variable is actually "true" (case matters)**

```bash
# This works:
ENABLE_SONARR=true

# These do NOT work:
ENABLE_SONARR=True
ENABLE_SONARR=TRUE
ENABLE_SONARR=yes
```

**Check 3: Restart the container**

```bash
# Restart to regenerate config
docker-compose restart apache-reverse-proxy

# Watch the logs
docker-compose logs -f apache-reverse-proxy

# Should see "Generating Apache configuration with enabled services..."
```

## Service Still Shows 502 Error

### Issue: Service is configured but returns 502 Bad Gateway

**Check 1: Is the service actually running?**

```bash
# List all services
docker-compose ps

# Should show the service in the list with status "Up"
```

**Check 2: Can the proxy reach the service on its network?**

```bash
# Test network connectivity
docker-compose exec apache-reverse-proxy ping sonarr

# Should get responses:
# PING sonarr (172.X.X.X) 56(84) bytes of data.
# 64 bytes from sonarr...

# If it fails, the service isn't on the network
```

**Check 3: Test the service port directly**

```bash
# Try connecting to the service port
docker-compose exec apache-reverse-proxy curl -v http://sonarr:8989

# Should get a response (not a connection refused)
```

**Check 4: Check the Apache error log**

```bash
# View recent errors
docker-compose exec apache-reverse-proxy tail -100 /var/log/apache2/error.log

# Look for errors like:
# (111)Connection refused: AH00957: HTTP: attempt to connect to 127.0.0.1:8989 failed
```

**Check 5: Verify service port in proxy config**

```bash
# View the generated config
docker-compose exec apache-reverse-proxy grep -A5 "Location /sonarr" /etc/apache2/sites-available/reverse-proxy.conf

# Should show the correct port, e.g.:
# ProxyPass http://sonarr:8989/sonarr
```

### Common Port Issues

Verify you have the correct port for each service:

| Service | Correct Port | Common Mistake |
|---------|--------------|----------------|
| Sonarr | 8989 | 8990 |
| Radarr | 7878 | 7879 |
| Lidarr | 8686 | 8686 |
| Readarr | 8787 | 8788 |
| Prowlarr | 9696 | 9697 |
| Overseerr | 5055 | 5056 |
| Jellyfin | 8096 | 8097 |

Check your docker-compose.yml to ensure ports match.

## Configuration File Not Generated

### Issue: Service starts but no /etc/apache2/sites-available/reverse-proxy.conf file

**Check 1: Check if template exists**

```bash
docker-compose exec apache-reverse-proxy ls -la /etc/apache2/sites-available/

# Should show:
# -rw-r--r-- ... reverse-proxy.conf.template
```

**Check 2: Check if generate-config.sh exists and is executable**

```bash
docker-compose exec apache-reverse-proxy ls -la /usr/local/bin/generate-config.sh

# Should be executable (-rwxr-xr-x)
```

**Check 3: Manually run the generator**

```bash
docker-compose exec apache-reverse-proxy /usr/local/bin/generate-config.sh
```

**Check 4: View entrypoint logs**

```bash
docker-compose logs apache-reverse-proxy | grep -i "generating\|config"
```

## Apache Won't Start

### Issue: Container exits immediately or shows errors

**Check 1: Verify Apache syntax**

```bash
docker-compose exec apache-reverse-proxy apache2ctl configtest

# Should show:
# Syntax OK
```

**Check 2: View startup errors**

```bash
# First few lines of startup
docker-compose logs apache-reverse-proxy | head -50

# Look for:
# - "apache2: bad syntax"
# - "No such file or directory"
# - SSL certificate errors
```

**Check 3: Check certificate file exists**

```bash
# If error mentions certificates
docker-compose exec apache-reverse-proxy ls -la /etc/letsencrypt/live/yourdomain.com/

# Should show:
# cert.pem
# chain.pem
# fullchain.pem
# privkey.pem
```

## Service Services in Config But Not Working

### Issue: Service appears in config but you can't access it

**Check 1: Verify service config file exists**

```bash
docker-compose exec apache-reverse-proxy ls -la /etc/apache2/sites-available/services/

# Should show service files like:
# sonarr.conf
# radarr.conf
# etc.
```

**Check 2: View the generated proxy rule**

```bash
docker-compose exec apache-reverse-proxy grep -A10 "Location /sonarr" /etc/apache2/sites-available/reverse-proxy.conf

# Should show proxy rules, not empty
```

**Check 3: Test the specific Location directive**

```bash
# Check if Location block is correct
docker-compose exec apache-reverse-proxy grep -n "Location /sonarr" /etc/apache2/sites-available/reverse-proxy.conf

# Should be a non-zero line number
```

## Network Issues

### Issue: Services can't communicate with each other

**Check 1: Verify all services are on the same network**

```bash
# Check which network services are using
docker network inspect proxy-network

# All containers should be listed there
```

**Check 2: Check if network exists**

```bash
docker network ls | grep proxy-network

# If missing, docker-compose will create it automatically
```

**Check 3: Restart network connections**

```bash
docker-compose down
docker-compose up -d
```

## Certificate Issues

### Issue: HTTPS not working or certificate errors

**Check 1: Verify certificate exists**

```bash
docker-compose exec apache-reverse-proxy certbot certificates

# Should show your domain and expiration date
```

**Check 2: Check certificate file paths**

```bash
docker-compose exec apache-reverse-proxy ls -la /etc/letsencrypt/live/yourdomain.com/

# All files should exist
```

**Check 3: Test HTTPS manually**

```bash
docker-compose exec apache-reverse-proxy curl -v https://yourdomain.com/

# Should connect without SSL errors
```

**Check 4: View Certbot logs**

```bash
docker-compose exec apache-reverse-proxy tail -50 /var/log/certbot-renewal.log
```

## WebSocket Issues

### Issue: Real-time updates not working

**Check 1: WebSocket proxies are included**

Some services need special WebSocket handling. Check config:

```bash
docker-compose exec apache-reverse-proxy grep -n "socket.io\|signalr" /etc/apache2/sites-available/reverse-proxy.conf

# Should show WebSocket proxy rules
```

**Check 2: WebSocket connectivity**

```bash
# Check if service supports WebSockets
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" \
  -H "Sec-WebSocket-Version: 13" \
  http://sonarr:8989/
```

## Debugging Steps

### Get Complete Diagnostic Info

```bash
# Create a diagnostic dump
docker-compose logs > logs.txt 2>&1
docker-compose ps >> logs.txt
docker-compose exec apache-reverse-proxy env >> logs.txt
docker-compose exec apache-reverse-proxy apache2ctl configtest >> logs.txt
docker-compose exec apache-reverse-proxy cat /etc/apache2/sites-available/reverse-proxy.conf >> logs.txt

# Review logs.txt for issues
```

### Check Inside the Container

```bash
# Get a shell in the container
docker-compose exec apache-reverse-proxy /bin/bash

# Then run diagnostics:
apache2ctl configtest
certbot certificates
env | grep ENABLE_
ls /etc/apache2/sites-available/
curl http://sonarr:8989
tail /var/log/apache2/error.log
```

### Rebuild from Scratch

If all else fails:

```bash
# Stop everything
docker-compose down -v

# Remove images to force rebuild
docker-compose rm -f

# Clean up
docker system prune -f

# Start fresh
docker-compose build
docker-compose up -d

# Watch logs
docker-compose logs -f apache-reverse-proxy
```

## Enable Debug Logging

```bash
# In docker-compose.yml, add:
environment:
  APACHE_LOG_LEVEL: debug

# Then restart:
docker-compose restart apache-reverse-proxy

# View debug output:
docker-compose logs -f apache-reverse-proxy
```

## Get Help

**When reporting issues, include:**

1. Output of `docker-compose ps`
2. Output of `docker-compose logs apache-reverse-proxy` (last 100 lines)
3. Your environment variables (from docker-compose.yml)
4. Output of `docker-compose exec apache-reverse-proxy apache2ctl configtest`
5. The specific error you're seeing

**Example diagnostic command:**

```bash
echo "=== Services ===" && \
docker-compose ps && \
echo "=== Recent Logs ===" && \
docker-compose logs --tail 50 apache-reverse-proxy && \
echo "=== Config Test ===" && \
docker-compose exec apache-reverse-proxy apache2ctl configtest && \
echo "=== Generated Config ===" && \
docker-compose exec apache-reverse-proxy head -50 /etc/apache2/sites-available/reverse-proxy.conf
```
