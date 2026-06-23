#!/bin/bash

# Generate HTML Menu Based on Enabled Services
# Uses index.html.template with dynamic service icons
# Organized in same categories as React dashboard

# Source environment variables from config file written by entrypoint
if [ -f /etc/apache2/env.conf ]; then
    source /etc/apache2/env.conf
fi

SIMPLE_TEMPLATE="/var/www/html/index.html.template"
DASHBOARD_TEMPLATE="/var/www/html/index.html.dashboard"
SIMPLE_OUTPUT="/var/www/html/index.html"
DASHBOARD_OUTPUT="/var/www/html/dashboard.html"

# Define all available services with metadata
# Format: SERVICE_KEY="Category|Name|Description|Icon|Href|Accent"
# Categories MUST be: DOWNLOADS, INFRA, MEDIA (to match dashboard)
declare -A SERVICES=(
    # DOWNLOADS category
    [SABNZBD]="DOWNLOADS|SABnzbd|Usenet downloads|/icons/sabnzbd.png|/sabnzbd/|#f5c20f"
    [DELUGE]="DOWNLOADS|Deluge|Torrent client|/icons/deluge.png|/deluge/|#3aa3e0"
    [TRANSMISSION]="DOWNLOADS|Transmission|Torrents|/icons/transmission.png|/transmission/|#343434"
    [QBITTORRENT]="DOWNLOADS|qBittorrent|Torrent client|/icons/qbittorrent.png|/qbittorrent/|#3683b6"
    
    # INFRA category (Indexers & Infrastructure)
    [RADARR]="INFRA|Radarr|Movies|/icons/radarr.png|/radarr/|#febc2e"
    [SONARR]="INFRA|Sonarr|TV shows|/icons/sonarr.png|/sonarr/calendar|#3aa0e0"
    [WHISPARR]="INFRA|Whisparr|Adult content|/icons/whisparr.png|/whisparr/|#ef7e30"
    [PROWLARR]="INFRA|Prowlarr|Indexer manager|/icons/prowlarr.png|/prowlarr/|#e8810e"
    [SEERR]="INFRA|Seerr|Requests|/icons/seerr.png|/seerr/|#00a4dc"
    [LIDARR]="INFRA|Lidarr|Music|/icons/lidarr.png|/lidarr/|#2ecd6f"
    
    # MEDIA category
    [EMBY]="MEDIA|Emby|Streaming|/icons/emby.png|SUBDOMAIN|#9146FF"
    [PLEX]="MEDIA|Plex|Streaming|/icons/plex.png|SUBDOMAIN|#e5a00d"
    [JELLYFIN]="MEDIA|Jellyfin|Streaming|/icons/jellyfin.png|/jellyfin/|#00a4dc"
    [TAUTULLI]="MEDIA|Tautulli|Analytics|/icons/tautulli.png|/tautulli/|#4a9eff"
)

# Service display order (same order for both menus)
declare -a SERVICE_ORDER=(
    # DOWNLOADERS
    "SABNZBD" "DELUGE" "TRANSMISSION" "QBITTORRENT"
    # INDEXERS
    "RADARR" "SONARR" "WHISPARR" "PROWLARR" "SEERR" "LIDARR"
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
    
    for service_key in "${SERVICE_ORDER[@]}"; do
        # Check if service is enabled
        local enable_var="ENABLE_${service_key}"
        local is_enabled="${!enable_var}"
        
        # Skip disabled services
        if [ "$is_enabled" != "true" ]; then
            continue
        fi
        
        # Parse service metadata
        IFS='|' read -r category service_name service_desc icon_path href accent <<< "${SERVICES[$service_key]}"
        
        # Handle subdomain services (Emby, Plex)
        if [ "$href" = "SUBDOMAIN" ]; then
            if [ "$service_key" = "EMBY" ]; then
                if [ -z "$EMBY_DOMAIN" ]; then
                    continue
                fi
                href="https://$EMBY_DOMAIN/"
            elif [ "$service_key" = "PLEX" ]; then
                if [ -z "$PLEX_DOMAIN" ]; then
                    continue
                fi
                href="https://$PLEX_DOMAIN/"
            fi
        fi
        
        # Add menu item - NO label span!
        menu_html+="<td class='menu-item'><a href='$href' target='content' title='$service_name'><img src='$icon_path' alt='$service_name' /></a></td>"
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
        IFS='|' read -r category service_name service_desc icon_path href accent <<< "${SERVICES[$service_key]}"
        
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
        
        # Add service object with correct accent color
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
    
    # Set dashboard name and icon
    local DASHBOARD_NAME="${DASHBOARD_NAME:-Media Server}"
    local DASHBOARD_ICON="${DASHBOARD_ICON:-/icons/apache-reverse-proxy.png}"
    
    # Read template and replace placeholders
    local html_content=$(cat "$SIMPLE_TEMPLATE")
    html_content="${html_content//@@MENU_ITEMS@@/$menu_items}"
    html_content="${html_content//@@ENABLED_SERVICES_LIST@@/$services_list}"
    html_content="${html_content//@@DASHBOARD_NAME@@/$DASHBOARD_NAME}"
    html_content="${html_content//@@DASHBOARD_ICON@@/$DASHBOARD_ICON}"
    
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
    
    # Set dashboard name and icon
    local DASHBOARD_NAME="${DASHBOARD_NAME:-Media Server}"
    local DASHBOARD_ICON="${DASHBOARD_ICON:-/icons/apache-reverse-proxy.png}"
    
    # Read template and replace placeholders
    local html_content=$(cat "$DASHBOARD_TEMPLATE")
    html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
    html_content="${html_content//@@DASHBOARD_NAME@@/$DASHBOARD_NAME}"
    html_content="${html_content//@@DASHBOARD_ICON@@/$DASHBOARD_ICON}"
    
    # Write output file
    echo "$html_content" > "$DASHBOARD_OUTPUT"
    
    echo "✓ React dashboard generated: $DASHBOARD_OUTPUT"
    echo "Debug: Service count in dashboard array:"
    echo "$services_array" | grep -o "{ cat:" | wc -l
}

