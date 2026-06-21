#!/bin/bash

# Generate Emby Subdomain VirtualHost Configuration
# Called with domain as first argument

EMBY_DOMAIN="${1:-emby.example.com}"

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
    
    # Route /embywebsocket to handle live TV and real-time app sync
    ProxyPassMatch "^/embywebsocket/(.*)" "ws://@@EMBY_HOST@@:@@EMBY_PORT@@/embywebsocket/$1"
    ProxyPassReverse "^/embywebsocket/(.*)" "ws://@@EMBY_HOST@@:@@EMBY_PORT@@/embywebsocket/$1"
    
    # Route all other traffic to root
    ProxyPass "/" "http://@@EMBY_HOST@@:@@EMBY_PORT@@/"
    ProxyPassReverse "/" "http://@@EMBY_HOST@@:@@EMBY_PORT@@/"
</VirtualHost>
EOF
