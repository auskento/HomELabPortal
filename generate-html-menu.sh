#!/bin/bash

# Generate HTML Menu Based on Enabled Services
# Uses index.html.template with dynamic service icons
# Organized in same categories as React dashboard

# Source environment variables from config file written by entrypoint
if [ -f /etc/apache2/env.conf ]; then
    source /etc/apache2/env.conf
fi

CLASSIC_TEMPLATE="/var/www/html/classic.template"
MODERN_TEMPLATE="/var/www/html/modern.template"
SLEEK_TEMPLATE="/var/www/html/sleek.template"
MINIMAL_TEMPLATE="/var/www/html/minimal.template"
DASHBOARD_OAUTH_TEMPLATE="/var/www/html/dashboard-oauth.html.template"

# Define all available services with metadata
# Format: SERVICE_KEY="Category|Name|Description|Icon|Href|Accent"
# Categories: USENET, TORRENTS, CONTENT, SEARCH, MEDIA
declare -A SERVICES=(
    # USENET category
    [SABNZBD]="USENET|SABnzbd|Usenet downloads|/icons/sabnzbd.png|/sabnzbd/|#f5c20f"
    [NZBGET]="USENET|NZBGet|Usenet downloads|/icons/nzbget.png|/nzbget/|#3da7e0"
    [NZBHYDRA]="USENET|NZBHydra|NZB indexer|/icons/nzbhydra.png|/nzbhydra/|#3e9c7d"

    # TORRENTS category
    [DELUGE]="TORRENTS|Deluge|Torrent client|/icons/deluge.png|/deluge/|#3aa3e0"
    [TRANSMISSION]="TORRENTS|Transmission|Torrents|/icons/transmission.png|/transmission/|#343434"
    [QBITTORRENT]="TORRENTS|qBittorrent|Torrent client|/icons/qbittorrent.png|/qbittorrent/|#3683b6"

    # CONTENT category
    [SONARR]="CONTENT|Sonarr|TV shows|/icons/sonarr.png|/sonarr/calendar|#3aa0e0"
    [RADARR]="CONTENT|Radarr|Movies|/icons/radarr.png|/radarr/|#febc2e"
    [LIDARR]="CONTENT|Lidarr|Music|/icons/lidarr.png|/lidarr/|#2ecd6f"
    [WHISPARR]="CONTENT|Whisparr|Adult content|/icons/whisparr.png|/whisparr/|#ef7e30"

    # SEARCH category
    [SEERR]="SEARCH|Seerr|Requests|/icons/seerr.png|/seerr/|#00a4dc"
    [PROWLARR]="SEARCH|Prowlarr|Indexer manager|/icons/prowlarr.png|/prowlarr/|#e8810e"
    [BAZARR]="SEARCH|Bazarr|Subtitles|/icons/bazarr.png|/bazarr/|#e91e63"

    # MEDIA category
    [EMBY]="MEDIA|Emby|Streaming|/icons/emby.png|SUBDOMAIN|#9146FF"
    [PLEX]="MEDIA|Plex|Streaming|/icons/plex.png|SUBDOMAIN|#e5a00d"
    [JELLYFIN]="MEDIA|Jellyfin|Streaming|/icons/jellyfin.png|/jellyfin/|#00a4dc"
    [TAUTULLI]="MEDIA|Tautulli|Analytics|/icons/tautulli.png|/tautulli/|#4a9eff"
)

# Service display order (same order for both menus)
declare -a SERVICE_ORDER=(
    # USENET
    "SABNZBD" "NZBGET" "NZBHYDRA"
    # TORRENTS
    "DELUGE" "TRANSMISSION" "QBITTORRENT"
    # CONTENT
    "SONARR" "RADARR" "LIDARR" "WHISPARR"
    # SEARCH
    "SEERR" "PROWLARR" "BAZARR"
    # MEDIA
    "EMBY" "PLEX" "JELLYFIN" "TAUTULLI"
)

