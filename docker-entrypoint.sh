#!/bin/bash
set -e

# Ensure proper permissions on mounted volumes (world-writable)
chmod -R 777 /etc/letsencrypt 2>/dev/null || true
chmod 777 /etc/letsencrypt/live 2>/dev/null || true
mkdir -p /etc/letsencrypt/live 2>/dev/null || true
chmod 777 /etc/letsencrypt/live 2>/dev/null || true
chmod -R 777 /var/log/apache2 2>/dev/null || true

# Ensure debug log directory exists and has proper permissions
mkdir -p /var/log/apache2/reverse-proxy-debug || {
    echo "ERROR: Failed to create /var/log/apache2/reverse-proxy-debug directory"
    exit 1
}
chmod 777 /var/log/apache2/reverse-proxy-debug || {
    echo "ERROR: Failed to set permissions on /var/log/apache2/reverse-proxy-debug"
    exit 1
}

# Load persistent dashboard configuration if it exists
# This allows changing UI style and landing page without rebuilding the image
if [ -f /etc/apache2/dashboard.conf ]; then
    echo "Loading persistent dashboard configuration..."
    source /etc/apache2/dashboard.conf
    echo "DEBUG: Loaded STYLE=$STYLE, DASHBOARD_LANDING=$DASHBOARD_LANDING"
fi

# Write environment variables to config file for scripts to source
cat > /etc/apache2/env.conf << ENVEOF
ACCESS_MODE="${ACCESS_MODE:-public}"
DOMAIN="${DOMAIN:-example.com}"
EMAIL="${EMAIL:-admin@example.com}"
STYLE="${STYLE:-classic}"
ENABLE_SONARR="${ENABLE_SONARR:-false}"
ENABLE_RADARR="${ENABLE_RADARR:-false}"
ENABLE_WHISPARR="${ENABLE_WHISPARR:-false}"
ENABLE_LIDARR="${ENABLE_LIDARR:-false}"
ENABLE_READARR="${ENABLE_READARR:-false}"
ENABLE_PROWLARR="${ENABLE_PROWLARR:-false}"
ENABLE_SEERR="${ENABLE_SEERR:-false}"
ENABLE_JELLYFIN="${ENABLE_JELLYFIN:-false}"
ENABLE_EMBY="${ENABLE_EMBY:-false}"
ENABLE_PLEX="${ENABLE_PLEX:-false}"
ENABLE_TAUTULLI="${ENABLE_TAUTULLI:-false}"
ENABLE_TRANSMISSION="${ENABLE_TRANSMISSION:-false}"
ENABLE_QBITTORRENT="${ENABLE_QBITTORRENT:-false}"
ENABLE_SABNZBD="${ENABLE_SABNZBD:-false}"
ENABLE_DELUGE="${ENABLE_DELUGE:-false}"
ENABLE_NZBGET="${ENABLE_NZBGET:-false}"
ENABLE_NZBHYDRA="${ENABLE_NZBHYDRA:-false}"
AUTHTYPE="${AUTHTYPE:-none}"
BASIC_AUTH_CREDENTIALS="${BASIC_AUTH_CREDENTIALS:-}"
ENTRA_CLIENT_ID="${ENTRA_CLIENT_ID:-}"
ENTRA_CLIENT_SECRET="${ENTRA_CLIENT_SECRET:-}"
ENTRA_REDIRECT_URI="${ENTRA_REDIRECT_URI:-}"
ENTRA_PROVIDER_METADATA_URL="${ENTRA_PROVIDER_METADATA_URL:-}"
ENTRA_CRYPTO_PASSPHRASE="${ENTRA_CRYPTO_PASSPHRASE:-}"
GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-}"
GOOGLE_CLIENT_SECRET="${GOOGLE_CLIENT_SECRET:-}"
GOOGLE_REDIRECT_URI="${GOOGLE_REDIRECT_URI:-}"
SONARR_URL="${SONARR_URL:-}"
RADARR_URL="${RADARR_URL:-}"
WHISPARR_URL="${WHISPARR_URL:-}"
LIDARR_URL="${LIDARR_URL:-}"
PROWLARR_URL="${PROWLARR_URL:-}"
SEERR_URL="${SEERR_URL:-}"
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
NZBGET_URL="${NZBGET_URL:-}"
NZBGET_USER="${NZBGET_USER:-}"
NZBGET_PASS="${NZBGET_PASS:-}"
NZBHYDRA_URL="${NZBHYDRA_URL:-}"
DASHBOARD_ICON="${DASHBOARD_ICON:-/icons/apache-reverse-proxy.png}"
DASHBOARD_LANDING="${DASHBOARD_LANDING:-}"
DASHBOARD_ORDER="${DASHBOARD_ORDER:-DOWNLOADS,INFRA,MEDIA}"
ENVEOF

