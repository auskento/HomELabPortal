#!/bin/bash
# Generate Apache reverse proxy configuration from template based on environment variables

TEMPLATE_FILE="${1:-/etc/apache2/sites-available/reverse-proxy.conf.template}"
OUTPUT_FILE="${2:-/etc/apache2/sites-available/reverse-proxy.conf}"

# Default values
DOMAIN="${DOMAIN:-example.com}"
EMAIL="${EMAIL:-admin@example.com}"
SSL_PROTOCOLS="${SSL_PROTOCOLS:-all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1}"
SSL_CIPHERS="${SSL_CIPHERS:-HIGH:!aNULL:!MD5}"

# Service enable/disable flags (default to false)
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
ENABLE_CUSTOM_BACKEND="${ENABLE_CUSTOM_BACKEND:-false}"

# Authentication flags
ENABLE_AUTH_OFFICE365="${ENABLE_AUTH_OFFICE365:-false}"

echo "=== Generating Apache Configuration ==="
echo "Domain: $DOMAIN"
echo "Enabled services:"

# Function to generate include directive
generate_include() {
    local service_name=$1
    local enable_flag=$2
    local service_file="/etc/apache2/sites-available/services/${service_name}.conf"
    
    if [ "$enable_flag" = "true" ]; then
        echo "  ✓ $service_name"
        echo "Include $service_file"
    else
        echo "  - $service_name (disabled)"
        echo ""
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
    else
        echo "  - Office 365 Authentication (disabled)"
        echo ""
    fi
}

# Generate include directives for each service
SONARR_INCLUDE=$(generate_include "sonarr" "$ENABLE_SONARR")
RADARR_INCLUDE=$(generate_include "radarr" "$ENABLE_RADARR")
WHISPARR_INCLUDE=$(generate_include "whisparr" "$ENABLE_WHISPARR")
LIDARR_INCLUDE=$(generate_include "lidarr" "$ENABLE_LIDARR")
READARR_INCLUDE=$(generate_include "readarr" "$ENABLE_READARR")
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

# Generate configuration from template
echo "Generating configuration from template..."

CONFIG=$(cat "$TEMPLATE_FILE")

# Replace placeholders
CONFIG="${CONFIG//@@DOMAIN@@/$DOMAIN}"
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
