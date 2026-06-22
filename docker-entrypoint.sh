#!/bin/bash
set -e

# Ensure proper permissions on mounted volumes (world-writable)
chmod -R 777 /etc/letsencrypt 2>/dev/null || true
chmod 777 /etc/letsencrypt/live 2>/dev/null || true
mkdir -p /etc/letsencrypt/live 2>/dev/null || true
chmod 777 /etc/letsencrypt/live 2>/dev/null || true
chmod -R 777 /var/log/apache2 2>/dev/null || true

# Write environment variables to config file for scripts to source
cat > /etc/apache2/env.conf << ENVEOF
DOMAIN="${DOMAIN:-example.com}"
EMAIL="${EMAIL:-admin@example.com}"
STYLE="${STYLE:-classic}"
ENABLE_SONARR="${ENABLE_SONARR:-false}"
ENABLE_RADARR="${ENABLE_RADARR:-false}"
ENABLE_WHISPARR="${ENABLE_WHISPARR:-false}"
ENABLE_LIDARR="${ENABLE_LIDARR:-false}"
ENABLE_READARR="${ENABLE_READARR:-false}"
ENABLE_PROWLARR="${ENABLE_PROWLARR:-false}"
ENABLE_OVERSEERR="${ENABLE_OVERSEERR:-false}"
ENABLE_JELLYFIN="${ENABLE_JELLYFIN:-false}"
ENABLE_EMBY="${ENABLE_EMBY:-false}"
ENABLE_PLEX="${ENABLE_PLEX:-false}"
ENABLE_TAUTULLI="${ENABLE_TAUTULLI:-false}"
ENABLE_TRANSMISSION="${ENABLE_TRANSMISSION:-false}"
ENABLE_QBITTORRENT="${ENABLE_QBITTORRENT:-false}"
ENABLE_SABNZBD="${ENABLE_SABNZBD:-false}"
ENABLE_DELUGE="${ENABLE_DELUGE:-false}"
ENABLE_AUTH_OFFICE365="${ENABLE_AUTH_OFFICE365:-false}"
ENABLE_BASIC_AUTH="${ENABLE_BASIC_AUTH:-false}"
BASIC_AUTH_CREDENTIALS="${BASIC_AUTH_CREDENTIALS:-}"
SONARR_URL="${SONARR_URL:-}"
RADARR_URL="${RADARR_URL:-}"
WHISPARR_URL="${WHISPARR_URL:-}"
LIDARR_URL="${LIDARR_URL:-}"
PROWLARR_URL="${PROWLARR_URL:-}"
OVERSEERR_URL="${OVERSEERR_URL:-}"
JELLYFIN_URL="${JELLYFIN_URL:-}"
EMBY_URL="${EMBY_URL:-}"
EMBY_DOMAIN="${EMBY_DOMAIN:-}"
PLEX_URL="${PLEX_URL:-}"
PLEX_DOMAIN="${PLEX_DOMAIN:-}"
TAUTULLI_URL="${TAUTULLI_URL:-}"
TRANSMISSION_URL="${TRANSMISSION_URL:-}"
QBITTORRENT_URL="${QBITTORRENT_URL:-}"
SABNZBD_URL="${SABNZBD_URL:-}"
DELUGE_URL="${DELUGE_URL:-}"
ENVEOF

echo ""
echo "=== Environment Configuration ===" 
cat /etc/apache2/env.conf
echo "=================================="
echo ""

echo ""
echo "=== Setting Global ServerName ==="
# Set global ServerName to suppress the warning
if ! grep -q "^ServerName" /etc/apache2/apache2.conf; then
    echo "ServerName $DOMAIN" >> /etc/apache2/apache2.conf
    echo "Added ServerName: $DOMAIN"
fi

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

# Enable required Apache modules for OAuth2 and Basic Auth
echo "Enabling Apache modules..."
a2enmod auth_openidc 2>/dev/null || true
a2enmod auth_basic 2>/dev/null || true
a2enmod authn_file 2>/dev/null || true
a2enmod proxy 2>/dev/null || true
a2enmod proxy_http 2>/dev/null || true
a2enmod headers 2>/dev/null || true
a2enmod rewrite 2>/dev/null || true
a2enmod ssl 2>/dev/null || true
a2enmod session 2>/dev/null || true
a2enmod session_crypto 2>/dev/null || true

# Check if auth_openidc module file exists
if [ -f /usr/lib/apache2/modules/mod_auth_openidc.so ]; then
    echo "✓ auth_openidc module file found and enabled"
