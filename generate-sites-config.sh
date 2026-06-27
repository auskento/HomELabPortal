#!/bin/bash

# Generate and manage sites.json for torrent/usenet links
# This script initializes sites.json on first run and manages favicon fetching

SITES_DIR="/var/log/apache2/sites"
SITES_JSON="$SITES_DIR/sites.json"

# Create directory if it doesn't exist
mkdir -p "$SITES_DIR"
chmod 755 "$SITES_DIR"

# Initialize sites.json with preset list if it doesn't exist
if [ ! -f "$SITES_JSON" ]; then
    echo "Initializing sites.json with preset list..."

    cat > "$SITES_JSON" << 'EOF'
{
  "sites": [
    {
      "code": "TPB",
      "name": "The Pirate Bay",
      "url": "https://thepiratebay.org",
      "category": "torrent"
    },
    {
      "code": "RAR",
      "name": "RARBG",
      "url": "https://rarbg.to",
      "category": "torrent"
    },
    {
      "code": "1337",
      "name": "1337x",
      "url": "https://1337x.to",
      "category": "torrent"
    },
    {
      "code": "YTS",
      "name": "YTS",
      "url": "https://yts.torrentbay.st",
      "category": "torrent"
    },
    {
      "code": "SKY",
      "name": "Sky Torrents",
      "url": "https://www.skytorrents.in",
      "category": "torrent"
    },
    {
      "code": "LAT",
      "name": "LimeTorrents",
      "url": "https://www.limetorrents.lol",
      "category": "torrent"
    },
    {
      "code": "DOG",
      "name": "DOGnzb",
      "url": "https://dognzb.cr",
      "category": "usenet"
    },
    {
      "code": "DRS",
      "name": "DrunkenSlug",
      "url": "https://www.drunkenslug.com",
      "category": "usenet"
    },
    {
      "code": "NLF",
      "name": "nzb.life",
      "url": "https://nzb.life",
      "category": "usenet"
    },
    {
      "code": "NFW",
      "name": "NZBFinder.ws",
      "url": "https://nzbfinder.ws",
      "category": "usenet"
    },
    {
      "code": "NGK",
      "name": "NZBgeek",
      "url": "https://nzbgeek.info",
      "category": "usenet"
    },
    {
      "code": "PLA",
      "name": "nzbplanet.net",
      "url": "https://nzbplanet.net",
      "category": "usenet"
    },
    {
      "code": "SIM",
      "name": "SimplyNZBs",
      "url": "https://www.simplynzbs.com",
      "category": "usenet"
    },
    {
      "code": "TAB",
      "name": "Tabula Rasa",
      "url": "https://www.tabulanzbz.com",
      "category": "usenet"
    },
    {
      "code": "UCC",
      "name": "Usenet Crawler",
      "url": "https://www.usenetcrawler.com",
      "category": "usenet"
    }
  ]
}
EOF
    chmod 644 "$SITES_JSON"
    echo "✓ sites.json created"
else
    echo "✓ sites.json already exists"
fi

# Fetch favicons for enabled sites
if [ ! -z "$SITES_ENABLED" ]; then
    echo "Fetching favicons for enabled sites..."

    # Parse SITES_ENABLED and fetch favicon for each
    IFS=',' read -ra CODES <<< "$SITES_ENABLED"
    for code in "${CODES[@]}"; do
        code=$(echo "$code" | xargs)  # Trim whitespace

        # Skip if favicon already exists
        if [ -f "$SITES_DIR/${code,,}.favicon.ico" ]; then
            continue
        fi

        # Extract URL from sites.json using grep/sed
        url=$(grep -A 3 "\"code\": \"$code\"" "$SITES_JSON" | grep "\"url\"" | sed 's/.*"url": "\(.*\)".*/\1/')

        if [ ! -z "$url" ]; then
            # Extract domain from URL
            domain=$(echo "$url" | sed 's|https://||' | sed 's|http://||' | sed 's|/.*||')

            # Try to fetch favicon
            favicon_url="https://www.google.com/s2/favicons?sz=64&domain=$domain"

            if wget -q -O "$SITES_DIR/${code,,}.favicon.ico.tmp" "$favicon_url" 2>/dev/null; then
                # Validate that downloaded file is a valid image
                if file "$SITES_DIR/${code,,}.favicon.ico.tmp" | grep -q "image"; then
                    # Resize favicon to consistent 64x64 square using ImageMagick
                    if command -v convert &> /dev/null; then
                        if convert "$SITES_DIR/${code,,}.favicon.ico.tmp" -resize 64x64 -background transparent -gravity center -extent 64x64 "$SITES_DIR/${code,,}.favicon.ico" 2>/dev/null; then
                            rm -f "$SITES_DIR/${code,,}.favicon.ico.tmp"
                            echo "  ✓ Fetched and resized favicon for $code"
                        else
                            # Resize failed, don't save
                            rm -f "$SITES_DIR/${code,,}.favicon.ico.tmp"
                            echo "  ⚠ Could not resize favicon for $code"
                        fi
                    else
                        # No ImageMagick, don't save without resizing
                        rm -f "$SITES_DIR/${code,,}.favicon.ico.tmp"
                        echo "  ⚠ ImageMagick not available, skipping favicon for $code"
                    fi
                else
                    # Not a valid image file, don't save
                    rm -f "$SITES_DIR/${code,,}.favicon.ico.tmp"
                    echo "  ⚠ Invalid image file for $code"
                fi
            else
                echo "  ⚠ Could not fetch favicon for $code (manual placement allowed)"
            fi
        fi
    done
fi

echo "✓ Sites configuration ready"
