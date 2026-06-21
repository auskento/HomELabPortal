#!/bin/bash

# Generate HTML Menu Based on Enabled Services
# Uses index.html.template with dynamic service icons
# Organized in same categories as React dashboard

SIMPLE_TEMPLATE="/var/www/html/index.html.template"
DASHBOARD_TEMPLATE="/var/www/html/index.html.dashboard"
SIMPLE_OUTPUT="/var/www/html/index.html"
DASHBOARD_OUTPUT="/var/www/html/dashboard.html"

# Define all available services with metadata (simple menu)
# Format: SERVICE_KEY="Category|Name|Icon|Href"
declare -A SERVICES=(
    # DOWNLOADERS category
    [SABNZBD]="DOWNLOADERS|SABnzbd|/icons/sabnzbd.png|/sabnzbd/"
    [DELUGE]="DOWNLOADERS|Deluge|/icons/deluge.png|/deluge/"
    [TRANSMISSION]="DOWNLOADERS|Transmission|/icons/transmission.png|/transmission/"
    [QBITTORRENT]="DOWNLOADERS|qBittorrent|/icons/qbittorrent.png|/qbittorrent/"
    
    # INDEXERS category
    [RADARR]="INDEXERS|Radarr|/icons/radarr.png|/radarr/"
    [SONARR]="INDEXERS|Sonarr|/icons/sonarr.png|/sonarr/calendar"
    [WHISPARR]="INDEXERS|Whisparr|/icons/whisparr.png|/whisparr/"
    [PROWLARR]="INDEXERS|Prowlarr|/icons/prowlarr.png|/prowlarr/"
    [OVERSEERR]="INDEXERS|Overseerr|/icons/overseerr.png|/overseerr/"
    [LIDARR]="INDEXERS|Lidarr|/icons/lidarr.png|/lidarr/"
    
    # MEDIA SERVERS category
    [EMBY]="MEDIA|Emby|/icons/emby.png|SUBDOMAIN"
    [PLEX]="MEDIA|Plex|/icons/plex.png|SUBDOMAIN"
    [JELLYFIN]="MEDIA|Jellyfin|/icons/jellyfin.png|/jellyfin/"
    [TAUTULLI]="MEDIA|Tautulli|/icons/tautulli.png|/tautulli/"
)

# Service display order (same order for both menus)
declare -a SERVICE_ORDER=(
    # DOWNLOADERS
    "SABNZBD" "DELUGE" "TRANSMISSION" "QBITTORRENT"
    # INDEXERS
    "RADARR" "SONARR" "WHISPARR" "PROWLARR" "OVERSEERR" "LIDARR"
    # MEDIA SERVERS
    "EMBY" "PLEX" "JELLYFIN" "TAUTULLI"
)

# Category labels
declare -A CATEGORY_LABEL=(
    [DOWNLOADERS]="DOWNLOADERS"
    [INDEXERS]="INDEXERS"
    [MEDIA]="MEDIA SERVERS"
)

# Generate menu items HTML in category order (for simple menu)
generate_menu_items() {
    local menu_html=""
    local current_category=""
    local first=true
    
    for service_key in "${SERVICE_ORDER[@]}"; do
        # Check if service is enabled
        local enable_var="ENABLE_${service_key}"
        local is_enabled="${!enable_var}"
        
        # Skip disabled services
        if [ "$is_enabled" != "true" ]; then
            continue
        fi
        
        # Parse service metadata
        IFS='|' read -r category service_name icon_path href <<< "${SERVICES[$service_key]}"
        
        # Handle subdomain services (Emby, Plex)
        if [ "$href" = "SUBDOMAIN" ]; then
            if [ "$service_key" = "EMBY" ]; then
                [ -z "$EMBY_DOMAIN" ] && continue
                href="https://$EMBY_DOMAIN/"
            elif [ "$service_key" = "PLEX" ]; then
                [ -z "$PLEX_DOMAIN" ] && continue
                href="https://$PLEX_DOMAIN/"
            fi
        fi
        
        # Add category header if changed
        if [ "$category" != "$current_category" ]; then
            if [ "$first" != "true" ]; then
                menu_html+="</td></tr><tr><td colspan='99'></td></tr><tr><td>"
            else
                menu_html+="<td>"
                first=false
            fi
            current_category="$category"
        else
            menu_html+="<td>"
        fi
        
        # Add menu item
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
    
    for service_key in "${SERVICE_ORDER[@]}"; do
        # Check if service is enabled
        local enable_var="ENABLE_${service_key}"
        local is_enabled="${!enable_var}"
        
        # Skip disabled services
        if [ "$is_enabled" != "true" ]; then
            continue
        fi
        
        # Parse service metadata
        IFS='|' read -r category service_name icon_path href <<< "${SERVICES[$service_key]}"
        
        # Handle subdomain services
        if [ "$href" = "SUBDOMAIN" ]; then
            if [ "$service_key" = "EMBY" ]; then
                [ -z "$EMBY_DOMAIN" ] && continue
                href="https://$EMBY_DOMAIN/"
            elif [ "$service_key" = "PLEX" ]; then
                [ -z "$PLEX_DOMAIN" ] && continue
                href="https://$PLEX_DOMAIN/"
            fi
        fi
        
        # Add list item
        list_html+="<li><a href='$href' target='content'>$service_name</a></li>"
    done
    
    # If no services enabled, show message
    if [ -z "$list_html" ]; then
        list_html="<li class='no-services'>⚠️ No services are currently enabled</li>"
    fi
    
    echo "$list_html"
}

# Generate services array for React dashboard (with categories)
generate_services_array() {
    local array=""
    local first=true
    
    for service_key in "${SERVICE_ORDER[@]}"; do
        # Check if service is enabled
        local enable_var="ENABLE_${service_key}"
        local is_enabled="${!enable_var}"
        
        # Skip disabled services
        if [ "$is_enabled" != "true" ]; then
            continue
        fi
        
        # Parse service metadata (format: category|name|desc|icon|href|accent)
        IFS='|' read -r category name desc icon href accent <<< "${SERVICES[$service_key]}"
        local id=$(echo "$service_key" | tr '[:upper:]' '[:lower:]')
        
        # Handle subdomain services
        if [ "$href" = "SUBDOMAIN" ]; then
            if [ "$service_key" = "EMBY" ]; then
                [ -z "$EMBY_DOMAIN" ] && continue
                href="https://$EMBY_DOMAIN/"
            elif [ "$service_key" = "PLEX" ]; then
                [ -z "$PLEX_DOMAIN" ] && continue
                href="https://$PLEX_DOMAIN/"
            fi
        fi
        
        # Determine if popup (external link)
        local popup="false"
        [[ "$href" == http* ]] && popup="true"
        
        # Add comma between items
        if [ "$first" = true ]; then
            first=false
        else
            array+=",$newline"
        fi
        
        # Add service object (using minimal info for now)
        array+="{ cat: '$category', id: '$id', name: '$name', desc: '$desc', icon: '$icon', href: '$href', accent: '#3aa0e0', popup: $popup }"
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
    echo "Generating both dashboards in synchronized order..."
    echo ""
    
    # Count enabled services
    local count=0
    for service_key in "${SERVICE_ORDER[@]}"; do
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
    echo "Service order matches:"
    echo "  1. MEDIA services"
    echo "  2. DOWNLOADS services"  
    echo "  3. INDEXERS & INFRA services"
}

# Run generation
generate_html




