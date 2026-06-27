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
MOBILE_TEMPLATE="/var/www/html/mobile.template"
DASHBOARD_OAUTH_TEMPLATE="/var/www/html/dashboard-oauth.html.template"
SITES_JSON="/var/log/apache2/sites/sites.json"
SITES_DIR="/var/log/apache2/sites"

# Function to generate sites HTML
generate_sites_html() {
    local sites_html=""

    if [ ! -f "$SITES_JSON" ]; then
        return
    fi

    if [ -z "$SITES_ENABLED" ]; then
        return
    fi

    # Parse SITES_ENABLED and generate HTML for each enabled site
    IFS=',' read -ra CODES <<< "$SITES_ENABLED"
    for code in "${CODES[@]}"; do
        code=$(echo "$code" | xargs)  # Trim whitespace

        # Extract site URL from sites.json using grep/sed
        url=$(grep -A 3 "\"code\": \"$code\"" "$SITES_JSON" | grep "\"url\"" | sed 's/.*"url": "\(.*\)".*/\1/')
        name=$(grep -A 2 "\"code\": \"$code\"" "$SITES_JSON" | grep "\"name\"" | sed 's/.*"name": "\(.*\)".*/\1/')

        if [ ! -z "$url" ]; then
            # Check if favicon exists
            favicon_file="$SITES_DIR/${code,,}.favicon.ico"
            if [ -f "$favicon_file" ]; then
                favicon_url="/sites/${code,,}.favicon.ico"
                # Include site if favicon exists (all on one line to avoid bash parameter expansion issues)
                sites_html+="<a href='$url' class='site-link' title='$name' target='_blank'><div class='site-icon'><img src='$favicon_url' alt='$name' /></div></a>"
            fi
        fi
    done

    # Output on single line to prevent bash parameter expansion issues
    printf '%s' "$sites_html"
}

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
    [SONARR]="CONTENT|Sonarr|TV shows|/icons/sonarr.png|@@SONARR_LANDING@@|#3aa0e0"
    [RADARR]="CONTENT|Radarr|Movies|/icons/radarr.png|@@RADARR_LANDING@@|#febc2e"
    [LIDARR]="CONTENT|Lidarr|Music|/icons/lidarr.png|@@LIDARR_LANDING@@|#2ecd6f"
    [WHISPARR]="CONTENT|Whisparr|Adult content|/icons/whisparr.png|@@WHISPARR_LANDING@@|#ef7e30"

    # SEARCH category
    [SEERR]="SEARCH|Seerr|Requests|/icons/seerr.png|SUBDOMAIN|#00a4dc"
    [PROWLARR]="SEARCH|Prowlarr|Indexer manager|/icons/prowlarr.png|/prowlarr/|#e8810e"
    [BAZARR]="SEARCH|Bazarr|Subtitles|/icons/bazarr.png|/bazarr/|#e91e63"

    # MEDIA category
    [EMBY]="MEDIA|Emby|Streaming|/icons/emby.png|SUBDOMAIN|#9146FF"
    [PLEX]="MEDIA|Plex|Streaming|/icons/plex.png|SUBDOMAIN|#e5a00d"
    [JELLYFIN]="MEDIA|Jellyfin|Streaming|/icons/jellyfin.png|/jellyfin/|#00a4dc"
    [TAUTULLI]="MEDIA|Tautulli|Analytics|/icons/tautulli.png|/tautulli/|#4a9eff"
)

# Substitute service landing page variables
# If DASHBOARD_LANDING is set, sync the corresponding service landing page
if [ ! -z "$DASHBOARD_LANDING" ]; then
    # Extract service name from DASHBOARD_LANDING (first path component)
    local service_name=$(echo "$DASHBOARD_LANDING" | sed 's|^/||' | cut -d'/' -f1)

    case "$service_name" in
        sonarr)
            SONARR_LANDING="${SONARR_LANDING:-$DASHBOARD_LANDING}"
            ;;
        radarr)
            RADARR_LANDING="${RADARR_LANDING:-$DASHBOARD_LANDING}"
            ;;
        lidarr)
            LIDARR_LANDING="${LIDARR_LANDING:-$DASHBOARD_LANDING}"
            ;;
        whisparr)
            WHISPARR_LANDING="${WHISPARR_LANDING:-$DASHBOARD_LANDING}"
            ;;
    esac
