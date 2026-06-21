#!/bin/bash

# Generate Dynamic React Dashboard Based on Enabled Services

DASHBOARD_TEMPLATE="/var/www/html/index.html.dashboard"
OUTPUT_FILE="/var/www/html/index.html"
SUPPORT_JS="/var/www/html/support.js"

# Define all available services with metadata
declare -A SERVICES=(
    [SONARR]="MEDIA|Sonarr|TV shows|/icons/sonarr.png|/sonarr/calendar|#3aa0e0"
    [RADARR]="MEDIA|Radarr|Movies|/icons/radarr.png|/radarr/|#febc2e"
    [WHISPARR]="MEDIA|Whisparr|Adult content|/icons/whisparr.png|/whisparr/|#ef7e30"
    [LIDARR]="MEDIA|Lidarr|Music|/icons/lidarr.png|/lidarr/|#2ecd6f"
    [READARR]="MEDIA|Readarr|Books|/icons/readarr.png|/readarr/|#d48d4c"
    [JELLYFIN]="MEDIA|Jellyfin|Streaming|/icons/jellyfin.png|/jellyfin/|#00a4dc"
    [EMBY]="MEDIA|Emby|Streaming|/icons/emby.png|/emby/|#9146FF"
    [PLEX]="MEDIA|Plex|Streaming|https://app.plex.tv|https://app.plex.tv|#e5a00d"
    [OVERSEERR]="MEDIA|Overseerr|Requests|/icons/overseerr.png|/overseerr/|#00a4dc"
    [TAUTULLI]="DOWNLOADS|Tautulli|Analytics|/icons/tautulli.png|/tautulli/|#4a9eff"
    [SABNZBD]="DOWNLOADS|SABnzbd|Usenet downloads|/icons/sabnzbd.png|/sabnzbd/|#f5c20f"
    [QBITTORRENT]="DOWNLOADS|qBittorrent|Torrent client|/icons/qbittorrent.png|/qbittorrent/|#3683b6"
    [TRANSMISSION]="DOWNLOADS|Transmission|Torrents|/icons/transmission.png|/transmission/|#343434"
    [DELUGE]="DOWNLOADS|Deluge|Torrent client|/icons/deluge.png|/deluge/|#3aa3e0"
    [PROWLARR]="INFRA|Prowlarr|Indexer manager|/icons/prowlarr.png|/prowlarr/|#e8810e"
)

# Convert service key to lowercase
service_to_id() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Generate services array for React component
generate_services_array() {
    local array=""
    local first=true
    
    for service_key in "${!SERVICES[@]}"; do
        # Check if service is enabled
        local enable_var="ENABLE_${service_key}"
        local is_enabled="${!enable_var}"
        
        # Skip disabled services
        if [ "$is_enabled" != "true" ]; then
            continue
        fi
        
        # Parse service metadata
        IFS='|' read -r category name desc icon href accent <<< "${SERVICES[$service_key]}"
        local id=$(service_to_id "$service_key")
        
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

# Main generation function
generate_html() {
    if [ ! -f "$DASHBOARD_TEMPLATE" ]; then
        echo "ERROR: Dashboard template not found: $DASHBOARD_TEMPLATE"
        return 1
    fi
    
    echo "Generating dynamic React dashboard..."
    echo ""
    
    # Generate services array
    local services_array=$(generate_services_array)
    
    # Count enabled services
    local count=0
    for service_key in "${!SERVICES[@]}"; do
        local enable_var="ENABLE_${service_key}"
        if [ "${!enable_var}" = "true" ]; then
            ((count++))
        fi
    done
    
    echo "Enabled services:"
    for service_key in "${!SERVICES[@]}"; do
        local enable_var="ENABLE_${service_key}"
        if [ "${!enable_var}" = "true" ]; then
            IFS='|' read -r category name desc icon href accent <<< "${SERVICES[$service_key]}"
            echo "  ✓ $name ($category)"
        fi
    done
    echo ""
    
    # Read template and replace placeholders
    local html_content=$(cat "$DASHBOARD_TEMPLATE")
    html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
    
    # Write output file
    echo "$html_content" > "$OUTPUT_FILE"
    
    echo "✓ Dashboard generated with $count enabled service(s)"
    echo "✓ Output: $OUTPUT_FILE"
}

# Run generation
generate_html