# Category labels
declare -A CATEGORY_LABEL=(
    [USENET]="USENET"
    [TORRENTS]="TORRENTS"
    [CONTENT]="CONTENT"
    [SEARCH]="SEARCH"
    [MEDIA]="MEDIA"
)

# Generate group order from DASHBOARD_ORDER variable
generate_group_order() {
    local dash_order="${DASHBOARD_ORDER:-CONTENT,SEARCH,USENET,TORRENTS,MEDIA}"
    local items=()

    # Split by comma and convert to uppercase
    IFS=',' read -ra groups <<< "$dash_order"
    for group in "${groups[@]}"; do
        # Trim whitespace
        group=$(echo "$group" | xargs)
        # Convert to uppercase for category matching
        local cat_upper=$(echo "$group" | tr '[:lower:]' '[:upper:]')
        items+=("'$cat_upper'")
    done

    # Join array with commas and output as JavaScript array literal
    local IFS=', '
    echo "[${items[*]}]"
}

# Generate menu items HTML respecting DASHBOARD_ORDER
generate_menu_items() {
    local menu_html=""

    # Parse DASHBOARD_ORDER to get group ordering
    local dash_order="${DASHBOARD_ORDER:-CONTENT,SEARCH,USENET,TORRENTS,MEDIA}"
    IFS=',' read -ra group_order <<< "$dash_order"

    # Convert group names to uppercase for matching
    for i in "${!group_order[@]}"; do
        group_order[$i]=$(echo "${group_order[$i]}" | xargs | tr '[:lower:]' '[:upper:]')
    done

    # Process services in DASHBOARD_ORDER group order
    for group in "${group_order[@]}"; do
        for service_key in "${SERVICE_ORDER[@]}"; do
            # Get service category
            IFS='|' read -r category rest <<< "${SERVICES[$service_key]}"

            # Skip if not in current group
            [ "$category" != "$group" ] && continue

            # Check if service is enabled
            local enable_var="ENABLE_${service_key}"
            local is_enabled="${!enable_var}"

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

            # Check if this service should open in a popup (qBittorrent, external links, etc)
            local popup_attr=""
            if [[ "$service_key" == "QBITTORRENT" ]] || [[ "$href" == http* ]]; then
                popup_attr=" onclick=\"window.open(this.href, '$service_name', 'resizable=yes,status=yes,location=yes,toolbar=yes,menubar=yes,scrollbars=yes'); return false;\""
            else
                popup_attr=" target='Main'"
            fi

            # Add menu item - NO label span!
            menu_html+="<td class='menu-item'><a href='$href'$popup_attr title='$service_name'><img src='$icon_path' alt='$service_name' /></a></td>"
        done
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

        # Determine if popup (external link or qBittorrent)
        local popup="false"
        [[ "$href" == http* ]] && popup="true"
        [[ "$service_key" == "QBITTORRENT" ]] && popup="true"

        # Add comma between items (with newline for readability)
        if [ "$first" = true ]; then
            first=false
        else
            array+=",$( printf '\n    ')"
        fi

        # Add service object with correct accent color
        array+="{ cat: '$category', id: '$id', name: '$name', desc: '$desc', icon: '$icon', href: '$href', accent: '$accent', popup: $popup }"
    done

    echo "$array"
}

