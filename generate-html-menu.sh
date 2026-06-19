#!/bin/bash

# Generate HTML Dashboard Menu Based on Enabled Services
# This script reads ENABLE_* environment variables and generates
# the index.html menu dynamically

TEMPLATE_FILE="/var/www/html/index.html.template"
OUTPUT_FILE="/var/www/html/index.html"

# Define all available services with metadata
declare -A SERVICES=(
    [PROWLARR]="Prowlarr|9696|#4a9eff|Indexer Manager"
    [SONARR]="Sonarr|8989|#08a3d4|TV Shows"
    [RADARR]="Radarr|7878|#65b342|Movies"
    [WHISPARR]="Whisparr|6969|#d45ba0|Adult Collections"
    [LIDARR]="Lidarr|8686|#d45b9d|Music"
    [READARR]="Readarr|8787|#d48d4c|Books"
    [OVERSEERR]="Overseerr|5055|#00a4dc|Requests"
    [JELLYFIN]="Jellyfin|8096|#00a4dc|Streaming"
    [EMBY]="Emby|8096|#9146FF|Streaming"
    [PLEX]="Plex|32400|#e5a00d|Streaming"
    [TAUTULLI]="Tautulli|8181|#4a9eff|Analytics"
    [TRANSMISSION]="Transmission|6969|#343434|Torrents"
    [QBITTORRENT]="qBittorrent|8080|#3683b6|Torrents"
    [SABNZBD]="SABnzbd|8080|#f4a000|Usenet"
    [DELUGE]="Deluge|8112|#2d5016|Torrents"
)

# Convert service key to path (lowercase)
service_to_path() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Generate color SVG icon
generate_svg() {
    local name=$1
    local color=$2
    local short_name=$3
    
    cat << EOF
<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><rect fill='$color' width='100' height='100'/><text x='50' y='60' font-size='30' fill='white' text-anchor='middle' font-weight='bold'>$short_name</text></svg>
EOF
}

# Generate menu items HTML
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
        IFS='|' read -r service_name port color description <<< "${SERVICES[$service_key]}"
        local path=$(service_to_path "$service_key")
        local short_name="${service_name:0:3}"
        
        # Check for custom icon file
        local icon_path="/var/www/html/icons/${path}.png"
        local icon_path_jpg="/var/www/html/icons/${path}.jpg"
        local icon_path_svg="/var/www/html/icons/${path}.svg"
        local icon_html=""
        
        if [ -f "$icon_path" ]; then
            # Use PNG icon
            icon_html="<img alt='$service_name' src='/icons/${path}.png' title='$service_name - $description' />"
        elif [ -f "$icon_path_jpg" ]; then
            # Use JPG icon
            icon_html="<img alt='$service_name' src='/icons/${path}.jpg' title='$service_name - $description' />"
        elif [ -f "$icon_path_svg" ]; then
            # Use SVG icon
            icon_html="<img alt='$service_name' src='/icons/${path}.svg' title='$service_name - $description' />"
        else
            # Fall back to generated SVG
            local svg_data=$(generate_svg "$service_name" "$color" "$short_name")
            local svg_base64=$(echo -n "$svg_data" | base64 -w 0)
            icon_html="<img alt='$service_name' src='data:image/svg+xml;base64,$svg_base64' title='$service_name - $description' />"
        fi
        
        # Add menu item
        menu_html+="<td class='menu-item'>"
        menu_html+="<a href='/$path/' target='content' title='$service_name - $description'>"
        menu_html+="$icon_html"
        menu_html+="<span class='label'>$service_name</span>"
        menu_html+="</a>"
        menu_html+="</td>"
    done
    
    echo "$menu_html"
}

# Generate enabled services list for fallback
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
        IFS='|' read -r service_name port color description <<< "${SERVICES[$service_key]}"
        local path=$(service_to_path "$service_key")
        
        # Add list item
        list_html+="<li><a href='/$path/'>$service_name</a> - $description</li>"
    done
    
    # If no services enabled, show message
    if [ -z "$list_html" ]; then
        list_html="<li class='no-services'>⚠️ No services are currently enabled</li>"
    fi
    
    echo "$list_html"
}

# Main generation function
generate_html() {
    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo "ERROR: Template file not found: $TEMPLATE_FILE"
        return 1
    fi
    
    echo "Generating dashboard HTML from enabled services..."
    echo ""
    echo "Icon Status:"
    
    # Check icon availability
    for service_key in "${!SERVICES[@]}"; do
        local enable_var="ENABLE_${service_key}"
        if [ "${!enable_var}" = "true" ]; then
            local path=$(service_to_path "$service_key")
            local icon_status="❌ Using generated SVG"
            
            if [ -f "/var/www/html/icons/${path}.png" ]; then
                icon_status="✓ PNG icon found"
            elif [ -f "/var/www/html/icons/${path}.jpg" ]; then
                icon_status="✓ JPG icon found"
            elif [ -f "/var/www/html/icons/${path}.svg" ]; then
                icon_status="✓ SVG icon found"
            fi
            
            echo "  $service_key: $icon_status"
        fi
    done
    echo ""
    
    # Generate menu items and services list
    local menu_items=$(generate_menu_items)
    local services_list=$(generate_services_list)
    
    # Read template and replace placeholders
    local html_content=$(cat "$TEMPLATE_FILE")
    html_content="${html_content//@@MENU_ITEMS@@/$menu_items}"
    html_content="${html_content//@@ENABLED_SERVICES_LIST@@/$services_list}"
    
    # Write output file
    echo "$html_content" > "$OUTPUT_FILE"
    
    # Count enabled services
    local count=0
    for service_key in "${!SERVICES[@]}"; do
        local enable_var="ENABLE_${service_key}"
        if [ "${!enable_var}" = "true" ]; then
            ((count++))
        fi
    done
    
    echo "✓ Dashboard generated with $count enabled service(s)"
    echo "✓ Output: $OUTPUT_FILE"
}

# Run generation
generate_html
