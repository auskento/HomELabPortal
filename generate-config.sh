#!/bin/bash
# Generate Apache reverse proxy configuration from template based on environment variables

# Source environment variables from config file written by entrypoint
if [ -f /etc/apache2/env.conf ]; then
    source /etc/apache2/env.conf
fi

TEMPLATE_FILE="${1:-/etc/apache2/sites-available/reverse-proxy.conf.template}"
OUTPUT_FILE="${2:-/etc/apache2/sites-available/reverse-proxy.conf}"

# Default values (overridable from env.conf)
DOMAIN="${DOMAIN:-example.com}"
EMAIL="${EMAIL:-admin@example.com}"
SSL_PROTOCOLS="${SSL_PROTOCOLS:-all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1}"
SSL_CIPHERS="${SSL_CIPHERS:-HIGH:!aNULL:!MD5}"

# After sourcing env.conf, process service config files to replace hardcoded URLs
# This converts sonarr:8989 -> the actual SONARR_URL if provided

process_service_config() {
    local service_name=$1
    local service_url_var="${1^^}_URL"  # Convert to uppercase: SONARR_URL
    local service_url="${!service_url_var}"  # Get the variable value
    local service_port="${2:-8989}"  # Default port
    local service_file="/etc/apache2/sites-available/services/${service_name}.conf"
    
    if [ -z "$service_url" ]; then
        # No custom URL provided, use default
        return
    fi
    
    # Extract host with port for ProxyPass URLs
    service_host_with_port=$(echo "$service_url" | sed 's|^http://||;s|^https://||;s|/.*||')
    
    # Extract host WITHOUT port for cookie domain
    service_host_only=$(echo "$service_url" | sed 's|^http://||;s|^https://||;s|/.*||;s|:.*||')
    
    # Replace ProxyPass URLs (keep the port)
    sed -i "s|http://[^/]*:${service_port}|http://${service_host_with_port}|g" "$service_file"
    sed -i "s|ws://[^/]*:${service_port}|ws://${service_host_with_port}|g" "$service_file"
    
    # Replace cookie domain ONLY if the line contains ProxyPassReverseCookieDomain
    sed -i "s|\(ProxyPassReverseCookieDomain\) $service_name |\1 $service_host_only |g" "$service_file"
    
    echo "Updated $service_name config to use: $service_url"
}

# Process each service if it's enabled
[ "$ENABLE_SONARR" = "true" ] && process_service_config "sonarr" "8989"
[ "$ENABLE_RADARR" = "true" ] && process_service_config "radarr" "7878"
[ "$ENABLE_WHISPARR" = "true" ] && process_service_config "whisparr" "6969"
[ "$ENABLE_LIDARR" = "true" ] && process_service_config "lidarr" "8686"
[ "$ENABLE_READARR" = "true" ] && process_service_config "readarr" "8787"
[ "$ENABLE_PROWLARR" = "true" ] && process_service_config "prowlarr" "9696"
[ "$ENABLE_OVERSEERR" = "true" ] && process_service_config "overseerr" "5055"
[ "$ENABLE_JELLYFIN" = "true" ] && process_service_config "jellyfin" "8096"
[ "$ENABLE_EMBY" = "true" ] && process_service_config "emby" "8096"
[ "$ENABLE_PLEX" = "true" ] && process_service_config "plex" "32400"
[ "$ENABLE_TAUTULLI" = "true" ] && process_service_config "tautulli" "8181"
[ "$ENABLE_TRANSMISSION" = "true" ] && process_service_config "transmission" "6969"
[ "$ENABLE_QBITTORRENT" = "true" ] && process_service_config "qbittorrent" "8080"
[ "$ENABLE_SABNZBD" = "true" ] && process_service_config "sabnzbd" "8080"
[ "$ENABLE_DELUGE" = "true" ] && process_service_config "deluge" "8112"


# Function to generate include directive (output ONLY the Include line)
generate_include() {
    local service_name=$1
    local enable_flag=$2
    
    # Skip Emby and Plex - they use subdomain VirtualHosts instead
    if [ "$service_name" = "emby" ] || [ "$service_name" = "plex" ]; then
        return
    fi
    
    local service_file="/etc/apache2/sites-available/services/${service_name}.conf"
    
    if [ "$enable_flag" = "true" ]; then
        echo "Include $service_file"
    fi
}

# Function to generate auth include directive
generate_auth_include() {
    local auth_name=$1
    local enable_flag=$2
    local auth_file="/etc/apache2/conf-available/${auth_name}.conf"
    
    if [ "$enable_flag" = "true" ]; then
        echo "  ✓ Office 365 Authentication"
        echo "Include $auth_file"
    fi
}