else
    echo "✗ WARNING: auth_openidc module file NOT found"
fi

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
        | sed "s|@@OAUTH2_CLIENT_ID@@|$OAUTH2_CLIENT_ID|g" \
        | sed "s|@@OAUTH2_CLIENT_SECRET@@|$OAUTH2_CLIENT_SECRET|g" \
        | sed "s|@@OAUTH2_REDIRECT_URI@@|$OAUTH2_REDIRECT_URI|g" \
        | sed "s|@@OIDC_PROVIDER_METADATA_URL@@|$OIDC_PROVIDER_METADATA_URL|g" \
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
    # Disable OAuth2 configs if they were previously enabled
    a2disconf oauth2-office365 2>/dev/null || true
    a2disconf auth-office365-protect 2>/dev/null || true
    rm -f /etc/apache2/conf-enabled/oauth2-office365.conf
    rm -f /etc/apache2/conf-enabled/auth-office365-protect.conf
fi

# Basic Authentication Setup
if [ "${ENABLE_BASIC_AUTH}" = "true" ]; then
    echo "=== Setting up Basic Authentication ==="

    # Validate required parameters
    if [ -z "$BASIC_AUTH_CREDENTIALS" ]; then
        echo "ERROR: BASIC_AUTH_CREDENTIALS is required when ENABLE_BASIC_AUTH=true"
        echo "Format: username:password|username2:password2 (pipe-separated pairs)"
        exit 1
    fi

    # Create .htpasswd file
    HTPASSWD_FILE="/etc/apache2/.htpasswd"
    > "$HTPASSWD_FILE"  # Clear the file

    # Parse credentials and add to .htpasswd
    IFS='|' read -ra CREDENTIALS_ARRAY <<< "$BASIC_AUTH_CREDENTIALS"
    for credential in "${CREDENTIALS_ARRAY[@]}"; do
        IFS=':' read -r username password <<< "$credential"
        if [ -z "$username" ] || [ -z "$password" ]; then
            echo "ERROR: Invalid credential format. Expected 'username:password'"
            exit 1
        fi
        # Use htpasswd to create bcrypt hash (most secure)
        htpasswd -bB "$HTPASSWD_FILE" "$username" "$password" 2>/dev/null || {
            echo "ERROR: Failed to create htpasswd entry for user: $username"
            exit 1
        }
        echo "✓ Added user to basic auth: $username"
    done

    # Set proper permissions
    chmod 640 "$HTPASSWD_FILE"

    # Enable the auth-basic config (it's already in conf-available from Dockerfile)
    if [ -f /etc/apache2/conf-available/auth-basic.conf ]; then
        cp /etc/apache2/conf-available/auth-basic.conf /etc/apache2/conf-enabled/auth-basic.conf
        echo "✓ Basic auth configuration enabled"
    else
        echo "ERROR: auth-basic.conf not found in /etc/apache2/conf-available/"
        exit 1
    fi

    echo "Basic Authentication configured with credentials from BASIC_AUTH_CREDENTIALS"
else
    echo "Basic Authentication is disabled (ENABLE_BASIC_AUTH=false)"
    # Disable basic auth if it was previously enabled
    rm -f /etc/apache2/conf-enabled/auth-basic.conf
    rm -f /etc/apache2/.htpasswd
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



# Check if certificate exists, if not generate it
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo ""
    echo "=== Obtaining Let's Encrypt Certificate ==="
    
    # Ensure directory exists
    mkdir -p "/etc/letsencrypt/live/$DOMAIN"
    
    # Obtain certificate using standalone method
    echo "Requesting certificate from Let's Encrypt for $DOMAIN..."
    certbot certonly \
        --standalone \
        --preferred-challenges http \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        --non-interactive \
        -d "$DOMAIN" \
        || {
            echo "Certbot failed. Generating self-signed certificate as fallback..."
            
            # Ensure directory exists
            mkdir -p "/etc/letsencrypt/live/$DOMAIN"
            
            # Generate self-signed certificate
            openssl req -x509 -nodes -days 365 \
                -newkey rsa:2048 \
                -keyout "/etc/letsencrypt/live/$DOMAIN/privkey.pem" \
                -out "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" \
                -subj "/C=AU/ST=Victoria/L=Melbourne/O=Org/CN=$DOMAIN" \
                2>/dev/null || true
            
            echo "Self-signed certificate generated"
        }