# Generate dashboard based on STYLE
generate_style_dashboard() {
    local STYLE="${STYLE:-classic}"
    local OUTPUT_FILE="/var/www/html/index.html"
    local TEMPLATE_FILE

    # Map style to template
    case "$STYLE" in
        classic)
            TEMPLATE_FILE="$CLASSIC_TEMPLATE"
            ;;
        modern)
            TEMPLATE_FILE="$MODERN_TEMPLATE"
            ;;
        sleek)
            TEMPLATE_FILE="$SLEEK_TEMPLATE"
            ;;
        minimal)
            TEMPLATE_FILE="$MINIMAL_TEMPLATE"
            ;;
        *)
            echo "ERROR: Invalid STYLE: $STYLE"
            return 1
            ;;
    esac

    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo "ERROR: Template not found: $TEMPLATE_FILE"
        return 1
    fi

    # For classic style, generate menu items and services list
    if [ "$STYLE" = "classic" ]; then
        local menu_items=$(generate_menu_items)
        local services_list=$(generate_services_list)

        local html_content=$(cat "$TEMPLATE_FILE")
        html_content="${html_content//@@MENU_ITEMS@@/$menu_items}"
        html_content="${html_content//@@ENABLED_SERVICES_LIST@@/$services_list}"
        html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
        html_content="${html_content//@@DASHBOARD_ICON@@/${DASHBOARD_ICON:-/icons/homelabportal.png}}"
        html_content="${html_content//@@DASHBOARD_THEME@@/${DASHBOARD_THEME:-dark}}"

        if [ -z "$DASHBOARD_LANDING" ]; then
            html_content=$(echo "$html_content" | sed 's|src="/@@DASHBOARD_LANDING@@"|src="about:blank"|')
        else
            html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
        fi

        echo "$html_content" > "$OUTPUT_FILE"
    elif [ "$STYLE" = "modern" ]; then
        # Modern dashboard uses React with full services array (with categories)
        local services_array=$(generate_services_array)
        local dash_order=$(generate_group_order)
        local html_content=$(cat "$TEMPLATE_FILE")
        html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
        html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
        html_content="${html_content//@@DASHBOARD_ICON@@/${DASHBOARD_ICON:-/icons/homelabportal.png}}"
        html_content="${html_content//@@DASHBOARD_ORDER@@/$dash_order}"
        html_content="${html_content//@@DASHBOARD_THEME@@/${DASHBOARD_THEME:-dark}}"

        if [ -z "$DASHBOARD_LANDING" ]; then
            html_content=$(echo "$html_content" | sed 's|src="/@@DASHBOARD_LANDING@@"||')
        else
            html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
        fi

        echo "$html_content" > "$OUTPUT_FILE"
    else
        # For sleek and minimal styles, generate icons-only services array
        local services_array=$(generate_dashboard2_services_array)
        local service_count=0
        for service_key in "${SERVICE_ORDER[@]}"; do
            local enable_var="ENABLE_${service_key}"
            if [ "${!enable_var}" = "true" ]; then
                ((service_count++))
            fi
        done

        local sizes=$(calculate_icon_sizes "$service_count")
        local ICON_SIZE=$(echo "$sizes" | cut -d'|' -f1)
        local ICON_GAP=$(echo "$sizes" | cut -d'|' -f2)
        local LOGO_SIZE=$(echo "$sizes" | cut -d'|' -f3)

        local html_content=$(cat "$TEMPLATE_FILE")
        html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
        html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
        html_content="${html_content//@@DASHBOARD_ICON@@/${DASHBOARD_ICON:-/icons/homelabportal.png}}"
        html_content="${html_content//@@DASHBOARD_THEME@@/${DASHBOARD_THEME:-dark}}"

        if [ -z "$DASHBOARD_LANDING" ]; then
            html_content=$(echo "$html_content" | sed 's|src="/@@DASHBOARD_LANDING@@"||')
        else
            html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
        fi

        html_content="${html_content//@@ICON_SIZE@@/$ICON_SIZE}"
        html_content="${html_content//@@ICON_GAP@@/$ICON_GAP}"
        html_content="${html_content//@@LOGO_SIZE@@/$LOGO_SIZE}"

        echo "$html_content" > "$OUTPUT_FILE"
    fi

    echo "✓ Dashboard generated: $STYLE → $OUTPUT_FILE"
}

