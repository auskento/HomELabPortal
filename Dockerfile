FROM debian:12

# Install Apache, Certbot, and dependencies
RUN apt-get update && apt-get install -y \
    apache2 \
    certbot \
    python3-certbot-apache \
    curl \
    wget \
    cron \
    vim \
    net-tools \
    imagemagick \
    && rm -rf /var/lib/apt/lists/*

# Install OpenID Connect authentication module for Office 365
RUN apt-get install -y libapache2-mod-auth-openidc

# Enable necessary Apache modules for reverse proxy and SSL
RUN a2enmod rewrite \
    && a2enmod proxy \
    && a2enmod proxy_http \
    && a2enmod ssl \
    && a2enmod headers \
    && a2enmod auth_openidc \
    && a2enmod session_crypto

# Create directories
RUN mkdir -p /var/www/html/error-pages \
    && mkdir -p /var/www/letsencrypt \
    && mkdir -p /etc/apache2/sites-available

# Copy custom HTML files
COPY html/ /var/www/html/

# Copy Apache configuration
COPY apache-conf/reverse-proxy.conf.template /etc/apache2/sites-available/reverse-proxy.conf.template
COPY apache-conf/ssl-config.conf /etc/apache2/mods-available/ssl-params.conf
COPY apache-conf/oauth2-office365.conf /etc/apache2/conf-available/
COPY apache-conf/auth-office365-protect.conf /etc/apache2/conf-available/
COPY apache-conf/services/ /etc/apache2/sites-available/services/

# Copy configuration generator script
COPY generate-config.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/generate-config.sh

# Copy HTML menu generator script
COPY generate-html-menu.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/generate-html-menu.sh

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