fi

# Format hrefs to use "/" prefix for consistency
SONARR_LANDING="${SONARR_LANDING:-sonarr}"
RADARR_LANDING="${RADARR_LANDING:-radarr}"
LIDARR_LANDING="${LIDARR_LANDING:-lidarr}"
WHISPARR_LANDING="${WHISPARR_LANDING:-whisparr}"

# Ensure landing pages start with /
[[ ! "$SONARR_LANDING" =~ ^/ ]] && SONARR_LANDING="/$SONARR_LANDING"
[[ ! "$RADARR_LANDING" =~ ^/ ]] && RADARR_LANDING="/$RADARR_LANDING"
[[ ! "$LIDARR_LANDING" =~ ^/ ]] && LIDARR_LANDING="/$LIDARR_LANDING"
[[ ! "$WHISPARR_LANDING" =~ ^/ ]] && WHISPARR_LANDING="/$WHISPARR_LANDING"

# Ensure landing pages end with /
[[ ! "$SONARR_LANDING" =~ /$ ]] && SONARR_LANDING="$SONARR_LANDING/"
[[ ! "$RADARR_LANDING" =~ /$ ]] && RADARR_LANDING="$RADARR_LANDING/"
[[ ! "$LIDARR_LANDING" =~ /$ ]] && LIDARR_LANDING="$LIDARR_LANDING/"
[[ ! "$WHISPARR_LANDING" =~ /$ ]] && WHISPARR_LANDING="$WHISPARR_LANDING/"

