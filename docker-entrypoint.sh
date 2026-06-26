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
DASHBOARD_THEME="${DASHBOARD_THEME:-dark}"
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
ENABLE_BAZARR="${ENABLE_BAZARR:-false}"
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
EMBY_REDIRECT_URI="${EMBY_REDIRECT_URI:-}"
PLEX_URL="${PLEX_URL:-}"
PLEX_DOMAIN="${PLEX_DOMAIN:-}"
PLEX_REDIRECT_URI="${PLEX_REDIRECT_URI:-}"
TAUTULLI_URL="${TAUTULLI_URL:-}"
TRANSMISSION_URL="${TRANSMISSION_URL:-}"
QBITTORRENT_URL="${QBITTORRENT_URL:-}"
SABNZBD_URL="${SABNZBD_URL:-}"
DELUGE_URL="${DELUGE_URL:-}"
NZBGET_URL="${NZBGET_URL:-}"
NZBGET_USER="${NZBGET_USER:-}"
NZBGET_PASS="${NZBGET_PASS:-}"
NZBHYDRA_URL="${NZBHYDRA_URL:-}"
BAZARR_URL="${BAZARR_URL:-}"
ICON_URL_BAZARR="${ICON_URL_BAZARR:-}"
DASHBOARD_NAME="${DASHBOARD_NAME:-HomELabPortal}"
DASHBOARD_ICON="${DASHBOARD_ICON:-/icons/homelabportal.png}"
DASHBOARD_LANDING="${DASHBOARD_LANDING:-}"
DASHBOARD_ORDER="${DASHBOARD_ORDER:-DOWNLOADS,INFRA,MEDIA}"
SSL_PROTOCOLS="${SSL_PROTOCOLS:-all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1}"
SSL_CIPHERS="${SSL_CIPHERS:-HIGH:!aNULL:!MD5}"
APACHE_LOG_LEVEL="${APACHE_LOG_LEVEL:-warn}"
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

        # Extract domain from ENTRA_REDIRECT_URI for wildcard cookie domain
        # Example: https://transfers.limosani.net.au/oauth2callback → .limosani.net.au
        COOKIE_DOMAIN=$(echo "$ENTRA_REDIRECT_URI" | sed -E 's|^https?://[^.]+\.([^/]+).*$|.\1|')
        if [ -z "$COOKIE_DOMAIN" ] || [ "$COOKIE_DOMAIN" = "$ENTRA_REDIRECT_URI" ]; then
            # Fallback: if URL doesn't have subdomain, use full domain
            COOKIE_DOMAIN=$(echo "$ENTRA_REDIRECT_URI" | sed -E 's|^https?://([^/]+).*$|.\1|')
        fi

        # Configure Entra OAuth2
        cat /etc/apache2/conf-available/oauth2-entra.conf \
            | sed "s|@@ENTRA_CLIENT_ID@@|$ENTRA_CLIENT_ID|g" \
            | sed "s|@@ENTRA_CLIENT_SECRET@@|$ENTRA_CLIENT_SECRET|g" \
            | sed "s|@@ENTRA_REDIRECT_URI@@|$ENTRA_REDIRECT_URI|g" \
            | sed "s|@@ENTRA_PROVIDER_METADATA_URL@@|$ENTRA_PROVIDER_METADATA_URL|g" \
            | sed "s|@@ENTRA_CRYPTO_PASSPHRASE@@|$ENTRA_CRYPTO_PASSPHRASE|g" \
            | sed "s|@@COOKIE_DOMAIN@@|$COOKIE_DOMAIN|g" \
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

        # Extract domain from GOOGLE_REDIRECT_URI for wildcard cookie domain
        # Example: https://transfers.limosani.net.au/oauth2callback → .limosani.net.au
        COOKIE_DOMAIN=$(echo "$GOOGLE_REDIRECT_URI" | sed -E 's|^https?://[^.]+\.([^/]+).*$|.\1|')
        if [ -z "$COOKIE_DOMAIN" ] || [ "$COOKIE_DOMAIN" = "$GOOGLE_REDIRECT_URI" ]; then
            # Fallback: if URL doesn't have subdomain, use full domain
            COOKIE_DOMAIN=$(echo "$GOOGLE_REDIRECT_URI" | sed -E 's|^https?://([^/]+).*$|.\1|')
        fi

        cat /etc/apache2/conf-available/oauth2-google.conf \
            | sed "s|@@GOOGLE_CLIENT_ID@@|$GOOGLE_CLIENT_ID|g" \
            | sed "s|@@GOOGLE_CLIENT_SECRET@@|$GOOGLE_CLIENT_SECRET|g" \
            | sed "s|@@GOOGLE_REDIRECT_URI@@|$GOOGLE_REDIRECT_URI|g" \
            | sed "s|@@GOOGLE_CRYPTO_PASSPHRASE@@|$GOOGLE_CRYPTO_PASSPHRASE|g" \
            | sed "s|@@COOKIE_DOMAIN@@|$COOKIE_DOMAIN|g" \
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

