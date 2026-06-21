#!/bin/bash

# Generate BOTH HTML Dashboards Based on Enabled Services
# - index.html: Simple icon menu with date/time
# - dashboard.html: React-based dashboard with categories

SIMPLE_TEMPLATE="/var/www/html/index.html.template"
DASHBOARD_TEMPLATE="/var/www/html/index.html.dashboard"
SIMPLE_OUTPUT="/var/www/html/index.html"
DASHBOARD_OUTPUT="/var/www/html/dashboard.html"

# Define all available services with metadata (simple menu)
declare -A SERVICES=(
    [SONARR]="Sonarr|/icons/sonarr.png|/sonarr/calendar"
    [RADARR]="Radarr|/icons/radarr.png|/radarr/"
    [WHISPARR]="Whisparr|/icons/whisparr.png|/whisparr/"
    [LIDARR]="Lidarr|/icons/lidarr.png|/lidarr/"
    [READARR]="Readarr|/icons/readarr.png|/readarr/"
    [JELLYFIN]="Jellyfin|/icons/jellyfin.png|/jellyfin/"
    [EMBY]="Emby|/icons/emby.png|/emby/"
    [PLEX]="Plex|/icons/plex.png|https://app.plex.tv"
    [OVERSEERR]="Overseerr|/icons/overseerr.png|/overseerr/"
    [TAUTULLI]="Tautulli|/icons/tautulli.png|/tautulli/"
    [SABNZBD]="SABnzbd|/icons/sabnzbd.png|/sabnzbd/"
    [QBITTORRENT]="qBittorrent|/icons/qbittorrent.png|/qbittorrent/"
    [TRANSMISSION]="Transmission|/icons/transmission.png|/transmission/"
    [DELUGE]="Deluge|/icons/deluge.png|/deluge/"
    [PROWLARR]="Prowlarr|/icons/prowlarr.png|/prowlarr/"
)

# Define services with categories for React dashboard
declare -A SERVICES_DASHBOARD=(
    [SONARR]="MEDIA|Sonarr|TV shows|/icons/sonarr.png|/sonarr/calendar|#3aa0e0"
    [RADARR]="MEDIA|Radarr|Movies|/icons/radarr.png|/radarr/|#febc2e"
    [WHISPARR]="MEDIA|Whisparr|Adult content|/icons/whisparr.png|/whisparr/|#ef7e30"
    [LIDARR]="MEDIA|Lidarr|Music|/icons/lidarr.png|/lidarr/|#2ecd6f"
    [READARR]="MEDIA|Readarr|Books|/icons/readarr.png|/readarr/|#d48d4c"
    [JELLYFIN]="MEDIA|Jellyfin|Streaming|/icons/jellyfin.png|/jellyfin/|#00a4dc"
    [EMBY]="MEDIA|Emby|Streaming|/icons/emby.png|/emby/|#9146FF"
    [PLEX]="MEDIA|Plex|Streaming|/icons/plex.png|https://app.plex.tv|#e5a00d"
    [OVERSEERR]="MEDIA|Overseerr|Requests|/icons/overseerr.png|/overseerr/|#00a4dc"
    [TAUTULLI]="DOWNLOADS|Tautulli|Analytics|/icons/tautulli.png|/tautulli/|#4a9eff"
    [SABNZBD]="DOWNLOADS|SABnzbd|Usenet downloads|/icons/sabnzbd.png|/sabnzbd/|#f5c20f"
    [QBITTORRENT]="DOWNLOADS|qBittorrent|Torrent client|/icons/qbittorrent.png|/qbittorrent/|#3683b6"
    [TRANSMISSION]="DOWNLOADS|Transmission|Torrents|/icons/transmission.png|/transmission/|#343434"
    [DELUGE]="DOWNLOADS|Deluge|Torrent client|/icons/deluge.png|/deluge/|#3aa3e0"
    [PROWLARR]="INFRA|Prowlarr|Indexer manager|/icons/prowlarr.png|/prowlarr/|#e8810e"
)

# Convert service key to lowercase path
service_to_path() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Generate menu items HTML (for simple menu)
generate_menu_items() {
    local menu_html=""
    
    for service_key in "${!SERVICES[@]}"; do
        # Check if service is enabled
        local enable_var="ENABLE_${service_key}"
        local is_enabled="${!enable_var}"
        
        # Skip disabled services
        if [ "$is_enabled" != "true" ]; then
            continue
        fi
        
        # Parse service metadata
        IFS='|' read -r service_name icon_path href <<< "${SERVICES[$service_key]}"
        
        # Add menu item
        menu_html+="<td class='menu-item'>"
        menu_html+="<a href='$href' target='content' title='$service_name'>"
        menu_html+="<img src='$icon_path' alt='$service_name' />"
        menu_html+="<span class='label'>$service_name</span>"
        menu_html+="</a>"
        menu_html+="</td>"
    done
    
    echo "$menu_html"
}