# Update SERVICES array with actual landing page values
SERVICES[SONARR]="CONTENT|Sonarr|TV shows|/icons/sonarr.png|$SONARR_LANDING|#3aa0e0"
SERVICES[RADARR]="CONTENT|Radarr|Movies|/icons/radarr.png|$RADARR_LANDING|#febc2e"
SERVICES[LIDARR]="CONTENT|Lidarr|Music|/icons/lidarr.png|$LIDARR_LANDING|#2ecd6f"
SERVICES[WHISPARR]="CONTENT|Whisparr|Adult content|/icons/whisparr.png|$WHISPARR_LANDING|#ef7e30"

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

            # Handle subdomain services (Emby, Plex, Seerr)
            if [ "$href" = "SUBDOMAIN" ]; then
                if [ "$service_key" = "EMBY" ]; then
                    # Use subdomain in public mode if defined, otherwise use internal URL
                    if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$EMBY_DOMAIN" ]; then
                        href="https://$EMBY_DOMAIN/"
                    else
                        if [ -z "$EMBY_URL" ]; then
                            continue
                        fi
                        href="$EMBY_URL"
                    fi
                elif [ "$service_key" = "PLEX" ]; then
                    # Use subdomain in public mode if defined, otherwise use internal URL
                    if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$PLEX_DOMAIN" ]; then
                        href="https://$PLEX_DOMAIN/"
                    else
                        if [ -z "$PLEX_URL" ]; then
                            continue
                        fi
                        href="$PLEX_URL"
                    fi
                elif [ "$service_key" = "SEERR" ]; then
                    # Use subdomain in public mode if defined, otherwise use internal URL
                    if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$SEERR_DOMAIN" ]; then
                        href="https://$SEERR_DOMAIN/"
                    else
                        if [ -z "$SEERR_URL" ]; then
                            continue
                        fi
                        href="$SEERR_URL"
                    fi
                fi
            fi

            # Check if this service should open in a popup (qBittorrent, external links, etc)
            local popup_attr=""
            if [[ "$service_key" == "QBITTORRENT" ]] || [[ "$href" == http* ]]; then
                popup_attr=" onclick=\"window.open(this.href, 'popup_' + Date.now(), 'width=1200,height=800,resizable=yes,status=yes,location=yes,toolbar=yes,menubar=yes,scrollbars=yes'); return false;\""
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
                if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$EMBY_DOMAIN" ]; then
                    href="https://$EMBY_DOMAIN/"
                else
                    [ -z "$EMBY_URL" ] && continue
                    href="$EMBY_URL"
                fi
            elif [ "$service_key" = "PLEX" ]; then
                if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$PLEX_DOMAIN" ]; then
                    href="https://$PLEX_DOMAIN/"
                else
                    [ -z "$PLEX_URL" ] && continue
                    href="$PLEX_URL"
                fi
            elif [ "$service_key" = "SEERR" ]; then
                if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$SEERR_DOMAIN" ]; then
                    href="https://$SEERR_DOMAIN/"
                else
                    [ -z "$SEERR_URL" ] && continue
                    href="$SEERR_URL"
                fi
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

        # MEDIA services: use DOMAIN in public mode, URL in private mode
        if [ "$category" = "MEDIA" ]; then
            if [ "$ACCESS_MODE" = "public" ]; then
                # Public mode: use subdomains if configured
                case "$service_key" in
                    EMBY)
                        if [ ! -z "$EMBY_DOMAIN" ]; then
                            href="https://$EMBY_DOMAIN/"
                        else
                            [ -z "$EMBY_URL" ] && continue
                            href="$EMBY_URL"
                        fi
                        ;;
                    PLEX)
                        if [ ! -z "$PLEX_DOMAIN" ]; then
                            href="https://$PLEX_DOMAIN/"
                        else
                            [ -z "$PLEX_URL" ] && continue
                            href="$PLEX_URL"
                        fi
                        ;;
                    TAUTULLI)
                        [ -z "$TAUTULLI_URL" ] && continue
                        href="$TAUTULLI_URL"
                        ;;
                esac
            else
                # Private mode: use internal URLs
                case "$service_key" in
                    EMBY)
                        [ -z "$EMBY_URL" ] && continue
                        href="$EMBY_URL"
                        ;;
                    PLEX)
                        [ -z "$PLEX_URL" ] && continue
                        href="$PLEX_URL"
                        ;;
                    TAUTULLI)
                        [ -z "$TAUTULLI_URL" ] && continue
                        href="$TAUTULLI_URL"
                        ;;
                esac
            fi
        elif [ "$href" = "SUBDOMAIN" ]; then
            # Handle other subdomain services (shouldn't reach here for MEDIA)
            if [ "$service_key" = "EMBY" ]; then
                if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$EMBY_DOMAIN" ]; then
                    href="https://$EMBY_DOMAIN/"
                else
                    [ -z "$EMBY_URL" ] && continue
                    href="$EMBY_URL"
                fi
            elif [ "$service_key" = "PLEX" ]; then
                if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$PLEX_DOMAIN" ]; then
                    href="https://$PLEX_DOMAIN/"
                else
                    [ -z "$PLEX_URL" ] && continue
                    href="$PLEX_URL"
                fi
            elif [ "$service_key" = "SEERR" ]; then
                if [ "$ACCESS_MODE" = "public" ] && [ ! -z "$SEERR_DOMAIN" ]; then
                    href="https://$SEERR_DOMAIN/"
                else
                    [ -z "$SEERR_URL" ] && continue
                    href="$SEERR_URL"
                fi
            fi
        fi

        # Determine if popup (external link, qBittorrent, or MEDIA services)
        local popup="false"
        [[ "$href" == http* ]] && popup="true"
        [[ "$service_key" == "QBITTORRENT" ]] && popup="true"
        [ "$category" = "MEDIA" ] && popup="true"

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

# Generate style switcher HTML for classic template
generate_style_switcher_classic() {
    if [ "$SHOW_STYLE_SWITCHER" = "true" ]; then
        echo '<div class="style-switcher" style="display:flex;gap:6px;justify-content:center;align-items:center">
                <a href="/" style="text-decoration:none;color:#4a9eff">Classic</a>
                <span style="color:#5d6575">|</span>
                <a href="/modern.html" style="text-decoration:none;color:#4a9eff">Modern</a>
                <span style="color:#5d6575">|</span>
                <a href="/sleek.html" style="text-decoration:none;color:#4a9eff">Sleek</a>
                <span style="color:#5d6575">|</span>
                <a href="/minimal.html" style="text-decoration:none;color:#4a9eff">Minimal</a>
                <span style="color:#5d6575">|</span>
                <button id="theme-toggle-classic" style="background:none;border:none;cursor:pointer;font-size:14px;padding:0;color:var(--text-accent)" title="Toggle theme">☀️</button>
            </div>'
    else
        echo '<div style="display:flex;gap:6px;justify-content:center;align-items:center">
                <button id="theme-toggle-classic" style="background:none;border:none;cursor:pointer;font-size:14px;padding:0;color:var(--text-accent)" title="Toggle theme">☀️</button>
            </div>'
    fi
}