# Request certificates for Emby and Plex subdomains
if [ "$SKIP_CERT_GENERATION" = "false" ]; then
    if [ ! -z "$EMBY_DOMAIN" ] && [ "${ENABLE_EMBY}" = "true" ]; then
        EMBY_CERT_DOMAIN=$(echo "$EMBY_DOMAIN" | sed -E 's|^https?://[^.]+\.(.+)$|\1|')
        if [ ! -f "/etc/letsencrypt/live/$EMBY_CERT_DOMAIN/fullchain.pem" ] || [ ! -f "/etc/letsencrypt/live/$EMBY_DOMAIN/fullchain.pem" ]; then
            echo "Requesting certificate for Emby subdomain: $EMBY_DOMAIN"
            certbot certonly --standalone --preferred-challenges http --email "$EMAIL" --agree-tos --no-eff-email --non-interactive -d "$EMBY_DOMAIN" 2>/dev/null || {
                echo "Certbot failed for Emby subdomain, using main domain certificate"
            }
        fi
    fi

    if [ ! -z "$PLEX_DOMAIN" ] && [ "${ENABLE_PLEX}" = "true" ]; then
        PLEX_CERT_DOMAIN=$(echo "$PLEX_DOMAIN" | sed -E 's|^https?://[^.]+\.(.+)$|\1|')
        if [ ! -f "/etc/letsencrypt/live/$PLEX_CERT_DOMAIN/fullchain.pem" ] || [ ! -f "/etc/letsencrypt/live/$PLEX_DOMAIN/fullchain.pem" ]; then
            echo "Requesting certificate for Plex subdomain: $PLEX_DOMAIN"
            certbot certonly --standalone --preferred-challenges http --email "$EMAIL" --agree-tos --no-eff-email --non-interactive -d "$PLEX_DOMAIN" 2>/dev/null || {
                echo "Certbot failed for Plex subdomain, using main domain certificate"
            }
        fi
    fi
fi

