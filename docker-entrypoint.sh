#!/bin/bash
set -e

# Ensure proper permissions on mounted volumes
chmod -R 755 /etc/letsencrypt 2>/dev/null || true
chmod -R 777 /var/log/apache2 2>/dev/null || true
mkdir -p /etc/letsencrypt/live 2>/dev/null || true

# Configuration
DOMAIN="${DOMAIN:-example.com}"
EMAIL="${EMAIL:-admin@example.com}"
CERTBOT_WEBROOT="${CERTBOT_WEBROOT:-/var/www/letsencrypt}"

echo "=== Apache & Let's Encrypt Setup ==="
echo "Domain: $DOMAIN"
echo "Email: $EMAIL"

# Generate Apache configuration from template based on environment variables
echo "Generating Apache configuration with enabled services..."
/usr/local/bin/generate-config.sh \
    /etc/apache2/sites-available/reverse-proxy.conf.template \
    /etc/apache2/sites-available/reverse-proxy.conf

# Download and resize app icons from provided URLs
echo ""
/usr/local/bin/download-icons.sh

# Generate HTML dashboard menu based on enabled services
echo ""
echo "Generating dashboard menu based on enabled services..."
/usr/local/bin/generate-html-menu.sh

# Enable reverse proxy site
a2ensite reverse-proxy.conf 2>/dev/null || true

# Office 365 / Azure AD Authentication Setup
if [ "${ENABLE_AUTH_OFFICE365}" = "true" ]; then
    echo "=== Setting up Office 365 Authentication ==="
    
    # Validate required OAuth2 parameters
    if [ -z "$OAUTH2_CLIENT_ID" ] || [ -z "$OAUTH2_CLIENT_SECRET" ]; then
        echo "ERROR: OAUTH2_CLIENT_ID and OAUTH2_CLIENT_SECRET are required for Office 365 auth"
        echo "Please set these environment variables in docker-compose.yml"
        exit 1
    fi
    
    # Generate crypto passphrase if not provided
    if [ -z "$OAUTH2_CRYPTO_PASSPHRASE" ]; then
        OAUTH2_CRYPTO_PASSPHRASE=$(openssl rand -base64 24)
        echo "Generated random crypto passphrase"
    fi
    
    # Update OAuth2 configuration with actual values
    echo "Configuring Office 365 OAuth2 settings..."
    
    # Create temp oauth2 config with actual values
    cat /etc/apache2/conf-available/oauth2-office365.conf \
        | sed "s|@@CRYPTO_PASSPHRASE@@|$OAUTH2_CRYPTO_PASSPHRASE|g" \
        > /etc/apache2/conf-enabled/oauth2-office365.conf
    
    # Enable auth protection
    cp /etc/apache2/conf-available/auth-office365-protect.conf /etc/apache2/conf-enabled/
    
    # Enable the auth config
    a2enconf oauth2-office365 2>/dev/null || true
    a2enconf auth-office365-protect 2>/dev/null || true
    
    echo "Office 365 Authentication configured"
    echo "  Client ID: ${OAUTH2_CLIENT_ID:0:20}..."
    echo "  Redirect URI: $OAUTH2_REDIRECT_URI"
    echo "  Allowed Domains: $OAUTH2_ALLOWED_DOMAINS"
else
    echo "Office 365 Authentication is disabled (ENABLE_AUTH_OFFICE365=false)"
fi

# Function to wait for certificate
wait_for_cert() {
    local domain=$1
    local max_wait=60
    local elapsed=0
    
    echo "Waiting for certificate for $domain..."
    while [ $elapsed -lt $max_wait ]; do
        if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
            echo "Certificate found for $domain"
            return 0
        fi
        sleep 1
        ((elapsed++))
    done
    
    echo "Warning: Certificate not found after $max_wait seconds"
    return 1
}



# Update Apache configuration with actual domain
if [ "$DOMAIN" != "example.com" ]; then
    echo "Updating Apache configuration with domain: $DOMAIN"
    sed -i "s/example\.com/$DOMAIN/g" /etc/apache2/sites-available/reverse-proxy.conf
fi

# Setup cron for certificate renewal
echo "Setting up certificate renewal cron job..."
if ! crontab -l 2>/dev/null | grep -q "certbot renew"; then
    (crontab -l 2>/dev/null; echo "0 3 * * * /usr/bin/certbot renew --webroot --webroot-path $CERTBOT_WEBROOT --quiet && /usr/sbin/apache2ctl graceful") | crontab -
fi

# Start cron daemon
echo "Starting cron daemon for certificate renewal..."
service cron start

# Test Apache configuration
echo "Testing Apache configuration..."
apache2ctl configtest || {
    echo "Apache configuration error!"
    exit 1
}

echo "=== Starting Apache ==="
exec "$@"