# Generate style switcher HTML for modern template
generate_style_switcher_modern() {
    if [ "$SHOW_STYLE_SWITCHER" = "true" ]; then
        echo '<div style="font-size:11px;text-align:center;padding:8px 0;border-top:1px solid var(--border-color);display:flex;gap:6px;justify-content:center;flex-wrap:wrap;align-items:center">
        <a href="/classic.html" style="color:var(--text-link);text-decoration:none;transition:color 0.2s">Classic</a>
        <span style="color:var(--text-tertiary)">|</span>
        <a href="/modern.html" style="color:var(--text-link);text-decoration:none;transition:color 0.2s">Modern</a>
        <span style="color:var(--text-tertiary)">|</span>
        <a href="/sleek.html" style="color:var(--text-link);text-decoration:none;transition:color 0.2s">Sleek</a>
        <span style="color:var(--text-tertiary)">|</span>
        <a href="/minimal.html" style="color:var(--text-link);text-decoration:none;transition:color 0.2s">Minimal</a>
        <span style="color:var(--text-tertiary)">|</span>
        <button id="theme-toggle-modern" style="background:none;border:none;cursor:pointer;font-size:11px;padding:0;color:var(--text-link);transition:color 0.2s" title="Toggle theme">☀️</button>
      </div>'
    else
        echo '<div style="font-size:11px;text-align:center;padding:8px 0;border-top:1px solid var(--border-color);display:flex;gap:6px;justify-content:center;flex-wrap:wrap;align-items:center">
        <button id="theme-toggle-modern" style="background:none;border:none;cursor:pointer;font-size:11px;padding:0;color:var(--text-link);transition:color 0.2s" title="Toggle theme">☀️</button>
      </div>'
    fi
}

# Generate style switcher HTML for sleek template
generate_style_switcher_sleek() {
    if [ "$SHOW_STYLE_SWITCHER" = "true" ]; then
        echo '<div style="font-size:9px;text-align:center;padding:8px 0;border-top:1px solid rgba(255,255,255,.1);display:flex;gap:4px;justify-content:center;flex-wrap:wrap;width:100%;align-items:center">
      <a href="/classic.html" style="color:#4a9eff;text-decoration:none;transition:color 0.2s">Classic</a>
      <span style="color:#5d6575">|</span>
      <a href="/modern.html" style="color:#4a9eff;text-decoration:none;transition:color 0.2s">Modern</a>
      <span style="color:#5d6575">|</span>
      <a href="/sleek.html" style="color:#4a9eff;text-decoration:none;transition:color 0.2s">Sleek</a>
      <span style="color:#5d6575">|</span>
      <a href="/minimal.html" style="color:#4a9eff;text-decoration:none;transition:color 0.2s">Minimal</a>
      <span style="color:#5d6575">|</span>
      <button id="theme-toggle-sleek" style="background:none;border:none;cursor:pointer;font-size:12px;padding:0;color:#4a9eff;transition:color 0.2s" title="Toggle theme">☀️</button>
    </div>'
    else
        echo '<div style="font-size:9px;text-align:center;padding:8px 0;border-top:1px solid rgba(255,255,255,.1);display:flex;gap:4px;justify-content:center;flex-wrap:wrap;width:100%;align-items:center">
      <button id="theme-toggle-sleek" style="background:none;border:none;cursor:pointer;font-size:12px;padding:0;color:#4a9eff;transition:color 0.2s" title="Toggle theme">☀️</button>
    </div>'
    fi
}