# Handle Emby subdomain with separate OAuth if enabled (only for OAuth auth types)
if [ "$SKIP_CERT_GENERATION" = "false" ] && [ "${ENABLE_EMBY}" = "true" ] && [ ! -z "$EMBY_DOMAIN" ] && [ ! -z "$EMBY_REDIRECT_URI" ] && ([ "$AUTHTYPE" = "google" ] || [ "$AUTHTYPE" = "entra" ]); then
    echo ""
    echo "=== Emby Subdomain OAuth Setup ==="
    echo "Emby domain: $EMBY_DOMAIN"

    # Extract subdomain from EMBY_DOMAIN (e.g., emby.limosani.net.au → emby)
    EMBY_SUBDOMAIN=$(echo "$EMBY_DOMAIN" | sed -E 's|^https?://([^.]+)\..*|\1|')

    # Extract domain for certificate (limosani.net.au)
    EMBY_CERT_DOMAIN=$(echo "$EMBY_DOMAIN" | sed -E 's|^https?://[^.]+\.(.+)$|\1|')

    echo "Emby subdomain: $EMBY_SUBDOMAIN, cert domain: $EMBY_CERT_DOMAIN"

    # Generate Emby OAuth config based on auth type
    case "$AUTHTYPE" in
        google)
            if [ ! -z "$EMBY_REDIRECT_URI" ]; then
                # Extract cookie domain from Emby redirect URI
                EMBY_COOKIE_DOMAIN=$(echo "$EMBY_REDIRECT_URI" | sed -E 's|^https?://[^.]+\.([^/]+).*$|.\1|')
                if [ -z "$EMBY_COOKIE_DOMAIN" ] || [ "$EMBY_COOKIE_DOMAIN" = "$EMBY_REDIRECT_URI" ]; then
                    EMBY_COOKIE_DOMAIN=$(echo "$EMBY_REDIRECT_URI" | sed -E 's|^https?://([^/]+).*$|.\1|')
                fi

                cat /etc/apache2/conf-available/oauth2-google.conf \
                    | sed "s#@@GOOGLE_REDIRECT_URI@@#$EMBY_REDIRECT_URI#g" \
                    | sed "s#@@COOKIE_DOMAIN@@#$EMBY_COOKIE_DOMAIN#g" \
                    > /etc/apache2/conf-available/oauth2-google-emby.conf

                echo "✓ Emby Google OAuth config generated"
            fi
            ;;
        entra)
            if [ ! -z "$EMBY_REDIRECT_URI" ]; then
                # Extract cookie domain from Emby redirect URI
                EMBY_COOKIE_DOMAIN=$(echo "$EMBY_REDIRECT_URI" | sed -E 's|^https?://[^.]+\.([^/]+).*$|.\1|')
                if [ -z "$EMBY_COOKIE_DOMAIN" ] || [ "$EMBY_COOKIE_DOMAIN" = "$EMBY_REDIRECT_URI" ]; then
                    EMBY_COOKIE_DOMAIN=$(echo "$EMBY_REDIRECT_URI" | sed -E 's|^https?://([^/]+).*$|.\1|')
                fi

                cat /etc/apache2/conf-available/oauth2-entra.conf \
                    | sed "s#@@ENTRA_CLIENT_ID@@#$ENTRA_CLIENT_ID#g" \
                    | sed "s#@@ENTRA_CLIENT_SECRET@@#$ENTRA_CLIENT_SECRET#g" \
                    | sed "s#@@ENTRA_REDIRECT_URI@@#$EMBY_REDIRECT_URI#g" \
                    | sed "s#@@ENTRA_PROVIDER_METADATA_URL@@#$ENTRA_PROVIDER_METADATA_URL#g" \
                    | sed "s#@@ENTRA_CRYPTO_PASSPHRASE@@#$ENTRA_CRYPTO_PASSPHRASE#g" \
                    | sed "s#@@COOKIE_DOMAIN@@#$EMBY_COOKIE_DOMAIN#g" \
                    > /etc/apache2/conf-available/oauth2-entra-emby.conf

                echo "✓ Emby Entra OAuth config generated"
            fi
            ;;
    esac
fi