# Generate enabled services list for iframe fallback
generate_services_list() {
    local list_html=""
    
    for service_key in "${!SERVICES[@]}"; do
        # Check if service is enabled
        local enable_var="ENABLE_${service_key}"
        local is_enabled="${!enable_var}"
        
        # Skip disabled services
        if [ "$is_enabled" != "true" ]; then
            continue
        fi
        
        # Parse service metadata
        IFS='|' read -r service_name icon_path href <<< "${SERVICES[$service_key]}"
        
        # Add list item
        list_html+="<li><a href='$href' target='content'>$service_name</a></li>"
    done
    
    # If no services enabled, show message
    if [ -z "$list_html" ]; then
        list_html="<li class='no-services'>⚠️ No services are currently enabled</li>"
    fi
    
    echo "$list_html"
}

# Generate services array for React dashboard
generate_services_array() {
    local array=""
    local first=true
    
    for service_key in "${!SERVICES_DASHBOARD[@]}"; do
        # Check if service is enabled
        local enable_var="ENABLE_${service_key}"
        local is_enabled="${!enable_var}"
        
        # Skip disabled services
        if [ "$is_enabled" != "true" ]; then
            continue
        fi
        
        # Parse service metadata
        IFS='|' read -r category name desc icon href accent <<< "${SERVICES_DASHBOARD[$service_key]}"
        local id=$(service_to_path "$service_key")
        
        # Determine if popup (external link)
        local popup="false"
        [[ "$href" == http* ]] && popup="true"
        
        # Add comma between items
        if [ "$first" = true ]; then
            first=false
        else
            array+=",$newline"
        fi
        
        # Add service object
        array+="{ cat: '$category', id: '$id', name: '$name', desc: '$desc', icon: '$icon', href: '$href', accent: '$accent', popup: $popup }"
    done
    
    echo "$array"
}

# Generate simple menu (index.html)
generate_simple_menu() {
    if [ ! -f "$SIMPLE_TEMPLATE" ]; then
        echo "ERROR: Simple template not found: $SIMPLE_TEMPLATE"
        return 1
    fi
    
    # Generate menu items and services list
    local menu_items=$(generate_menu_items)
    local services_list=$(generate_services_list)
    
    # Read template and replace placeholders
    local html_content=$(cat "$SIMPLE_TEMPLATE")
    html_content="${html_content//@@MENU_ITEMS@@/$menu_items}"
    html_content="${html_content//@@ENABLED_SERVICES_LIST@@/$services_list}"
    
    # Write output file
    echo "$html_content" > "$SIMPLE_OUTPUT"
    
    echo "✓ Simple menu generated: $SIMPLE_OUTPUT"
}

# Generate React dashboard (dashboard.html)
generate_react_dashboard() {
    if [ ! -f "$DASHBOARD_TEMPLATE" ]; then
        echo "ERROR: Dashboard template not found: $DASHBOARD_TEMPLATE"
        return 1
    fi
    
    # Copy support.js
    cp /usr/local/bin/support.js /var/www/html/support.js 2>/dev/null || true
    
    # Generate services array
    local services_array=$(generate_services_array)
    
    # Read template and replace placeholders
    local html_content=$(cat "$DASHBOARD_TEMPLATE")
    html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
    
    # Write output file
    echo "$html_content" > "$DASHBOARD_OUTPUT"
    
    echo "✓ React dashboard generated: $DASHBOARD_OUTPUT"
}

# Main generation function
generate_html() {
    echo "Generating both dashboards..."
    echo ""
    
    # Count enabled services
    local count=0
    for service_key in "${!SERVICES[@]}"; do
        local enable_var="ENABLE_${service_key}"
        if [ "${!enable_var}" = "true" ]; then
            ((count++))
        fi
    done
    
    # Generate both versions
    generate_simple_menu
    generate_react_dashboard
    
    echo ""
    echo "✓ Both dashboards generated with $count enabled service(s)"
    echo ""
    echo "Available dashboards:"
    echo "  - Simple menu (default):  http://transfers.limosani.au/ → /var/www/html/index.html"
    echo "  - React dashboard:        http://transfers.limosani.au/dashboard.html"
}

# Run generation
generate_html



