#!/bin/bash

# Update Dashboard Configuration
# Allows changing dashboard style and landing page without rebuilding the image
# Usage: update-dashboard-config.sh [--style classic|modern|oauth] [--landing SERVICE_PATH] [--reload]

CONFIG_FILE="/etc/apache2/dashboard.conf"
ENTRYPOINT_CONFIG="/etc/apache2/env.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
STYLE=""
LANDING=""
RELOAD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --style)
            STYLE="$2"
            shift 2
            ;;
        --landing)
            LANDING="$2"
            shift 2
            ;;
        --reload)
            RELOAD=true
            shift
            ;;
        --help)
            echo "Update Dashboard Configuration"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --style STYLE         Set dashboard style: classic, modern, or oauth"
            echo "  --landing PATH        Set default landing page (e.g., sonarr/calendar, radarr)"
            echo "  --reload              Reload dashboards after updating config"
            echo "  --help                Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --style modern --landing radarr --reload"
            echo "  $0 --landing sonarr/calendar"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Initialize config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    echo "# Dashboard Configuration" > "$CONFIG_FILE"
    echo "# Auto-generated configuration file" >> "$CONFIG_FILE"
    echo "STYLE=${STYLE:-classic}" >> "$CONFIG_FILE"
    echo "LANDING=${LANDING:-}" >> "$CONFIG_FILE"
fi

# Update STYLE if provided
if [ -n "$STYLE" ]; then
    # Validate style option
    case "$STYLE" in
        classic|modern|oauth)
            sed -i "s|^STYLE=.*|STYLE=\"${STYLE}\"|" "$CONFIG_FILE"
            echo -e "${GREEN}✓ Dashboard style updated to: $STYLE${NC}"
            ;;
        *)
            echo -e "${RED}✗ Invalid style: $STYLE${NC}"
            echo "Valid options: classic, modern, oauth"
            exit 1
            ;;
    esac
fi

# Update LANDING if provided
if [ -n "$LANDING" ]; then
    sed -i "s|^LANDING=.*|LANDING=\"${LANDING}\"|" "$CONFIG_FILE"
    echo -e "${GREEN}✓ Landing page updated to: $LANDING${NC}"
fi

# Display current configuration
echo ""
echo -e "${YELLOW}Current Configuration:${NC}"
grep -E "^(STYLE|LANDING)=" "$CONFIG_FILE"

# Reload dashboards if requested
if [ "$RELOAD" = true ]; then
    echo ""
    echo "Reloading dashboards..."

    # First, update env.conf with new values
    if [ -n "$STYLE" ] || [ -n "$LANDING" ]; then
        # Update STYLE in env.conf
        if [ -n "$STYLE" ]; then
            sed -i "s|^STYLE=.*|STYLE=\"${STYLE}\"|" "$ENTRYPOINT_CONFIG"
        fi

        # Update LANDING in env.conf
        if [ -n "$LANDING" ]; then
            sed -i "s|^LANDING=.*|LANDING=\"${LANDING}\"|" "$ENTRYPOINT_CONFIG"
        fi
    fi

    # Source the updated env.conf to get all environment variables
    if [ -f "$ENTRYPOINT_CONFIG" ]; then
        source "$ENTRYPOINT_CONFIG"
    fi

    # Export variables so generate-html-menu.sh can use them
    export STYLE
    export LANDING
    export DASHBOARD_NAME
    export DASHBOARD_ICON
    export AUTHTYPE
    export ENABLE_SONARR
    export ENABLE_RADARR
    export ENABLE_WHISPARR
    export ENABLE_LIDARR
    export ENABLE_READARR
    export ENABLE_PROWLARR
    export ENABLE_SEERR
    export ENABLE_JELLYFIN
    export ENABLE_EMBY
    export ENABLE_PLEX
    export ENABLE_TAUTULLI
    export ENABLE_TRANSMISSION
    export ENABLE_QBITTORRENT
    export ENABLE_SABNZBD
    export ENABLE_DELUGE
    export DOMAIN
    export EMAIL
    export EMBY_DOMAIN
    export PLEX_DOMAIN

    # Regenerate dashboards with updated config
    if [ -x "/usr/local/bin/generate-html-menu.sh" ]; then
        /usr/local/bin/generate-html-menu.sh
        echo -e "${GREEN}✓ Dashboards regenerated${NC}"
    else
        echo -e "${YELLOW}⚠ Dashboard generator not found${NC}"
    fi

    echo -e "${GREEN}✓ Configuration reloaded${NC}"
fi

echo ""
echo "To apply changes, you can:"
echo "1. Use --reload flag to regenerate dashboards immediately"
echo "2. Restart the Apache service: systemctl restart apache2"
echo "3. Use environment variables on next container start"