# Handle Plex subdomain with separate OAuth if enabled (only for OAuth auth types)
if [ "$SKIP_CERT_GENERATION" = "false" ] && [ "${ENABLE_PLEX}" = "true" ] && [ ! -z "$PLEX_DOMAIN" ] && [ ! -z "$PLEX_REDIRECT_URI" ] && ([ "$AUTHTYPE" = "google" ] || [ "$AUTHTYPE" = "entra" ]); then
    echo ""
    echo "=== Plex Subdomain OAuth Setup ==="
    echo "Plex domain: $PLEX_DOMAIN"

    # Extract subdomain from PLEX_DOMAIN (e.g., plex.limosani.net.au → plex)
    PLEX_SUBDOMAIN=$(echo "$PLEX_DOMAIN" | sed -E 's|^https?://([^.]+)\..*|\1|')

    # Extract domain for certificate (limosani.net.au)
    PLEX_CERT_DOMAIN=$(echo "$PLEX_DOMAIN" | sed -E 's|^https?://[^.]+\.(.+)$|\1|')

    echo "Plex subdomain: $PLEX_SUBDOMAIN, cert domain: $PLEX_CERT_DOMAIN"

    # Generate Plex OAuth config based on auth type
    case "$AUTHTYPE" in
        google)
            if [ ! -z "$PLEX_REDIRECT_URI" ]; then
                # Extract cookie domain from Plex redirect URI
                PLEX_COOKIE_DOMAIN=$(echo "$PLEX_REDIRECT_URI" | sed -E 's|^https?://[^.]+\.([^/]+).*$|.\1|')
                if [ -z "$PLEX_COOKIE_DOMAIN" ] || [ "$PLEX_COOKIE_DOMAIN" = "$PLEX_REDIRECT_URI" ]; then
                    PLEX_COOKIE_DOMAIN=$(echo "$PLEX_REDIRECT_URI" | sed -E 's|^https?://([^/]+).*$|.\1|')
                fi

                cat /etc/apache2/conf-available/oauth2-google.conf \
                    | sed "s#@@GOOGLE_REDIRECT_URI@@#$PLEX_REDIRECT_URI#g" \
                    | sed "s#@@COOKIE_DOMAIN@@#$PLEX_COOKIE_DOMAIN#g" \
                    > /etc/apache2/conf-available/oauth2-google-plex.conf

                echo "✓ Plex Google OAuth config generated"
            fi
            ;;
        entra)
            if [ ! -z "$PLEX_REDIRECT_URI" ]; then
                # Extract cookie domain from Plex redirect URI
                PLEX_COOKIE_DOMAIN=$(echo "$PLEX_REDIRECT_URI" | sed -E 's|^https?://[^.]+\.([^/]+).*$|.\1|')
                if [ -z "$PLEX_COOKIE_DOMAIN" ] || [ "$PLEX_COOKIE_DOMAIN" = "$PLEX_REDIRECT_URI" ]; then
                    PLEX_COOKIE_DOMAIN=$(echo "$PLEX_REDIRECT_URI" | sed -E 's|^https?://([^/]+).*$|.\1|')
                fi

                cat /etc/apache2/conf-available/oauth2-entra.conf \
                    | sed "s#@@ENTRA_CLIENT_ID@@#$ENTRA_CLIENT_ID#g" \
                    | sed "s#@@ENTRA_CLIENT_SECRET@@#$ENTRA_CLIENT_SECRET#g" \
                    | sed "s#@@ENTRA_REDIRECT_URI@@#$PLEX_REDIRECT_URI#g" \
                    | sed "s#@@ENTRA_PROVIDER_METADATA_URL@@#$ENTRA_PROVIDER_METADATA_URL#g" \
                    | sed "s#@@ENTRA_CRYPTO_PASSPHRASE@@#$ENTRA_CRYPTO_PASSPHRASE#g" \
                    | sed "s#@@COOKIE_DOMAIN@@#$PLEX_COOKIE_DOMAIN#g" \
                    > /etc/apache2/conf-available/oauth2-entra-plex.conf

                echo "✓ Plex Entra OAuth config generated"
            fi
            ;;
    esac
fi

# Generate Emby VirtualHost if enabled (public mode only)
if [ "$ACCESS_MODE" = "public" ] && [ "${ENABLE_EMBY}" = "true" ] && [ ! -z "$EMBY_DOMAIN" ]; then
    echo ""
    echo "=== Generating Emby VirtualHost ==="

    # Domain name from EMBY_DOMAIN (should be emby.limosani.net.au format)
    EMBY_DOMAIN_NAME="$EMBY_DOMAIN"
    EMBY_CERT_DOMAIN=$(echo "$EMBY_DOMAIN" | sed -E 's|^https?://||' | sed -E 's|[^.]+\.(.+)$|\1|')

    # Use subdomain cert if it exists, otherwise use main domain cert
    if [ -f "/etc/letsencrypt/live/$EMBY_DOMAIN_NAME/fullchain.pem" ]; then
        EMBY_CERT_PATH="$EMBY_DOMAIN_NAME"
    elif [ -f "/etc/letsencrypt/live/$EMBY_CERT_DOMAIN/fullchain.pem" ]; then
        EMBY_CERT_PATH="$EMBY_CERT_DOMAIN"
    else
        EMBY_CERT_PATH="$DOMAIN"
    fi

    # Generate Emby VirtualHost config
    cat > /etc/apache2/sites-available/emby-vhost.conf <<'EMBYEOF'
