#!/bin/bash

# Generate Emby Subdomain VirtualHost Configuration
# Called with: domain [enable_oauth]
# Requires OIDC env vars: OAUTH2_CLIENT_ID, OAUTH2_CLIENT_SECRET, OAUTH2_CRYPTO_PASSPHRASE

EMBY_DOMAIN="${1:-emby.example.com}"
ENABLE_OAUTH="${2:-false}"

cat << 'EOF'
# Emby Subdomain VirtualHost
<VirtualHost *:443>
    ServerName @@EMBY_DOMAIN@@
    
    # SSL/TLS Configuration
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/@@EMBY_DOMAIN@@/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/@@EMBY_DOMAIN@@/privkey.pem
    SSLProtocol -all +TLSv1.2 +TLSv1.3
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder on
    
    # Proxy settings
    ProxyRequests Off
    ProxyPreserveHost On
    
    # Request limit settings for Emby compatibility
    LimitRequestFieldSize 32768
    LimitRequestFields 100
    LimitRequestLine 32768
    
    # KeepAlive and timeout settings
    KeepAlive On
    Timeout 300
    
    # Forward crucial headers
    RequestHeader set X-Forwarded-Proto "https" env=HTTPS
    RequestHeader set X-Forwarded-Port "443"
    RequestHeader set X-Real-IP %{REMOTE_ADDR}s
    RequestHeader set X-Forwarded-For %{HTTP:X-Forwarded-For}e
    RequestHeader set X-Remote-User %{REMOTE_USER}s
EOF

# OIDC configuration NOT applied to subdomains
# Subdomains don't require separate OIDC auth - users authenticate at main domain
# Attempting to add OIDC here causes hostname mismatch errors with mod_auth_openidc
# This is intentionally disabled for Emby subdomains

cat << 'EOF'
    
    # OAuth2 Handlers
    <Location /oauth2>
        SetHandler oauth2-handler
    </Location>
    
    <Location /oauth2/callback>
        SetHandler oauth2-handler
    </Location>
EOF

# Subdomains don't require separate OIDC auth
# Users authenticate at main domain; subdomains are accessible without re-auth
# Attempting to add OIDC here causes hostname mismatch errors with mod_auth_openidc

cat << 'EOF'
    
    # Route all traffic to Emby backend
    ProxyPass "/" "http://@@EMBY_HOST@@:@@EMBY_PORT@@/"
    ProxyPassReverse "/" "http://@@EMBY_HOST@@:@@EMBY_PORT@@/"

    # Debug Logging with date-based folder organization
    LogLevel warn
    ErrorLog /var/log/apache2/reverse-proxy-debug/emby-error.log
    CustomLog "|/usr/local/bin/apache-log-rotator.sh emby" combined env=!nolog
</VirtualHost>
EOF