# Generate style switcher HTML for minimal template
generate_style_switcher_minimal() {
    if [ "$SHOW_STYLE_SWITCHER" = "true" ]; then
        echo '<div style="font-size:9px;text-align:center;padding:8px 0;border-top:1px solid rgba(255,255,255,.1);display:flex;gap:4px;justify-content:center;flex-wrap:wrap;width:100%;align-items:center">
      <a href="/classic.html" style="color:#4a9eff;text-decoration:none;transition:color 0.2s">Classic</a>
      <span style="color:#5d6575">|</span>
      <a href="/modern.html" style="color:#4a9eff;text-decoration:none;transition:color 0.2s">Modern</a>
      <span style="color:#5d6575">|</span>
      <a href="/sleek.html" style="color:#4a9eff;text-decoration:none;transition:color 0.2s">Sleek</a>
      <span style="color:#5d6575">|</span>
      <a href="/minimal.html" style="color:#4a9eff;text-decoration:none;transition:color 0.2s">Minimal</a>
      <span style="color:#5d6575">|</span>
      <button id="theme-toggle-minimal" style="background:none;border:none;cursor:pointer;font-size:12px;padding:0;color:#4a9eff;transition:color 0.2s" title="Toggle theme">☀️</button>
    </div>'
    else
        echo '<div style="font-size:9px;text-align:center;padding:8px 0;border-top:1px solid rgba(255,255,255,.1);display:flex;gap:4px;justify-content:center;flex-wrap:wrap;width:100%;align-items:center">
      <button id="theme-toggle-minimal" style="background:none;border:none;cursor:pointer;font-size:12px;padding:0;color:#4a9eff;transition:color 0.2s" title="Toggle theme">☀️</button>
    </div>'
    fi
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
        local style_switcher=$(generate_style_switcher_classic)

        local html_content=$(cat "$TEMPLATE_FILE")
        html_content="${html_content//@@MENU_ITEMS@@/$menu_items}"
        html_content="${html_content//@@ENABLED_SERVICES_LIST@@/$services_list}"
        html_content="${html_content//@@STYLE_SWITCHER@@/$style_switcher}"
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
        local style_switcher=$(generate_style_switcher_modern)
        local html_content=$(cat "$TEMPLATE_FILE")
        html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
        html_content="${html_content//@@STYLE_SWITCHER@@/$style_switcher}"
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

        # Determine which style switcher to use
        local style_switcher
        if [ "$STYLE" = "sleek" ]; then
            style_switcher=$(generate_style_switcher_sleek)
        else
            style_switcher=$(generate_style_switcher_minimal)
        fi

        local html_content=$(cat "$TEMPLATE_FILE")
        html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
        html_content="${html_content//@@STYLE_SWITCHER@@/$style_switcher}"
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
        local sites_items=$(generate_sites_html)
        local style_switcher=$(generate_style_switcher_classic)
        local html_content=$(cat "$CLASSIC_TEMPLATE")
        html_content="${html_content//@@MENU_ITEMS@@/$menu_items}"
        html_content="${html_content//@@ENABLED_SERVICES_LIST@@/$services_list}"
        html_content="${html_content//@@SITES_ITEMS@@/$sites_items}"
        html_content="${html_content//@@STYLE_SWITCHER@@/$style_switcher}"
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
        local sites_items=$(generate_sites_html)
        local style_switcher=$(generate_style_switcher_modern)
        local html_content=$(cat "$MODERN_TEMPLATE")
        html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
        html_content="${html_content//@@SITES_ITEMS@@/$sites_items}"
        html_content="${html_content//@@STYLE_SWITCHER@@/$style_switcher}"
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
        local sites_items=$(generate_sites_html)
        local style_switcher=$(generate_style_switcher_sleek)
        local html_content=$(cat "$SLEEK_TEMPLATE")
        html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
        html_content="${html_content//@@SITES_ITEMS@@/$sites_items}"
        html_content="${html_content//@@STYLE_SWITCHER@@/$style_switcher}"
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
        local sites_items=$(generate_sites_html)
        local style_switcher=$(generate_style_switcher_minimal)
        local html_content=$(cat "$MINIMAL_TEMPLATE")
        html_content="${html_content//@@SERVICES_ARRAY@@/$services_array}"
        html_content="${html_content//@@SITES_ITEMS@@/$sites_items}"
        html_content="${html_content//@@STYLE_SWITCHER@@/$style_switcher}"
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

    # Generate Mobile (always)
    if [ -f "$MOBILE_TEMPLATE" ]; then
        local menu_items=$(generate_menu_items)
        local sites_items=$(generate_sites_html)
        local html_content=$(cat "$MOBILE_TEMPLATE")
        html_content="${html_content//@@MENU_ITEMS@@/$menu_items}"
        html_content="${html_content//@@SITES_ITEMS@@/$sites_items}"
        html_content="${html_content//@@DASHBOARD_NAME@@/${DASHBOARD_NAME:-Media Server}}"
        html_content="${html_content//@@DASHBOARD_ICON@@/${DASHBOARD_ICON:-/icons/homelabportal.png}}"
        echo "$html_content" > "/var/www/html/mobile.html"
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

            # MEDIA services: use DOMAIN in public mode, URL in private mode
            if [ "$category" = "MEDIA" ]; then
                if [ "$ACCESS_MODE" = "public" ]; then
                    # Public mode: use OAuth-protected subdomains
                    case "$service_key" in
                        EMBY)
                            [ -z "$EMBY_DOMAIN" ] && continue
                            href="https://$EMBY_DOMAIN/"
                            ;;
                        PLEX)
                            [ -z "$PLEX_DOMAIN" ] && continue
                            href="https://$PLEX_DOMAIN/"
                            ;;
                        TAUTULLI)
                            [ -z "$TAUTULLI_URL" ] && continue
                            href="$TAUTULLI_URL"
                            ;;
                    esac
                else
                    # Private mode: use internal URLs
                    case "$service_key" in
                        EMBY)
                            [ -z "$EMBY_URL" ] && continue
                            href="$EMBY_URL"
                            ;;
                        PLEX)
                            [ -z "$PLEX_URL" ] && continue
                            href="$PLEX_URL"
                            ;;
                        TAUTULLI)
                            [ -z "$TAUTULLI_URL" ] && continue
                            href="$TAUTULLI_URL"
                            ;;
                    esac
                fi
            elif [ "$href" = "SUBDOMAIN" ]; then
                # Handle other subdomain services
                if [ "$service_key" = "EMBY" ]; then
                    if [ ! -z "$EMBY_DOMAIN" ]; then
                        href="https://$EMBY_DOMAIN/"
                    else
                        [ -z "$EMBY_URL" ] && continue
                        href="$EMBY_URL"
                    fi
                elif [ "$service_key" = "PLEX" ]; then
                    if [ ! -z "$PLEX_DOMAIN" ]; then
                        href="https://$PLEX_DOMAIN/"
                    else
                        [ -z "$PLEX_URL" ] && continue
                        href="$PLEX_URL"
                    fi
                elif [ "$service_key" = "SEERR" ]; then
                    if [ ! -z "$SEERR_DOMAIN" ]; then
                        href="https://$SEERR_DOMAIN/"
                    else
                        [ -z "$SEERR_URL" ] && continue
                        href="$SEERR_URL"
                    fi
                fi
            fi

            # Determine if popup (external link, qBittorrent, MEDIA services, or Seerr)
            local popup="false"
            [[ "$href" == http* ]] && popup="true"
            [[ "$service_key" == "QBITTORRENT" ]] && popup="true"
            [ "$category" = "MEDIA" ] && popup="true"
            [ "$service_key" = "SEERR" ] && popup="true"

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

    # For public mode with basic auth only, generate single index.html to avoid repeated auth prompts
    # For private mode or OAuth (google, entra), generate all styles since they don't have re-auth issues
    if [ "$ACCESS_MODE" = "public" ] && [ "$AUTHTYPE" = "basic" ]; then
        # Public + basic auth: only generate index.html to prevent repeated auth prompts
        SHOW_STYLE_SWITCHER="false"
        generate_style_dashboard
        echo ""
        echo "✓ Dashboard generated (basic auth: single menu) with $count enabled service(s)"
        echo ""
        echo "  /index.html"
    else
        # Private mode or OAuth modes: generate all style variants for menu switching
        SHOW_STYLE_SWITCHER="true"
        generate_style_dashboard
        generate_all_styles
        echo ""
        echo "✓ Dashboards generated with $count enabled service(s)"
        echo ""
        echo "Available dashboards:"
        echo "  /index.html (primary: $STYLE)"
        echo "  /classic.html"
        echo "  /modern.html"
        echo "  /sleek.html"
        echo "  /minimal.html"
    fi
}

# Run generation
generate_html