# Generate all dashboard styles for style switching
generate_all_styles() {
    local STYLE="${STYLE:-classic}"
    local service_count=0
    for service_key in "${SERVICE_ORDER[@]}"; do
        local enable_var="ENABLE_${service_key}"
        if [ "${!enable_var}" = "true" ]; then
            ((service_count++))
        fi
    done

    local sizes=$(calculate_icon_sizes "$service_count")
    local ICON_SIZE=$(echo "$sizes" | cut -d'|' -f1)
    local ICON_GAP=$(echo "$sizes" | cut -d'|' -f2)
    local LOGO_SIZE=$(echo "$sizes" | cut -d'|' -f3)

    # Generate Classic (always)
    if [ -f "$CLASSIC_TEMPLATE" ]; then
        local menu_items=$(generate_menu_items)
        local services_list=$(generate_services_list)
        local html_content=$(cat "$CLASSIC_TEMPLATE")
        html_content="${html_content//@@MENU_ITEMS@@/$menu_items}"
        html_content="${html_content//@@ENABLED_SERVICES_LIST@@/$services_list}"
        html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
        html_content="${html_content//@@DASHBOARD_ICON@@/${DASHBOARD_ICON:-/icons/homelabportal.png}}"
        if [ -z "$DASHBOARD_LANDING" ]; then
            html_content=$(echo "$html_content" | sed 's|src="/@@DASHBOARD_LANDING@@"|src="about:blank"|')
        else
            html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
        fi
        echo "$html_content" > "/var/www/html/classic.html"
    fi

    # Generate Modern (always)
    if [ -f "$MODERN_TEMPLATE" ]; then
        local services_array=$(generate_services_array)
        local dash_order=$(generate_group_order)
        local html_content=$(cat "$MODERN_TEMPLATE")
        html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
        html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
        html_content="${html_content//@@DASHBOARD_ICON@@/${DASHBOARD_ICON:-/icons/homelabportal.png}}"
        html_content="${html_content//@@DASHBOARD_ORDER@@/$dash_order}"
        if [ -z "$DASHBOARD_LANDING" ]; then
            html_content=$(echo "$html_content" | sed 's|src="/@@DASHBOARD_LANDING@@"||')
        else
            html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
        fi
        echo "$html_content" > "/var/www/html/modern.html"
    fi

    # Generate Sleek (always)
    if [ -f "$SLEEK_TEMPLATE" ]; then
        local services_array=$(generate_dashboard2_services_array)
        local html_content=$(cat "$SLEEK_TEMPLATE")
        html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
        html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
        html_content="${html_content//@@DASHBOARD_ICON@@/${DASHBOARD_ICON:-/icons/homelabportal.png}}"
        if [ -z "$DASHBOARD_LANDING" ]; then
            html_content=$(echo "$html_content" | sed 's|src="/@@DASHBOARD_LANDING@@"||')
        else
            html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
        fi
        html_content="${html_content//@@ICON_SIZE@@/$ICON_SIZE}"
        html_content="${html_content//@@ICON_GAP@@/$ICON_GAP}"
        html_content="${html_content//@@LOGO_SIZE@@/$LOGO_SIZE}"
        echo "$html_content" > "/var/www/html/sleek.html"
    fi

    # Generate Minimal (always)
    if [ -f "$MINIMAL_TEMPLATE" ]; then
        local services_array=$(generate_dashboard2_services_array)
        local html_content=$(cat "$MINIMAL_TEMPLATE")
        html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
        html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
        html_content="${html_content//@@DASHBOARD_ICON@@/${DASHBOARD_ICON:-/icons/homelabportal.png}}"
        if [ -z "$DASHBOARD_LANDING" ]; then
            html_content=$(echo "$html_content" | sed 's|src="/@@DASHBOARD_LANDING@@"||')
        else
            html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
        fi
        html_content="${html_content//@@ICON_SIZE@@/$ICON_SIZE}"
        html_content="${html_content//@@ICON_GAP@@/$ICON_GAP}"
        html_content="${html_content//@@LOGO_SIZE@@/$LOGO_SIZE}"
        echo "$html_content" > "/var/www/html/minimal.html"
    fi
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
    local dash_order=$(generate_group_order)

    # Set dashboard name, icon, and landing page
    local DASHBOARD_NAME="${DASHBOARD_NAME:-Media Server}"
    local DASHBOARD_ICON="${DASHBOARD_ICON:-/icons/homelabportal.png}"
    local DASHBOARD_LANDING="${DASHBOARD_LANDING:-}"

    # Read template and replace placeholders
    local html_content=$(cat "$DASHBOARD_TEMPLATE")
    html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
    html_content="${html_content//@@DASHBOARD_NAME@@/$DASHBOARD_NAME}"
    html_content="${html_content//@@DASHBOARD_ICON@@/$DASHBOARD_ICON}"
    html_content="${html_content//@@DASHBOARD_ORDER@@/$dash_order}"

    # Only set iframe src if DASHBOARD_LANDING is provided
    if [ -z "$DASHBOARD_LANDING" ]; then
        html_content=$(echo "$html_content" | sed 's|src="/@@DASHBOARD_LANDING@@"||')
    else
        html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
    fi

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
    # Larger multipliers for 2-column grid layout
    if [ "$service_count" -le 5 ]; then
        icon_multiplier="1.7"
        gap_multiplier="1.4"
        logo_multiplier="1.5"
    elif [ "$service_count" -le 8 ]; then
        icon_multiplier="1.6"
        gap_multiplier="1.2"
        logo_multiplier="1.375"
    elif [ "$service_count" -le 12 ]; then
        icon_multiplier="1.5"
        gap_multiplier="1.0"
        logo_multiplier="1.25"
    elif [ "$service_count" -le 15 ]; then
        icon_multiplier="1.4"
        gap_multiplier="0.8"
        logo_multiplier="1.125"
    else
        icon_multiplier="1.2"
        gap_multiplier="0.6"
        logo_multiplier="1.0"
    fi

    echo "$icon_multiplier|$gap_multiplier|$logo_multiplier"
}

