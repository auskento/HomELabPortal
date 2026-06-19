#!/bin/bash

# Download and Resize App Icons from URLs
# This script downloads icon images from provided URLs and resizes them to 100x100

ICONS_DIR="/var/www/html/icons"
TARGET_SIZE="100x100"

# Create icons directory if it doesn't exist
mkdir -p "$ICONS_DIR"

echo "=== Downloading and Processing App Icons ==="
echo ""

# Define icon URLs for each service
# Format: ICON_URL_SERVICENAME=https://url.to/icon.png
declare -A ICON_URLS=(
    [SONARR]="${ICON_URL_SONARR}"
    [RADARR]="${ICON_URL_RADARR}"
    [WHISPARR]="${ICON_URL_WHISPARR}"
    [LIDARR]="${ICON_URL_LIDARR}"
    [READARR]="${ICON_URL_READARR}"
    [PROWLARR]="${ICON_URL_PROWLARR}"
    [OVERSEERR]="${ICON_URL_OVERSEERR}"
    [JELLYFIN]="${ICON_URL_JELLYFIN}"
    [EMBY]="${ICON_URL_EMBY}"
    [PLEX]="${ICON_URL_PLEX}"
    [TAUTULLI]="${ICON_URL_TAUTULLI}"
    [TRANSMISSION]="${ICON_URL_TRANSMISSION}"
    [QBITTORRENT]="${ICON_URL_QBITTORRENT}"
    [SABNZBD]="${ICON_URL_SABNZBD}"
    [DELUGE]="${ICON_URL_DELUGE}"
)

# Service name to lowercase path converter
service_to_path() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Download and resize an icon
download_and_resize_icon() {
    local service_key=$1
    local icon_url=$2
    local service_name=$(echo "$service_key" | tr '[:lower:]' '[:upper:]')
    
    # Skip if URL is empty
    if [ -z "$icon_url" ]; then
        return 0
    fi
    
    local service_path=$(service_to_path "$service_key")
    local temp_file="/tmp/${service_path}_icon"
    local output_file="${ICONS_DIR}/${service_path}.png"
    
    echo "Processing $service_name..."
    
    # Download the icon
    if ! curl -s -L -o "$temp_file" "$icon_url" 2>/dev/null; then
        echo "  ❌ Failed to download from: $icon_url"
        return 1
    fi
    
    # Check if file was downloaded
    if [ ! -f "$temp_file" ] || [ ! -s "$temp_file" ]; then
        echo "  ❌ Downloaded file is empty"
        rm -f "$temp_file"
        return 1
    fi
    
    # Get the actual image dimensions to check validity
    local file_type=$(file "$temp_file" | grep -o "image/[^ ]*" | cut -d'/' -f2 || echo "unknown")
    
    if [ "$file_type" = "unknown" ]; then
        echo "  ❌ Not a valid image file"
        rm -f "$temp_file"
        return 1
    fi
    
    # Resize to 100x100 with padding to maintain aspect ratio
    if ! convert "$temp_file" \
        -resize "$TARGET_SIZE>" \
        -gravity center \
        -background none \
        -extent "$TARGET_SIZE" \
        "$output_file" 2>/dev/null; then
        echo "  ❌ Failed to resize image"
        rm -f "$temp_file"
        return 1
    fi
    
    # Set proper permissions
    chmod 644 "$output_file"
    
    # Get file size for info
    local file_size=$(du -h "$output_file" | cut -f1)
    
    echo "  ✓ Downloaded and resized to ${TARGET_SIZE} ($file_size)"
    
    # Clean up temp file
    rm -f "$temp_file"
    
    return 0
}

# Process all services
icon_count=0
success_count=0

for service_key in "${!ICON_URLS[@]}"; do
    icon_url="${ICON_URLS[$service_key]}"
    
    if [ -n "$icon_url" ]; then
        ((icon_count++))
        if download_and_resize_icon "$service_key" "$icon_url"; then
            ((success_count++))
        fi
    fi
done

echo ""

# Report results
if [ $icon_count -eq 0 ]; then
    echo "ℹ️  No icon URLs provided"
    echo "   Set ICON_URL_SERVICENAME environment variables to download icons"
else
    echo "✓ Icon Processing Complete"
    echo "  Downloaded: $success_count / $icon_count"
    
    if [ $success_count -eq $icon_count ]; then
        echo "  Status: All icons downloaded successfully! ✓"
    elif [ $success_count -gt 0 ]; then
        echo "  Status: Some icons downloaded (partial success)"
    else
        echo "  Status: Failed to download any icons"
    fi
fi

echo ""
echo "Icon directory contents:"
ls -lh "$ICONS_DIR"/*.png 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}' || echo "  (no icons yet)"

echo ""