<VirtualHost *:80>
    ServerName @@EMBY_DOMAIN_NAME@@
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    DocumentRoot /var/www/letsencrypt
    <Directory /var/www/letsencrypt>
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost *:443>
    ServerName @@EMBY_DOMAIN_NAME@@
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/@@EMBY_CERT_PATH@@/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/@@EMBY_CERT_PATH@@/privkey.pem
    SSLProtocol @@SSL_PROTOCOLS@@
    SSLCipherSuite @@SSL_CIPHERS@@
    SSLHonorCipherOrder on

    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"

    ProxyRequests Off
    ProxyPreserveHost On
    ProxyVia Off

    <Proxy *>
        Order deny,allow
        Allow from all
        Satisfy Any
    </Proxy>

    ProxyTimeout 300
    Timeout 300

    @@INCLUDE_EMBY_OAUTH@@

    ProxyPass / http://emby:8096/
    ProxyPassReverse / http://emby:8096/

    ErrorDocument 502 /error-pages/502.html
    ErrorDocument 503 /error-pages/503.html

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
    LogLevel warn
</VirtualHost>
EMBYEOF

    sed -i "s#@@EMBY_DOMAIN_NAME@@#$EMBY_DOMAIN_NAME#g" /etc/apache2/sites-available/emby-vhost.conf
    sed -i "s#@@EMBY_CERT_PATH@@#$EMBY_CERT_PATH#g" /etc/apache2/sites-available/emby-vhost.conf
    sed -i "s#@@SSL_PROTOCOLS@@#$SSL_PROTOCOLS#g" /etc/apache2/sites-available/emby-vhost.conf
    sed -i "s#@@SSL_CIPHERS@@#$SSL_CIPHERS#g" /etc/apache2/sites-available/emby-vhost.conf
    sed -i "s#http://emby:8096/#$EMBY_URL/#g" /etc/apache2/sites-available/emby-vhost.conf

    # Generate auth protection config for Emby based on AUTHTYPE
    case "$AUTHTYPE" in
        google)
            # Generate auth protection config
            cat > /etc/apache2/conf-available/auth-google-protect-emby.conf <<'EMBYAUTHEOF'
<Location /oauth2>
    SetHandler oauth2-handler
</Location>
<Location /oauth2callback>
    SetHandler oauth2-handler
</Location>
<Location />
    AuthType openid-connect
    Require valid-user
    LogLevel debug
</Location>
RequestHeader set X-Remote-User %{OIDC_email}e
RequestHeader set X-Remote-Name %{OIDC_name}e
RequestHeader set X-Remote-ID %{OIDC_sub}e
RequestHeader set X-Auth-Method "Google"
EMBYAUTHEOF

            # Add includes for Google OAuth
            sed -i "/@@INCLUDE_EMBY_OAUTH@@/c\\    Include /etc/apache2/conf-available/oauth2-google-emby.conf\n    Include /etc/apache2/conf-available/auth-google-protect-emby.conf" /etc/apache2/sites-available/emby-vhost.conf
            ;;
        entra)
            # Generate auth protection config
            cat > /etc/apache2/conf-available/auth-entra-protect-emby.conf <<'EMBYAUTHEOF'
<Location /oauth2>
    SetHandler oauth2-handler
</Location>
<Location /oauth2callback>
    SetHandler oauth2-handler