echo ""
echo "=== Environment Configuration ==="
cat /etc/apache2/env.conf
echo "DEBUG: Checking ENABLE_BASIC_AUTH in env.conf:"
grep "ENABLE_BASIC_AUTH" /etc/apache2/env.conf || echo "DEBUG: ENABLE_BASIC_AUTH not found in env.conf!"
echo "=================================="
echo ""

# Source env.conf to load defaults for variables not set in environment
source /etc/apache2/env.conf

echo ""
echo "=== Setting Global ServerName ==="
# Set global ServerName to suppress the warning
if ! grep -q "^ServerName" /etc/apache2/apache2.conf; then
    echo "ServerName $DOMAIN" >> /etc/apache2/apache2.conf
    echo "Added ServerName: $DOMAIN"
fi

# Update env.conf with modified STYLE (in case basic auth forced it to classic)
sed -i "s/^STYLE=.*/STYLE=\"${STYLE}\"/" /etc/apache2/env.conf

# Configuration - clean up ACCESS_MODE if it was set
ACCESS_MODE=$(echo "${ACCESS_MODE}" | tr '[:upper:]' '[:lower:]' | sed "s/'//g" | sed 's/"//g' | xargs)
DOMAIN="${DOMAIN:-example.com}"
EMAIL="${EMAIL:-admin@example.com}"
CERTBOT_WEBROOT="${CERTBOT_WEBROOT:-/var/www/letsencrypt}"

echo "=== Deployment Mode Setup ==="
echo "Access Mode: $ACCESS_MODE"

# Determine deployment mode and set SKIP_CERT_GENERATION accordingly
if [ "$ACCESS_MODE" = "private" ]; then
    echo "✓ Private mode - Internal dashboard only"
    SKIP_CERT_GENERATION=true

    # Validate that only none or basic auth are used in private mode
    if [ "$AUTHTYPE" != "none" ] && [ "$AUTHTYPE" != "basic" ]; then
        echo "ERROR: Private mode only supports 'none' or 'basic' authentication"
        echo "Provided AUTHTYPE: $AUTHTYPE"
        exit 1
    fi

    echo "Domain: $DOMAIN (not used for certificates)"
elif [ "$ACCESS_MODE" = "public" ]; then
    echo "✓ Public mode - Full features enabled"
    SKIP_CERT_GENERATION=false
    echo "Domain: $DOMAIN"
    echo "Email: $EMAIL"
else
    echo "ERROR: Invalid ACCESS_MODE: $ACCESS_MODE"
    echo "Valid options: private, public"
    exit 1
fi

echo ""
echo "=== Apache Setup ==="
echo "Style: $STYLE (Auth: $AUTHTYPE)"

# Generate Apache configuration from template based on environment variables
echo "Generating Apache configuration with enabled services..."
/usr/local/bin/generate-config.sh \
    /etc/apache2/sites-available/reverse-proxy.conf.template \
    /etc/apache2/sites-available/reverse-proxy.conf

# Download and resize app icons from provided URLs
echo ""
/usr/local/bin/download-icons.sh

# Generate HTML dashboard based on enabled services and STYLE
echo ""
echo "Generating dashboard menu based on enabled services..."
/usr/local/bin/generate-html-menu.sh

# Enable reverse proxy site
a2ensite reverse-proxy.conf 2>/dev/null || true

# Enable required Apache modules for OAuth2 and Basic Auth
echo "Enabling Apache modules..."
a2enmod auth_openidc 2>/dev/null || true
a2enmod auth_basic 2>/dev/null || true
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

# Normalize AUTHTYPE value (handle case and quotes)
AUTHTYPE=$(echo "${AUTHTYPE}" | tr '[:upper:]' '[:lower:]' | sed "s/'//g" | sed 's/"//g' | xargs)
echo "DEBUG: AUTHTYPE='${AUTHTYPE}'"

# Force classic style for basic auth (basic auth doesn't support modern dashboards)
if [ "$AUTHTYPE" = "basic" ]; then
    STYLE="classic"
    echo "INFO: Basic auth requires STYLE=classic (modern dashboards require session management)"
fi

