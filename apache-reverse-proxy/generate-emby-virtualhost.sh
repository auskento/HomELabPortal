#!/bin/bash

# Generate Emby Subdomain VirtualHost Configuration
# Called with: domain [enable_oauth]

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
    
    # Hardening & KeepAlive settings to prevent dropped playback sessions
    KeepAlive On
    Timeout 6000
    
    # Prevent Apache from acting as a forward proxy
    ProxyRequests Off
    ProxyPreserveHost On
    
    # Forward crucial headers to Emby (Client IP, Host info, and connection scheme)
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
    
    # Pass Office 365 user information headers to Emby
    RequestHeader set X-Remote-User %{OIDC_email}e
    RequestHeader set X-Remote-Name %{OIDC_name}e
    RequestHeader set X-Remote-ID %{OIDC_sub}e
    RequestHeader set X-Auth-Method "Office365"
EOF
fi

cat << 'EOF'
    
    # Route /embywebsocket to handle live TV and real-time app sync
    ProxyPassMatch "^/embywebsocket/(.*)" "ws://@@EMBY_HOST@@:@@EMBY_PORT@@/embywebsocket/$1"
    ProxyPassReverse "^/embywebsocket/(.*)" "ws://@@EMBY_HOST@@:@@EMBY_PORT@@/embywebsocket/$1"
    
    # Route all other traffic to root
    ProxyPass "/" "http://@@EMBY_HOST@@:@@EMBY_PORT@@/"
    ProxyPassReverse "/" "http://@@EMBY_HOST@@:@@EMBY_PORT@@/"
</VirtualHost>
EOF