</Location>
<Location />
    AuthType openid-connect
    Require valid-user
    LogLevel debug
</Location>
RequestHeader set X-Remote-User %{OIDC_email}e
RequestHeader set X-Remote-Name %{OIDC_name}e
RequestHeader set X-Remote-ID %{OIDC_sub}e
RequestHeader set X-Auth-Method "Entra"
EMBYAUTHEOF

            # Add includes for Entra OAuth
            sed -i "/@@INCLUDE_EMBY_OAUTH@@/c\\    Include /etc/apache2/conf-available/oauth2-entra-emby.conf\n    Include /etc/apache2/conf-available/auth-entra-protect-emby.conf" /etc/apache2/sites-available/emby-vhost.conf
            ;;
        basic)
            # Generate basic auth protection config
            cat > /etc/apache2/conf-available/auth-basic-protect-emby.conf <<'EMBYAUTHEOF'
<Location />
    AuthType Basic
    AuthName "Emby"
    AuthUserFile /etc/apache2/.htpasswd
    Require valid-user
</Location>
EMBYAUTHEOF

            # Add basic auth include
            sed -i "/@@INCLUDE_EMBY_OAUTH@@/c\\    Include /etc/apache2/conf-available/auth-basic-protect-emby.conf" /etc/apache2/sites-available/emby-vhost.conf
            ;;
        none|*)
            # No auth protection - just remove the placeholder
            sed -i "/@@INCLUDE_EMBY_OAUTH@@/d" /etc/apache2/sites-available/emby-vhost.conf
            ;;
    esac

    a2ensite emby-vhost.conf 2>/dev/null || true
    echo "✓ Emby VirtualHost enabled"
fi

# Generate Plex VirtualHost if enabled (public mode only)
if [ "$ACCESS_MODE" = "public" ] && [ "${ENABLE_PLEX}" = "true" ] && [ ! -z "$PLEX_DOMAIN" ]; then
    echo ""
    echo "=== Generating Plex VirtualHost ==="

    # Domain name from PLEX_DOMAIN (should be plex.limosani.net.au format)
    PLEX_DOMAIN_NAME="$PLEX_DOMAIN"
    PLEX_CERT_DOMAIN=$(echo "$PLEX_DOMAIN" | sed -E 's|^https?://||' | sed -E 's|[^.]+\.(.+)$|\1|')

    # Use subdomain cert if it exists, otherwise use main domain cert
    if [ -f "/etc/letsencrypt/live/$PLEX_DOMAIN_NAME/fullchain.pem" ]; then
        PLEX_CERT_PATH="$PLEX_DOMAIN_NAME"
    elif [ -f "/etc/letsencrypt/live/$PLEX_CERT_DOMAIN/fullchain.pem" ]; then
        PLEX_CERT_PATH="$PLEX_CERT_DOMAIN"
    else
        PLEX_CERT_PATH="$DOMAIN"
    fi

    # Generate Plex VirtualHost config
    cat > /etc/apache2/sites-available/plex-vhost.conf <<'PLEXEOF'
<VirtualHost *:80>
    ServerName @@PLEX_DOMAIN_NAME@@
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    DocumentRoot /var/www/letsencrypt
    <Directory /var/www/letsencrypt>
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost *:443>
    ServerName @@PLEX_DOMAIN_NAME@@
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/@@PLEX_CERT_PATH@@/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/@@PLEX_CERT_PATH@@/privkey.pem
    SSLProtocol @@SSL_PROTOCOLS@@
    SSLCipherSuite @@SSL_CIPHERS@@
    SSLHonorCipherOrder on

    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"

    ProxyRequests Off
    ProxyPreserveHost On
    ProxyVia Off

    <Proxy *>
        Order deny,allow
        Allow from all
        Satisfy Any
    </Proxy>

    ProxyTimeout 300
    Timeout 300

    @@INCLUDE_PLEX_OAUTH@@

    ProxyPass / http://plex:32400/
    ProxyPassReverse / http://plex:32400/

    ErrorDocument 502 /error-pages/502.html
    ErrorDocument 503 /error-pages/503.html

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
    LogLevel warn
