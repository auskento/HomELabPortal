# Apache Reverse Proxy with Let's Encrypt

A complete Docker setup for an Apache reverse proxy with automatic SSL/TLS certificate management via Let's Encrypt, supporting multiple backend servers and custom HTML error pages.

## Features

- **Apache 2 Reverse Proxy** - Route traffic to multiple backend servers
- **Let's Encrypt Integration** - Automatic HTTPS with Certbot
- **Auto-Renewal** - Certificates automatically renew via cron (daily at 3 AM)
- **Load Balancing** - Round-robin load distribution across backends
- **Security Headers** - HSTS, X-Frame-Options, CSP, etc.
- **Custom Error Pages** - Beautiful 502 and 503 error pages
- **Health Checks** - Built-in Docker health checks
- **Multi-backend Support** - Route different paths to different backends

## Project Structure

```
.
├── Dockerfile                          # Docker image definition
├── docker-compose.yml                  # Docker Compose configuration
├── docker-entrypoint.sh               # Startup script (cert init & renewal setup)
├── cert-renewal-cron                  # Cron job for certificate renewal
├── apache-conf/
│   ├── reverse-proxy.conf             # Main Apache reverse proxy config
│   └── ssl-config.conf                # SSL/TLS security parameters
└── html/
    ├── index.html                     # Home page
    └── error-pages/
        ├── 502.html                   # Bad Gateway error page
        └── 503.html                   # Service Unavailable error page
```

## Quick Start

### Prerequisites

- Docker & Docker Compose installed
- A registered domain name (for Let's Encrypt)
- Port 80 and 443 available on your host

### 1. Configure Your Domain

Edit `docker-compose.yml` and set your domain and email:

```yaml
environment:
  DOMAIN: yourdomain.com
  EMAIL: your-email@example.com
```

### 2. Update Apache Configuration

Edit `apache-conf/reverse-proxy.conf` with your backend server addresses:

```apache
```

Update the `ServerName` and `ServerAlias` directives as well:

```apache
ServerName yourdomain.com
ServerAlias www.yourdomain.com
```

### 3. Build and Start

```bash
# Build the Docker image
docker-compose build

# Start the services
docker-compose up -d

# View logs
docker-compose logs -f apache-reverse-proxy
```

The container will:
1. Check if certificates exist
2. Request new certificates from Let's Encrypt if needed
3. Set up automatic renewal
4. Start Apache

## Configuration Details

### SSL/TLS Configuration

The setup uses modern, secure TLS settings:
- **Minimum TLS version**: 1.2
- **Ciphers**: ECDHE and DHE based (perfect forward secrecy)
- **HSTS**: Enabled with 1-year max age

### Reverse Proxy Behavior

The proxy configuration includes:
- **Preserve Host Header**: Backend receives original Host header
- **Keep-Alive**: Persistent connections to backends
- **Load Balancing**: Round-robin by default
- **Timeouts**:
  - Connect: 30 seconds
  - Total: 300 seconds
  - Buffer Size: 4KB

### Certificate Auto-Renewal

Certificates are renewed daily at 3 AM UTC via cron:

```bash
0 3 * * * /usr/bin/certbot renew --quiet --agree-tos && /usr/sbin/apache2ctl graceful
```

If you need to manually renew:

```bash
docker-compose exec apache-reverse-proxy certbot renew
```

## Advanced Configuration

### Using with Multiple Path-Based Backends

To route different paths to different backends:

```apache

<Location /api>
</Location>
```

### Customizing HTML Files

Edit files in the `html/` directory:
- `html/index.html` - Home page
- `html/error-pages/502.html` - Bad gateway errors
- `html/error-pages/503.html` - Service unavailable

Changes are picked up automatically after container restart.

### Enabling Additional Apache Modules

Add to the `RUN a2enmod` line in Dockerfile:

```dockerfile
RUN a2enmod rewrite \
    && a2enmod proxy \
    && a2enmod proxy_http \
    && a2enmod ssl \
    && a2enmod headers \
    && a2enmod your_module_here
```

## Logging

### Apache Logs

Access logs:
```bash
docker-compose exec apache-reverse-proxy tail -f /var/log/apache2/access.log
```

Error logs:
```bash
docker-compose exec apache-reverse-proxy tail -f /var/log/apache2/error.log
```

### Certificate Renewal Logs

```bash
docker-compose exec apache-reverse-proxy tail -f /var/log/certbot-renewal.log
```

## Troubleshooting

### Certificate not obtaining

1. **Ensure port 80 is accessible**:
   ```bash
   curl -I http://yourdomain.com/.well-known/acme-challenge/test
   ```

2. **Check DNS resolution**:
   ```bash
   docker-compose exec apache-reverse-proxy nslookup yourdomain.com
   ```

3. **View detailed logs**:
   ```bash
   docker-compose exec apache-reverse-proxy certbot -v renew
   ```

### 502 Bad Gateway Errors

- Check backend servers are running and accessible
- Verify backend addresses in `reverse-proxy.conf`
- Check backend logs for errors
- Increase timeouts if backends are slow

### Apache won't start

```bash
# Test configuration
docker-compose exec apache-reverse-proxy apache2ctl configtest

# View startup errors
docker-compose logs apache-reverse-proxy
```

## Performance Tuning

### Increase Worker Threads

Edit Dockerfile and add before the CMD:

```dockerfile
RUN echo "ServerLimit 256" >> /etc/apache2/mods-available/mpm_prefork.conf
RUN echo "MaxRequestWorkers 256" >> /etc/apache2/mods-available/mpm_prefork.conf
```

### Use Event MPM (Production)

Replace in Dockerfile:

```dockerfile
RUN a2dismod mpm_prefork && a2enmod mpm_event
```

## Backup & Restore

### Backup Certificates

```bash
docker cp apache-reverse-proxy:/etc/letsencrypt ./letsencrypt-backup
```

### Restore Certificates

```bash
docker cp ./letsencrypt-backup apache-reverse-proxy:/etc/letsencrypt
```

## Monitoring

### Health Check Status

```bash
docker-compose ps
```

Should show `(healthy)` status.

### Certificate Expiry

```bash
docker-compose exec apache-reverse-proxy certbot certificates
```

## Security Considerations

1. **Keep Docker images updated**: Regularly rebuild to get latest security patches
2. **Use strong Let's Encrypt email**: Use an email you actively monitor
3. **Restrict backend access**: Backends should only accept connections from proxy
4. **Monitor logs**: Watch for suspicious activity in access logs
5. **Firewall rules**: Only expose ports 80/443 to public, backend ports only to proxy

## Production Deployment

### Recommended Changes

1. Use a more robust process manager (supervisord)
2. Separate certificate renewal from main container
3. Use Docker secrets for sensitive data
4. Enable read-only root filesystem
5. Run as non-root user
6. Use external certificate storage (e.g., AWS Secrets Manager)

Example production-ready additions to Dockerfile:

```dockerfile
RUN useradd -m -s /sbin/nologin apache-user
USER apache-user
RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf
EXPOSE 8080 8443
```

## Contributing

Feel free to customize:
- Backend addresses and routing rules
- CSS styling of error pages
- Apache modules and configuration
- Cron schedule for certificate renewal

## License

Free to use and modify for your needs.

## Support

For issues:
1. Check the troubleshooting section
2. Review Apache error logs
3. Verify Docker network connectivity
4. Test Let's Encrypt directly with certbot