# Generate icons-only services array for dashboard2 (respects DASHBOARD_ORDER)
generate_dashboard2_services_array() {
    local array=""
    local first=true

    # Parse DASHBOARD_ORDER to get group ordering
    local dash_order="${DASHBOARD_ORDER:-CONTENT,SEARCH,USENET,TORRENTS,MEDIA}"
    IFS=',' read -ra group_order <<< "$dash_order"

    # Convert group names to uppercase for matching
    for i in "${!group_order[@]}"; do
        group_order[$i]=$(echo "${group_order[$i]}" | xargs | tr '[:lower:]' '[:upper:]')
    done

    # Process services in DASHBOARD_ORDER group order
    for group in "${group_order[@]}"; do
        for service_key in "${SERVICE_ORDER[@]}"; do
            # Get service category
            IFS='|' read -r category rest <<< "${SERVICES[$service_key]}"

            # Skip if not in current group
            [ "$category" != "$group" ] && continue

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
            [[ "$service_key" == "QBITTORRENT" ]] && popup="true"

            if [ "$first" = true ]; then
                first=false
            else
                array+=","
            fi

            array+="{ id: '${id}', name: '${name}', icon: '${icon}', href: '${href}', accent: '${accent}', popup: ${popup} }"
        done
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

    # Set dashboard name, icon, and landing page
    local DASHBOARD_NAME="${DASHBOARD_NAME:-Media Server}"
    local DASHBOARD_ICON="${DASHBOARD_ICON:-/icons/homelabportal.png}"
    local DASHBOARD_LANDING="${DASHBOARD_LANDING:-}"

    # Calculate dynamic icon sizes
    local sizes=$(calculate_icon_sizes "$service_count")
    local ICON_SIZE=$(echo "$sizes" | cut -d'|' -f1)
    local ICON_GAP=$(echo "$sizes" | cut -d'|' -f2)
    local LOGO_SIZE=$(echo "$sizes" | cut -d'|' -f3)

    local html_content=$(cat "$DASHBOARD_TEMPLATE")
    html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
    html_content="${html_content//@@DASHBOARD_NAME@@/$DASHBOARD_NAME}"
    html_content="${html_content//@@DASHBOARD_ICON@@/$DASHBOARD_ICON}"

    # Only set iframe src if DASHBOARD_LANDING is provided; otherwise remove src attribute to show welcome screen
    if [ -z "$DASHBOARD_LANDING" ]; then
        html_content=$(echo "$html_content" | sed 's|src="/@@DASHBOARD_LANDING@@"||')
    else
        html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
    fi

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

    # Set dashboard name, icon, and landing page
    local DASHBOARD_NAME="${DASHBOARD_NAME:-Media Server}"
    local DASHBOARD_ICON="${DASHBOARD_ICON:-/icons/homelabportal.png}"
    local DASHBOARD_LANDING="${DASHBOARD_LANDING:-}"

    # Calculate dynamic icon sizes
    local sizes=$(calculate_icon_sizes "$service_count")
    local ICON_SIZE=$(echo "$sizes" | cut -d'|' -f1)
    local ICON_GAP=$(echo "$sizes" | cut -d'|' -f2)
    local LOGO_SIZE=$(echo "$sizes" | cut -d'|' -f3)

    local html_content=$(cat "$DASHBOARD_TEMPLATE")
    html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
    html_content="${html_content//@@DASHBOARD_NAME@@/$DASHBOARD_NAME}"
    html_content="${html_content//@@DASHBOARD_ICON@@/$DASHBOARD_ICON}"

    # Only set iframe src if DASHBOARD_LANDING is provided; otherwise remove src attribute to show welcome screen
    if [ -z "$DASHBOARD_LANDING" ]; then
        html_content=$(echo "$html_content" | sed 's|src="/@@DASHBOARD_LANDING@@"||')
    else
        html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
    fi

    html_content="${html_content//@@ICON_SIZE@@/$ICON_SIZE}"
    html_content="${html_content//@@ICON_GAP@@/$ICON_GAP}"
    html_content="${html_content//@@LOGO_SIZE@@/$LOGO_SIZE}"

    echo "$html_content" > "$DASHBOARD_OUTPUT"

    echo "✓ Grid dashboard generated (auto-fit columns): $DASHBOARD_OUTPUT"
}