else
    echo ""
    echo "Certificate found for $DOMAIN"
fi

# Handle Emby subdomain if enabled
if [ "${ENABLE_EMBY}" = "true" ]; then
    # Use provided EMBY_DOMAIN or skip
    if [ -z "$EMBY_DOMAIN" ]; then
        echo "WARNING: ENABLE_EMBY=true but EMBY_DOMAIN not set. Skipping Emby subdomain setup."
    else
        echo ""
        echo "=== Emby Subdomain Setup ==="
        echo "Emby domain: $EMBY_DOMAIN"
        
        if [ ! -f "/etc/letsencrypt/live/$EMBY_DOMAIN/fullchain.pem" ]; then
            echo "Requesting certificate for $EMBY_DOMAIN..."
            certbot certonly \
                --standalone \
                --preferred-challenges http \
                --email "$EMAIL" \
                --agree-tos \
                --no-eff-email \
                --non-interactive \
                -d "$EMBY_DOMAIN" \
                || {
                    echo "Certbot failed for Emby. Generating self-signed certificate..."
                    mkdir -p "/etc/letsencrypt/live/$EMBY_DOMAIN"
                    openssl req -x509 -nodes -days 365 \
                        -newkey rsa:2048 \
                        -keyout "/etc/letsencrypt/live/$EMBY_DOMAIN/privkey.pem" \
                        -out "/etc/letsencrypt/live/$EMBY_DOMAIN/fullchain.pem" \
                        -subj "/C=AU/ST=Victoria/L=Melbourne/O=Org/CN=$EMBY_DOMAIN" \
                        2>/dev/null || true
                }
        else
            echo "Certificate found for $EMBY_DOMAIN"
        fi
        
        # Generate Emby VirtualHost with proper variable substitution
        EMBY_HOST=$(echo "$EMBY_URL" | sed 's|^https*://||;s|/.*||;s|:.*||')
        EMBY_PORT=$(echo "$EMBY_URL" | grep -oP ':\K[0-9]+' | head -1)
        [ -z "$EMBY_PORT" ] && EMBY_PORT="8096"
        
        echo "DEBUG Emby: URL=$EMBY_URL, HOST=$EMBY_HOST, PORT=$EMBY_PORT, DOMAIN=$EMBY_DOMAIN"
        
        EMBY_CONFIG=$(/usr/local/bin/generate-emby-virtualhost.sh "$EMBY_DOMAIN" "$ENABLE_AUTH_OFFICE365")
        EMBY_CONFIG="${EMBY_CONFIG//@@EMBY_DOMAIN@@/$EMBY_DOMAIN}"
        EMBY_CONFIG="${EMBY_CONFIG//@@EMBY_HOST@@/$EMBY_HOST}"
        EMBY_CONFIG="${EMBY_CONFIG//@@EMBY_PORT@@/$EMBY_PORT}"
        EMBY_CONFIG="${EMBY_CONFIG//@@OAUTH2_CLIENT_ID@@/$OAUTH2_CLIENT_ID}"
        EMBY_CONFIG="${EMBY_CONFIG//@@OAUTH2_CLIENT_SECRET@@/$OAUTH2_CLIENT_SECRET}"
        EMBY_CONFIG="${EMBY_CONFIG//@@OIDC_PROVIDER_METADATA_URL@@/$OIDC_PROVIDER_METADATA_URL}"
        EMBY_CONFIG="${EMBY_CONFIG//@@OAUTH2_CRYPTO_PASSPHRASE@@/$OAUTH2_CRYPTO_PASSPHRASE}"
        echo "$EMBY_CONFIG" > /etc/apache2/sites-available/emby-subdomain.conf
        a2ensite emby-subdomain.conf 2>/dev/null || true
        echo "Emby VirtualHost created with: $EMBY_HOST:$EMBY_PORT"
    fi
fi