# Generate include directives for each service
SONARR_INCLUDE=$(generate_include "sonarr" "$ENABLE_SONARR")
RADARR_INCLUDE=$(generate_include "radarr" "$ENABLE_RADARR")
WHISPARR_INCLUDE=$(generate_include "whisparr" "$ENABLE_WHISPARR")
LIDARR_INCLUDE=$(generate_include "lidarr" "$ENABLE_LIDARR")
PROWLARR_INCLUDE=$(generate_include "prowlarr" "$ENABLE_PROWLARR")
OVERSEERR_INCLUDE=$(generate_include "overseerr" "$ENABLE_OVERSEERR")
JELLYFIN_INCLUDE=$(generate_include "jellyfin" "$ENABLE_JELLYFIN")
EMBY_INCLUDE=$(generate_include "emby" "$ENABLE_EMBY")
PLEX_INCLUDE=$(generate_include "plex" "$ENABLE_PLEX")
TAUTULLI_INCLUDE=$(generate_include "tautulli" "$ENABLE_TAUTULLI")
TRANSMISSION_INCLUDE=$(generate_include "transmission" "$ENABLE_TRANSMISSION")
QBITTORRENT_INCLUDE=$(generate_include "qbittorrent" "$ENABLE_QBITTORRENT")
SABNZBD_INCLUDE=$(generate_include "sabnzbd" "$ENABLE_SABNZBD")
DELUGE_INCLUDE=$(generate_include "deluge" "$ENABLE_DELUGE")

# Generate auth includes
AUTH_OFFICE365_INCLUDE=$(generate_auth_include "auth-office365-protect" "$ENABLE_AUTH_OFFICE365")

# Generate custom backend include if enabled
CUSTOM_BACKEND_INCLUDE=""
if [ "$ENABLE_CUSTOM_BACKEND" = "true" ]; then
    CUSTOM_BACKEND_PATH="${CUSTOM_BACKEND_PATH:-/custom}"
    CUSTOM_BACKEND_URL="${CUSTOM_BACKEND_URL:-http://backend:8080}"
    echo "  ✓ custom backend at $CUSTOM_BACKEND_PATH"
    CUSTOM_BACKEND_INCLUDE="<Location $CUSTOM_BACKEND_PATH>
    ProxyPass $CUSTOM_BACKEND_URL
    ProxyPassReverse $CUSTOM_BACKEND_URL
    ProxyConnectTimeout 30
    ProxyTimeout 300
    ProxyPreserveHost On
    RequestHeader set X-Real-IP %{REMOTE_ADDR}s
    RequestHeader set X-Forwarded-For %{HTTP:X-Forwarded-For}e
    RequestHeader set X-Forwarded-Proto \"https\"
    RequestHeader set X-Forwarded-Host %{HTTP_HOST}e
</Location>"
fi

# Read template file
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "ERROR: Template file not found: $TEMPLATE_FILE"
    exit 1
fi

# Determine landing page based on enabled services
echo ""
echo "=== Setting Landing Page ==="
if [ "$ENABLE_SONARR" = "true" ]; then
    LANDING_PAGE="/sonarr/calendar"
    echo "Landing page: Sonarr Calendar"
elif [ "$ENABLE_RADARR" = "true" ]; then
    LANDING_PAGE="/radarr"
    echo "Landing page: Radarr"
else
    LANDING_PAGE="/index.html"
    echo "Landing page: Menu"
fi

# Generate configuration from template
echo ""
echo "Generating configuration from template..."

CONFIG=$(cat "$TEMPLATE_FILE")

# Replace placeholders
CONFIG="${CONFIG//@@DOMAIN@@/$DOMAIN}"
CONFIG="${CONFIG//@@STYLE@@/$STYLE}"
CONFIG="${CONFIG//@@SSL_PROTOCOLS@@/$SSL_PROTOCOLS}"
CONFIG="${CONFIG//@@SSL_CIPHERS@@/$SSL_CIPHERS}"

# Replace service includes
CONFIG="${CONFIG//@@INCLUDE_SONARR@@/$SONARR_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_RADARR@@/$RADARR_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_WHISPARR@@/$WHISPARR_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_LIDARR@@/$LIDARR_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_READARR@@/$READARR_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_PROWLARR@@/$PROWLARR_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_OVERSEERR@@/$OVERSEERR_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_JELLYFIN@@/$JELLYFIN_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_EMBY@@/$EMBY_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_PLEX@@/$PLEX_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_TAUTULLI@@/$TAUTULLI_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_TRANSMISSION@@/$TRANSMISSION_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_QBITTORRENT@@/$QBITTORRENT_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_SABNZBD@@/$SABNZBD_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_DELUGE@@/$DELUGE_INCLUDE}"
CONFIG="${CONFIG//@@INCLUDE_CUSTOM_BACKEND@@/$CUSTOM_BACKEND_INCLUDE}"

# Replace auth includes
CONFIG="${CONFIG//@@INCLUDE_AUTH_OFFICE365@@/$AUTH_OFFICE365_INCLUDE}"

# Write output file
echo "$CONFIG" > "$OUTPUT_FILE"

echo "Configuration generated: $OUTPUT_FILE"
echo "=== Configuration Complete ==="