# Authentication Setup - Mutually Exclusive
case "${AUTHTYPE}" in
    basic)
        echo "=== Setting up Basic Authentication ==="

        # Validate required parameters
        if [ -z "$BASIC_AUTH_CREDENTIALS" ]; then
            echo "ERROR: BASIC_AUTH_CREDENTIALS is required when AUTHTYPE=basic"
            echo "Format: username:password|username2:password2 (pipe-separated pairs)"
            exit 1
        fi

        # Create .htpasswd file
        HTPASSWD_FILE="/etc/apache2/.htpasswd"
        > "$HTPASSWD_FILE"

        # Parse credentials and add to .htpasswd
        IFS='|' read -ra CREDENTIALS_ARRAY <<< "$BASIC_AUTH_CREDENTIALS"
        for credential in "${CREDENTIALS_ARRAY[@]}"; do
            IFS=':' read -r username password <<< "$credential"
            if [ -z "$username" ] || [ -z "$password" ]; then
                echo "ERROR: Invalid credential format. Expected 'username:password'"
                exit 1
            fi
            htpasswd -bB "$HTPASSWD_FILE" "$username" "$password" 2>/dev/null || {
                echo "ERROR: Failed to create htpasswd entry for user: $username"
                exit 1
            }
            echo "✓ Added user to basic auth: $username"
        done

        # Set proper permissions
        chown root:www-data "$HTPASSWD_FILE"
        chmod 640 "$HTPASSWD_FILE"

        # Enable basic auth config
        if [ -f /etc/apache2/conf-available/auth-basic.conf ]; then
            cp /etc/apache2/conf-available/auth-basic.conf /etc/apache2/conf-enabled/auth-basic.conf
            echo "✓ Basic authentication enabled"
        else
            echo "ERROR: auth-basic.conf not found"
            exit 1
        fi

        # Disable OAuth2
        a2disconf oauth2-office365 2>/dev/null || true
        a2disconf auth-office365-protect 2>/dev/null || true
        rm -f /etc/apache2/conf-enabled/oauth2-office365.conf
        rm -f /etc/apache2/conf-enabled/auth-office365-protect.conf
        ;;

    entra)
        echo "=== Setting up Entra ID (Microsoft) Authentication ==="

        # Validate required parameters
        if [ -z "$ENTRA_CLIENT_ID" ] || [ -z "$ENTRA_CLIENT_SECRET" ] || [ -z "$ENTRA_PROVIDER_METADATA_URL" ]; then
            echo "ERROR: ENTRA_CLIENT_ID, ENTRA_CLIENT_SECRET, and ENTRA_PROVIDER_METADATA_URL are required for AUTHTYPE=entra"
            exit 1
        fi

        # Generate crypto passphrase if not provided
        if [ -z "$ENTRA_CRYPTO_PASSPHRASE" ]; then
            ENTRA_CRYPTO_PASSPHRASE=$(openssl rand -base64 24)
            echo "Generated random crypto passphrase"
        fi

        # Configure Entra OAuth2
        cat /etc/apache2/conf-available/oauth2-entra.conf \
            | sed "s|@@ENTRA_CLIENT_ID@@|$ENTRA_CLIENT_ID|g" \
            | sed "s|@@ENTRA_CLIENT_SECRET@@|$ENTRA_CLIENT_SECRET|g" \
            | sed "s|@@ENTRA_REDIRECT_URI@@|$ENTRA_REDIRECT_URI|g" \
            | sed "s|@@ENTRA_PROVIDER_METADATA_URL@@|$ENTRA_PROVIDER_METADATA_URL|g" \
            | sed "s|@@ENTRA_CRYPTO_PASSPHRASE@@|$ENTRA_CRYPTO_PASSPHRASE|g" \
            > /etc/apache2/conf-enabled/oauth2-entra.conf

        cp /etc/apache2/conf-available/auth-entra-protect.conf /etc/apache2/conf-enabled/
        a2enconf oauth2-entra 2>/dev/null || true
        a2enconf auth-entra-protect 2>/dev/null || true

        echo "✓ Entra ID authentication enabled"
        echo "  Client ID: ${ENTRA_CLIENT_ID:0:20}..."

        # Disable other auth methods
        rm -f /etc/apache2/conf-enabled/auth-basic.conf /etc/apache2/conf-enabled/oauth2-google.conf /etc/apache2/conf-enabled/auth-google-protect.conf
        rm -f /etc/apache2/.htpasswd
        ;;

    google)
        echo "=== Setting up Google OAuth2 Authentication ==="

        # Validate required parameters
        if [ -z "$GOOGLE_CLIENT_ID" ] || [ -z "$GOOGLE_CLIENT_SECRET" ] || [ -z "$GOOGLE_REDIRECT_URI" ]; then
            echo "ERROR: GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, and GOOGLE_REDIRECT_URI are required for AUTHTYPE=google"
            exit 1
        fi

        # Configure Google OAuth2
        # Generate random encryption passphrase for sessions (internal use only)
        GOOGLE_CRYPTO_PASSPHRASE=$(openssl rand -base64 24)

        cat /etc/apache2/conf-available/oauth2-google.conf \
            | sed "s|@@GOOGLE_CLIENT_ID@@|$GOOGLE_CLIENT_ID|g" \
            | sed "s|@@GOOGLE_CLIENT_SECRET@@|$GOOGLE_CLIENT_SECRET|g" \
            | sed "s|@@GOOGLE_REDIRECT_URI@@|$GOOGLE_REDIRECT_URI|g" \
            | sed "s|@@GOOGLE_CRYPTO_PASSPHRASE@@|$GOOGLE_CRYPTO_PASSPHRASE|g" \
            > /etc/apache2/conf-enabled/oauth2-google.conf

        cp /etc/apache2/conf-available/auth-google-protect.conf /etc/apache2/conf-enabled/
        a2enconf oauth2-google 2>/dev/null || true
        a2enconf auth-google-protect 2>/dev/null || true

        echo "✓ Google authentication enabled"
        echo "  Client ID: ${GOOGLE_CLIENT_ID:0:20}..."

        # Disable other auth methods
        rm -f /etc/apache2/conf-enabled/auth-basic.conf /etc/apache2/conf-enabled/oauth2-entra.conf /etc/apache2/conf-enabled/auth-entra-protect.conf
        rm -f /etc/apache2/.htpasswd
        ;;

    none|*)
        echo "=== Authentication Disabled (AUTHTYPE=none) ==="

        # Disable all authentication methods
        a2disconf oauth2-entra 2>/dev/null || true
        a2disconf auth-entra-protect 2>/dev/null || true
        a2disconf oauth2-google 2>/dev/null || true
        a2disconf auth-google-protect 2>/dev/null || true
        rm -f /etc/apache2/conf-enabled/oauth2-entra.conf /etc/apache2/conf-enabled/auth-entra-protect.conf
        rm -f /etc/apache2/conf-enabled/oauth2-google.conf /etc/apache2/conf-enabled/auth-google-protect.conf
        rm -f /etc/apache2/conf-enabled/auth-basic.conf
        rm -f /etc/apache2/.htpasswd

        echo "✓ No authentication required"
        ;;
