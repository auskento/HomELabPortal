#!/bin/bash

# Generate Plex Subdomain VirtualHost Configuration
# Called with: domain [enable_oauth]

PLEX_DOMAIN="${1:-plex.example.com}"
ENABLE_OAUTH="${2:-false}"

cat << 'EOF'
# Plex Subdomain VirtualHost
<VirtualHost *:443>
    ServerName @@PLEX_DOMAIN@@
    
    # SSL/TLS Configuration
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/@@PLEX_DOMAIN@@/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/@@PLEX_DOMAIN@@/privkey.pem
    SSLProtocol -all +TLSv1.2 +TLSv1.3
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder on
    
    # Proxy settings
    ProxyRequests Off
    ProxyPreserveHost On
    
    # Request limit settings for Plex compatibility
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
    
    # Office 365 OAuth Protection (when enabled)
    <Location /oauth2>
        SetHandler oauth2-handler
    </Location>
    
    <Location /oauth2callback>
        SetHandler oauth2-handler
    </Location>
EOF

# Add OAuth authentication if enabled
if [ "$ENABLE_OAUTH" = "true" ]; then
    cat << 'EOF'
    
    # OAuth2 Authentication Protection
    <Location />
        AuthType openid-connect
        Require valid-user
        LogLevel debug
    </Location>
    
    # Pass Office 365 user information headers to Plex
    RequestHeader set X-Remote-User %{OIDC_email}e
    RequestHeader set X-Remote-Name %{OIDC_name}e
    RequestHeader set X-Remote-ID %{OIDC_sub}e
    RequestHeader set X-Auth-Method "Office365"
EOF
fi

cat << 'EOF'
    
    # Route all traffic to Plex backend
    ProxyPass "/" "http://@@PLEX_HOST@@:@@PLEX_PORT@@/"
    ProxyPassReverse "/" "http://@@PLEX_HOST@@:@@PLEX_PORT@@/"
</VirtualHost>
EOF