# Calculate dynamic icon sizes based on service count
# Returns responsive multipliers instead of fixed pixels
calculate_icon_sizes() {
    local service_count=$1
    local icon_multiplier gap_multiplier logo_multiplier

    # Service count tiers determine scaling multipliers
    # Icons will scale responsively: base_unit * multiplier
    if [ "$service_count" -le 5 ]; then
        icon_multiplier="1.3"
        gap_multiplier="1.2"
        logo_multiplier="1.25"
    elif [ "$service_count" -le 8 ]; then
        icon_multiplier="1.2"
        gap_multiplier="1.0"
        logo_multiplier="1.125"
    elif [ "$service_count" -le 12 ]; then
        icon_multiplier="1.1"
        gap_multiplier="0.8"
        logo_multiplier="1.0"
    elif [ "$service_count" -le 15 ]; then
        icon_multiplier="1.0"
        gap_multiplier="0.6"
        logo_multiplier="0.9375"
    else
        icon_multiplier="0.9"
        gap_multiplier="0.5"
        logo_multiplier="0.875"
    fi

    echo "$icon_multiplier|$gap_multiplier|$logo_multiplier"
}

# Generate icons-only services array for dashboard2
generate_dashboard2_services_array() {
    local array=""
    local first=true
    
    for service_key in "${SERVICE_ORDER[@]}"; do
        local enable_var="ENABLE_${service_key}"
        local is_enabled="${!enable_var}"
        
        if [ "$is_enabled" != "true" ]; then
            continue
        fi
        
        IFS='|' read -r category name desc icon href accent <<< "${SERVICES[$service_key]}"
        local id=$(echo "$service_key" | tr '[:upper:]' '[:lower:]')
        
        if [ "$href" = "SUBDOMAIN" ]; then
            if [ "$service_key" = "EMBY" ]; then
                [ -z "$EMBY_DOMAIN" ] && continue
                href="https://$EMBY_DOMAIN/"
            elif [ "$service_key" = "PLEX" ]; then
                [ -z "$PLEX_DOMAIN" ] && continue
                href="https://$PLEX_DOMAIN/"
            fi
        fi
        
        local popup="false"
        [[ "$href" == http* ]] && popup="true"
        
        if [ "$first" = true ]; then
            first=false
        else
            array+=","
        fi
        
        array+="{ id: '${id}', name: '${name}', icon: '${icon}', href: '${href}', accent: '${accent}', popup: ${popup} }"
    done
    
    echo "[$array]"
}