esac

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



# Generate certificate only if not skipped (public mode)
if [ "$SKIP_CERT_GENERATION" = "false" ]; then
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
else
    echo ""
    echo "=== Certificate Generation Skipped (Private Mode) ==="
    # Ensure directory structure exists for private mode
    mkdir -p "/etc/letsencrypt/live/$DOMAIN"

    # Generate self-signed certificate for private mode
    if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        openssl req -x509 -nodes -days 365 \
            -newkey rsa:2048 \
            -keyout "/etc/letsencrypt/live/$DOMAIN/privkey.pem" \
            -out "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" \
            -subj "/C=AU/ST=Victoria/L=Melbourne/O=Org/CN=$DOMAIN" \
            2>/dev/null || true
        echo "Self-signed certificate generated for private mode"
    fi
fi

# Handle Emby subdomain if enabled (only in public mode)
if [ "$SKIP_CERT_GENERATION" = "false" ] && [ "${ENABLE_EMBY}" = "true" ]; then
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
        EMBY_CONFIG="${EMBY_CONFIG//@@OAUTH2_CRYPTO_PASSPHRASE@@/$OAUTH2_CRYPTO_PASSPHRASE}"
        echo "$EMBY_CONFIG" > /etc/apache2/sites-available/emby-subdomain.conf
        a2ensite emby-subdomain.conf 2>/dev/null || true
        echo "Emby VirtualHost created with: $EMBY_HOST:$EMBY_PORT"
    fi
fi

# Handle Plex subdomain if enabled (only in public mode)
if [ "$SKIP_CERT_GENERATION" = "false" ] && [ "${ENABLE_PLEX}" = "true" ]; then
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
DEBUG_DIR="/var/log/apache2/reverse-proxy-debug/$(date +%Y%m%d-%H%M%S)"
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