# Handle Plex subdomain if enabled
if [ "${ENABLE_PLEX}" = "true" ]; then
    # Use provided PLEX_DOMAIN or skip
    if [ -z "$PLEX_DOMAIN" ]; then
        echo "WARNING: ENABLE_PLEX=true but PLEX_DOMAIN not set. Skipping Plex subdomain setup."
    else
        echo ""
        echo "=== Plex Subdomain Setup ==="
        echo "Plex domain: $PLEX_DOMAIN"
        
        if [ ! -f "/etc/letsencrypt/live/$PLEX_DOMAIN/fullchain.pem" ]; then
            echo "Requesting certificate for $PLEX_DOMAIN..."
            certbot certonly \
                --standalone \
                --preferred-challenges http \
                --email "$EMAIL" \
                --agree-tos \
                --no-eff-email \
                --non-interactive \
                -d "$PLEX_DOMAIN" \
                || {
                    echo "Certbot failed for Plex. Generating self-signed certificate..."
                    mkdir -p "/etc/letsencrypt/live/$PLEX_DOMAIN"
                    openssl req -x509 -nodes -days 365 \
                        -newkey rsa:2048 \
                        -keyout "/etc/letsencrypt/live/$PLEX_DOMAIN/privkey.pem" \
                        -out "/etc/letsencrypt/live/$PLEX_DOMAIN/fullchain.pem" \
                        -subj "/C=AU/ST=Victoria/L=Melbourne/O=Org/CN=$PLEX_DOMAIN" \
                        2>/dev/null || true
                }
        else
            echo "Certificate found for $PLEX_DOMAIN"
        fi
        
        # Generate Plex VirtualHost with proper variable substitution
        PLEX_HOST=$(echo "$PLEX_URL" | sed 's|^https*://||;s|/.*||;s|:.*||')
        PLEX_PORT=$(echo "$PLEX_URL" | grep -oP ':\K[0-9]+' | head -1)
        [ -z "$PLEX_PORT" ] && PLEX_PORT="32400"
        
        echo "DEBUG Plex: URL=$PLEX_URL, HOST=$PLEX_HOST, PORT=$PLEX_PORT, DOMAIN=$PLEX_DOMAIN"
        
        PLEX_CONFIG=$(/usr/local/bin/generate-plex-virtualhost.sh "$PLEX_DOMAIN" "$ENABLE_AUTH_OFFICE365")
        PLEX_CONFIG="${PLEX_CONFIG//@@PLEX_DOMAIN@@/$PLEX_DOMAIN}"
        PLEX_CONFIG="${PLEX_CONFIG//@@PLEX_HOST@@/$PLEX_HOST}"
        PLEX_CONFIG="${PLEX_CONFIG//@@PLEX_PORT@@/$PLEX_PORT}"
        PLEX_CONFIG="${PLEX_CONFIG//@@OAUTH2_CLIENT_ID@@/$OAUTH2_CLIENT_ID}"
        PLEX_CONFIG="${PLEX_CONFIG//@@OAUTH2_CLIENT_SECRET@@/$OAUTH2_CLIENT_SECRET}"
        PLEX_CONFIG="${PLEX_CONFIG//@@OIDC_PROVIDER_METADATA_URL@@/$OIDC_PROVIDER_METADATA_URL}"
        PLEX_CONFIG="${PLEX_CONFIG//@@OAUTH2_CRYPTO_PASSPHRASE@@/$OAUTH2_CRYPTO_PASSPHRASE}"
        echo "$PLEX_CONFIG" > /etc/apache2/sites-available/plex-subdomain.conf
        a2ensite plex-subdomain.conf 2>/dev/null || true
        echo "Plex VirtualHost created with: $PLEX_HOST:$PLEX_PORT"
        echo "Plex VirtualHost created"
    fi
fi

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
echo ""
echo "=== Generated reverse-proxy.conf ===" 
cat /etc/apache2/sites-available/reverse-proxy.conf
echo "===================================="
echo ""
apache2ctl configtest || {
    echo "Apache configuration error!"
    exit 1
}

echo "=== Starting Apache ==="

# Debug logging - save generated files
DEBUG_DIR="/var/log/apache-reverse-proxy-debug/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DEBUG_DIR"
cp /etc/apache2/env.conf "$DEBUG_DIR/" 2>/dev/null || true
cp /etc/apache2/sites-available/reverse-proxy.conf "$DEBUG_DIR/" 2>/dev/null || true
cp /etc/apache2/sites-enabled/reverse-proxy.conf "$DEBUG_DIR/" 2>/dev/null || true
echo "Debug files saved to: $DEBUG_DIR"

# Trap signals to gracefully shut down cron and Apache
trap 'echo "Shutting down..."; service cron stop 2>/dev/null; kill ${APACHE_PID} 2>/dev/null; wait ${APACHE_PID} 2>/dev/null; exit 0' SIGTERM SIGINT

# Start Apache in foreground and capture PID
apache2ctl -D FOREGROUND &
APACHE_PID=$!

# Wait for Apache process
wait ${APACHE_PID}