# Generate dashboard based on authentication type
generate_dashboard_for_auth() {
    local DASHBOARD_OUTPUT="/var/www/html/dashboard2.html"
    local DASHBOARD_TEMPLATE=""

    # Choose template based on AUTHTYPE
    if [ "$AUTHTYPE" = "oauth" ]; then
        DASHBOARD_TEMPLATE="/var/www/html/dashboard-oauth.html.template"
    else
        # Default to basic auth dashboard (direct links, no iframes)
        DASHBOARD_TEMPLATE="/var/www/html/dashboard2.html.template"
    fi

    if [ ! -f "$DASHBOARD_TEMPLATE" ]; then
        echo "⚠ Dashboard template not found: $DASHBOARD_TEMPLATE"
        return
    fi

    # Count enabled services
    local service_count=0
    for service_key in "${SERVICE_ORDER[@]}"; do
        local enable_var="ENABLE_${service_key}"
        if [ "${!enable_var}" = "true" ]; then
            ((service_count++))
        fi
    done

    local services_array=$(generate_dashboard2_services_array)

    # Set dashboard name and icon
    local DASHBOARD_NAME="${DASHBOARD_NAME:-Media Server}"
    local DASHBOARD_ICON="${DASHBOARD_ICON:-/icons/apache-reverse-proxy.png}"

    # Calculate dynamic icon sizes
    local sizes=$(calculate_icon_sizes "$service_count")
    local ICON_SIZE=$(echo "$sizes" | cut -d'|' -f1)
    local ICON_GAP=$(echo "$sizes" | cut -d'|' -f2)
    local LOGO_SIZE=$(echo "$sizes" | cut -d'|' -f3)

    local html_content=$(cat "$DASHBOARD_TEMPLATE")
    html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
    html_content="${html_content//@@DASHBOARD_NAME@@/$DASHBOARD_NAME}"
    html_content="${html_content//@@DASHBOARD_ICON@@/$DASHBOARD_ICON}"
    html_content="${html_content//@@ICON_SIZE@@/$ICON_SIZE}"
    html_content="${html_content//@@ICON_GAP@@/$ICON_GAP}"
    html_content="${html_content//@@LOGO_SIZE@@/$LOGO_SIZE}"

    echo "$html_content" > "$DASHBOARD_OUTPUT"

    if [ "$AUTHTYPE" = "oauth" ]; then
        echo "✓ OAuth dashboard generated (with iframes): $DASHBOARD_OUTPUT"
    else
        echo "✓ Basic auth dashboard generated ($service_count services, $ICON_SIZE icons): $DASHBOARD_OUTPUT"
    fi
}

# Generate icons-only dashboard (dashboard2.html)
generate_dashboard2() {
    generate_dashboard_for_auth
}

# Generate grid-based dashboard (dashboard3.html with auto-fit columns)
generate_dashboard3() {
    local DASHBOARD_OUTPUT="/var/www/html/dashboard3.html"
    local DASHBOARD_TEMPLATE="/var/www/html/dashboard3.html.template"

    if [ ! -f "$DASHBOARD_TEMPLATE" ]; then
        echo "⚠ Dashboard3 template not found: $DASHBOARD_TEMPLATE"
        return
    fi

    # Count enabled services
    local service_count=0
    for service_key in "${SERVICE_ORDER[@]}"; do
        local enable_var="ENABLE_${service_key}"
        if [ "${!enable_var}" = "true" ]; then
            ((service_count++))
        fi
    done

    local services_array=$(generate_dashboard2_services_array)

    # Set dashboard name and icon
    local DASHBOARD_NAME="${DASHBOARD_NAME:-Media Server}"
    local DASHBOARD_ICON="${DASHBOARD_ICON:-/icons/apache-reverse-proxy.png}"

    # Calculate dynamic icon sizes
    local sizes=$(calculate_icon_sizes "$service_count")
    local ICON_SIZE=$(echo "$sizes" | cut -d'|' -f1)
    local ICON_GAP=$(echo "$sizes" | cut -d'|' -f2)
    local LOGO_SIZE=$(echo "$sizes" | cut -d'|' -f3)

    local html_content=$(cat "$DASHBOARD_TEMPLATE")
    html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
    html_content="${html_content//@@DASHBOARD_NAME@@/$DASHBOARD_NAME}"
    html_content="${html_content//@@DASHBOARD_ICON@@/$DASHBOARD_ICON}"
    html_content="${html_content//@@ICON_SIZE@@/$ICON_SIZE}"
    html_content="${html_content//@@ICON_GAP@@/$ICON_GAP}"
    html_content="${html_content//@@LOGO_SIZE@@/$LOGO_SIZE}"

    echo "$html_content" > "$DASHBOARD_OUTPUT"

    echo "✓ Grid dashboard generated (auto-fit columns): $DASHBOARD_OUTPUT"
}

# Main generation function
generate_html() {
    echo "Generating all dashboards in synchronized order..."
    echo ""

    # Count enabled services
    local count=0
    for service_key in "${SERVICE_ORDER[@]}"; do
        local enable_var="ENABLE_${service_key}"
        if [ "${!enable_var}" = "true" ]; then
            ((count++))
        fi
    done

    # Generate all versions
    generate_simple_menu
    generate_react_dashboard
    generate_dashboard2
    generate_dashboard3

    echo ""
    echo "✓ All dashboards generated with $count enabled service(s)"
    echo ""
    echo "Available at:"
    echo "  /index.html (classic menu)"
    echo "  /dashboard.html (React modern UI)"
    echo "  /dashboard2.html (iframes, single column)"
    echo "  /dashboard3.html (iframes, auto-fit grid columns)"
}

# Run generation
generate_html