</VirtualHost>
PLEXEOF

    sed -i "s#@@PLEX_DOMAIN_NAME@@#$PLEX_DOMAIN_NAME#g" /etc/apache2/sites-available/plex-vhost.conf
    sed -i "s#@@PLEX_CERT_PATH@@#$PLEX_CERT_PATH#g" /etc/apache2/sites-available/plex-vhost.conf
    sed -i "s#@@SSL_PROTOCOLS@@#$SSL_PROTOCOLS#g" /etc/apache2/sites-available/plex-vhost.conf
    sed -i "s#@@SSL_CIPHERS@@#$SSL_CIPHERS#g" /etc/apache2/sites-available/plex-vhost.conf
    sed -i "s#http://plex:32400/#$PLEX_URL/#g" /etc/apache2/sites-available/plex-vhost.conf

    # Generate auth protection config for Plex based on AUTHTYPE
    case "$AUTHTYPE" in
        google)
            # Generate auth protection config
            cat > /etc/apache2/conf-available/auth-google-protect-plex.conf <<'PLEXAUTHEOF'
<Location /oauth2>
    SetHandler oauth2-handler
</Location>
<Location /oauth2callback>
    SetHandler oauth2-handler
</Location>
<Location />
    AuthType openid-connect
    Require valid-user
    LogLevel debug
</Location>
RequestHeader set X-Remote-User %{OIDC_email}e
RequestHeader set X-Remote-Name %{OIDC_name}e
RequestHeader set X-Remote-ID %{OIDC_sub}e
RequestHeader set X-Auth-Method "Google"
PLEXAUTHEOF

            # Add includes for Google OAuth
            sed -i "/@@INCLUDE_PLEX_OAUTH@@/c\\    Include /etc/apache2/conf-available/oauth2-google-plex.conf\n    Include /etc/apache2/conf-available/auth-google-protect-plex.conf" /etc/apache2/sites-available/plex-vhost.conf
            ;;
        entra)
            # Generate auth protection config
            cat > /etc/apache2/conf-available/auth-entra-protect-plex.conf <<'PLEXAUTHEOF'
<Location /oauth2>
    SetHandler oauth2-handler
</Location>
<Location /oauth2callback>
    SetHandler oauth2-handler
</Location>
<Location />
    AuthType openid-connect
    Require valid-user
    LogLevel debug
</Location>
RequestHeader set X-Remote-User %{OIDC_email}e
RequestHeader set X-Remote-Name %{OIDC_name}e
RequestHeader set X-Remote-ID %{OIDC_sub}e
RequestHeader set X-Auth-Method "Entra"
PLEXAUTHEOF

            # Add includes for Entra OAuth
            sed -i "/@@INCLUDE_PLEX_OAUTH@@/c\\    Include /etc/apache2/conf-available/oauth2-entra-plex.conf\n    Include /etc/apache2/conf-available/auth-entra-protect-plex.conf" /etc/apache2/sites-available/plex-vhost.conf
            ;;
        basic)
            # Generate basic auth protection config
            cat > /etc/apache2/conf-available/auth-basic-protect-plex.conf <<'PLEXAUTHEOF'
<Location />
    AuthType Basic
    AuthName "Plex"
    AuthUserFile /etc/apache2/.htpasswd
    Require valid-user
</Location>
PLEXAUTHEOF

            # Add basic auth include
            sed -i "/@@INCLUDE_PLEX_OAUTH@@/c\\    Include /etc/apache2/conf-available/auth-basic-protect-plex.conf" /etc/apache2/sites-available/plex-vhost.conf
            ;;
        none|*)
            # No auth protection - just remove the placeholder
            sed -i "/@@INCLUDE_PLEX_OAUTH@@/d" /etc/apache2/sites-available/plex-vhost.conf
            ;;
    esac

    a2ensite plex-vhost.conf 2>/dev/null || true
    echo "✓ Plex VirtualHost enabled"
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
