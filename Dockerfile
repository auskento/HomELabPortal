FROM debian:13-slim

# Set timezone to Melbourne
ENV TZ=Australia/Melbourne

# Install Apache, Certbot, and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    certbot \
    python3-certbot-apache \
    curl \
    wget \
    cron \
    vim \
    net-tools \
    imagemagick \
    file \
    tzdata \
    libapache2-mod-auth-openidc \
    && rm -rf /var/lib/apt/lists/*

# Enable necessary Apache modules for reverse proxy, SSL, and authentication
RUN a2enmod rewrite \
    && a2enmod proxy \
    && a2enmod proxy_http \
    && a2enmod ssl \
    && a2enmod headers \
    && a2enmod auth_openidc \
    && a2enmod auth_basic \
    && a2enmod session_crypto \
    && a2enmod filter \
    && a2enmod substitute

# Create directories
RUN mkdir -p /var/www/html/error-pages \
    && mkdir -p /var/www/letsencrypt \
    && mkdir -p /etc/apache2/sites-available \
    && mkdir -p /etc/letsencrypt \
    && mkdir -p /etc/letsencrypt/live \
    && mkdir -p /var/log/apache2 \
    && mkdir -p /var/log/apache2/reverse-proxy-debug \
    && mkdir -p /var/log/apache2/sites \
    && chmod -R 777 /etc/letsencrypt \
    && chmod 777 /etc/letsencrypt/live \
    && chmod -R 777 /var/log/apache2

# Copy custom HTML files (including subdirectories)
COPY html /var/www/html
RUN chmod -R 755 /var/www/html && \
    find /var/www/html -type f -exec chmod 644 {} \;

# Copy pre-cached site favicons
COPY html/sites-icons/* /var/log/apache2/sites/ 2>/dev/null || true
RUN chmod 644 /var/log/apache2/sites/*.favicon.ico 2>/dev/null || true

# Copy Apache configuration
COPY apache-conf/reverse-proxy.conf.template /etc/apache2/sites-available/reverse-proxy.conf.template
COPY apache-conf/ssl-config.conf /etc/apache2/mods-available/ssl-params.conf
COPY apache-conf/oauth2-entra.conf /etc/apache2/conf-available/
COPY apache-conf/auth-entra-protect.conf /etc/apache2/conf-available/
COPY apache-conf/oauth2-google.conf /etc/apache2/conf-available/
COPY apache-conf/auth-google-protect.conf /etc/apache2/conf-available/
COPY apache-conf/auth-basic.conf /etc/apache2/conf-available/
COPY apache-conf/services/ /etc/apache2/sites-available/services/

# Copy configuration generator scripts
COPY generate-config.sh generate-html-menu.sh download-icons.sh generate-sites-config.sh generate-emby-virtualhost.sh generate-plex-virtualhost.sh apache-log-rotator.sh /usr/local/bin/
COPY support.js /usr/local/bin/
RUN chmod +x /usr/local/bin/generate-config.sh /usr/local/bin/generate-html-menu.sh /usr/local/bin/download-icons.sh /usr/local/bin/generate-sites-config.sh /usr/local/bin/generate-emby-virtualhost.sh /usr/local/bin/generate-plex-virtualhost.sh /usr/local/bin/apache-log-rotator.sh

# Copy icon download script
COPY download-icons.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/download-icons.sh

# Disable default site (will enable reverse proxy config in entrypoint)
RUN a2dissite 000-default.conf

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create renewal check script
RUN mkdir -p /etc/cron.d
COPY cert-renewal-cron /etc/cron.d/certbot-renewal
RUN chmod 0644 /etc/cron.d/certbot-renewal

# Expose ports
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2ctl", "-D", "FOREGROUND"]