# Generate basic standalone dashboard
generate_basic() {
    if [ ! -f "/var/www/html/basic.template" ]; then
        return
    fi

    local menu_items=$(generate_menu_items)
    local html_content=$(cat "/var/www/html/basic.template")
    html_content="${html_content//@@MENU_ITEMS@@/$menu_items}"
    html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"

    if [ -z "$DASHBOARD_LANDING" ]; then
        html_content=$(echo "$html_content" | sed 's|/@@DASHBOARD_LANDING@@|/index.html|')
    else
        html_content="${html_content//@@DASHBOARD_LANDING@@/$DASHBOARD_LANDING}"
    fi

    echo "$html_content" > "/var/www/html/basic.html"
    echo "✓ Basic dashboard generated: /basic.html"
}

# Main generation function
generate_html() {
    echo "Generating dashboards for STYLE=$STYLE..."
    echo ""

    # Count enabled services
    local count=0
    for service_key in "${SERVICE_ORDER[@]}"; do
        local enable_var="ENABLE_${service_key}"
        if [ "${!enable_var}" = "true" ]; then
            ((count++))
        fi
    done

    # Generate primary dashboard based on STYLE
    generate_style_dashboard

    # Generate all alternate styles for switching between any style
    generate_all_styles

    # Generate basic standalone dashboard (not referenced elsewhere)
    generate_basic

    echo ""
    echo "✓ Dashboards generated with $count enabled service(s)"
    echo ""
    echo "Available dashboards:"
    echo "  /index.html (primary: $STYLE)"
    echo "  /classic.html"
    echo "  /modern.html"
    echo "  /sleek.html"
    echo "  /minimal.html"
}

# Run generation
generate_html




