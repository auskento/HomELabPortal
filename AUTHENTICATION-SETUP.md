# Authentication Setup Guide

The Apache Reverse Proxy supports three mutually exclusive authentication methods: **Basic Auth**, **Entra ID (Microsoft)**, and **Google OAuth**. Choose one based on your security and user management needs.

## Quick Comparison

| Feature | Basic Auth | Entra ID | Google |
|---------|-----------|----------|--------|
| Setup Complexity | ⭐ Simple | ⭐⭐⭐ Complex | ⭐⭐ Medium |
| User Management | Manual credentials | Azure AD sync | Google Workspace |
| Session Management | Stateless | Stateful (sessions) | Stateful (sessions) |
| Logout Support | Browser only | Yes (session clear) | Yes (session clear) |
| User Info Display | Limited | Full (name, email, ID) | Full (name, email, ID) |
| Best For | Small teams | Enterprise with Azure | Google Workspace users |

---

## 1. Basic Authentication

Simple username/password authentication. No external services required. **Uses classic interface only** (automatically enforced).

### Environment Variables

```env
AUTHTYPE=basic
BASIC_AUTH_CREDENTIALS=user1:password1|user2:password2|admin:securepass
STYLE=classic    # Automatically forced (cannot be changed)
```

### Format

Credentials are pipe-separated pairs in format `username:password`:
- Single user: `admin:mypassword`
- Multiple users: `admin:pass1|user2:pass2|guest:pass3`

### Features
- ✅ No external dependencies
- ✅ Works offline
- ✅ Uses simple classic interface
- ❌ No session management
- ❌ No logout button
- ❌ Browser dialog only
- Uses dashboard with **direct service links** (no iframes)

### Security Considerations
- Credentials are hashed with bcrypt
- Transmitted over HTTPS only
- Store in Docker secrets or environment variables, never in code
- Change passwords regularly

---

## 2. Entra ID (Microsoft Azure AD)

Enterprise authentication using Microsoft Entra ID (formerly Azure AD). Best for organizations with Microsoft 365/Office 365.

### Prerequisites
1. Microsoft Entra tenant (Azure AD)
2. Application registered in Entra ID
3. Client ID and Client Secret obtained

### Environment Variables

```env
AUTHTYPE=entra
ENTRA_CLIENT_ID=your-client-id-here
ENTRA_CLIENT_SECRET=your-client-secret-here
ENTRA_REDIRECT_URI=https://transfers.limosani.au/oauth2callback
ENTRA_PROVIDER_METADATA_URL=https://login.microsoftonline.com/YOUR_TENANT_ID/v2.0/.well-known/openid-configuration
```

### Setup Steps

#### 1. Create Entra Application

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Active Directory → App registrations → New registration**
3. Fill in:
   - **Name**: "Apache Reverse Proxy"
   - **Supported account types**: "Accounts in this organizational directory only"
   - **Redirect URI**: `https://transfers.limosani.au/oauth2callback`
4. Click **Register**

#### 2. Get Credentials

1. In app details, copy the **Application (client) ID** → `ENTRA_CLIENT_ID`
2. Go to **Certificates & secrets → New client secret**
3. Copy the secret value → `ENTRA_CLIENT_SECRET`
4. Go to **Overview**, copy **Directory (tenant) ID**
5. Build metadata URL: `https://login.microsoftonline.com/TENANT_ID/v2.0/.well-known/openid-configuration` → `ENTRA_PROVIDER_METADATA_URL`

#### 3. Configure API Permissions (Optional)

1. **API permissions → Add a permission → Microsoft Graph → Delegated permissions**
2. Add: `User.Read`, `profile`, `email`
3. Click **Grant admin consent**

### Features
- ✅ Enterprise-grade security
- ✅ Azure AD group support
- ✅ Session management
- ✅ Logout button in dashboard
- ✅ User info display (name, email)
- ✅ Multi-tenant capable
- Uses dashboard with embedded iframes (keeps sidebar visible)

### User Restrictions

Optional: Restrict to specific domains or users. Not configured by default.

---

## 3. Google OAuth 2.0

Authentication using Google accounts. Best for teams using Google Workspace.

### Prerequisites
1. Google Cloud Project
2. OAuth 2.0 credentials created
3. Client ID and Client Secret obtained

### Environment Variables

```env
AUTHTYPE=google
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret-here
GOOGLE_REDIRECT_URI=https://transfers.limosani.au/oauth2callback
```

### Setup Steps

#### 1. Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Click **Select a Project → New Project**
3. Name: "Apache Reverse Proxy"
4. Click **Create**

#### 2. Enable OAuth 2.0 API

1. **APIs & Services → OAuth consent screen**
2. Select **External** (for any Google account)
3. Fill in app details:
   - **App name**: "Apache Reverse Proxy"
   - **User support email**: your-email@example.com
   - **Developer contact**: your-email@example.com
4. Click **Save & Continue**

#### 3. Create Credentials

1. **APIs & Services → Credentials → Create Credentials → OAuth Client ID**
2. Select **Web application**
3. Add **Authorized redirect URIs**:
   - `https://transfers.limosani.au/oauth2callback`
4. Click **Create**
5. Copy:
   - **Client ID** → `GOOGLE_CLIENT_ID`
   - **Client Secret** → `GOOGLE_CLIENT_SECRET`

#### 4. (Optional) Restrict to Google Workspace Domain

If using Google Workspace, add to OAuth screen configuration:
- **Scopes**: `openid`, `profile`, `email`
- This can be enforced in Apache config if needed

### Features
- ✅ Easy setup for Google users
- ✅ Works with any Google account
- ✅ Session management
- ✅ Logout button in dashboard
- ✅ User info display (name, email)
- ✅ Google Workspace integration
- Uses dashboard with embedded iframes (keeps sidebar visible)

---

## Switching Between Auth Methods

All methods are mutually exclusive. Set only one `AUTHTYPE`:

```env
# Option 1: Basic
AUTHTYPE=basic
BASIC_AUTH_CREDENTIALS=user:password

# Option 2: Entra
AUTHTYPE=entra
ENTRA_CLIENT_ID=...
ENTRA_CLIENT_SECRET=...
ENTRA_REDIRECT_URI=...
ENTRA_PROVIDER_METADATA_URL=...

# Option 3: Google
AUTHTYPE=google
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_REDIRECT_URI=...

# Option 4: Disabled
AUTHTYPE=none
```

When switching, the old auth method's configuration is automatically disabled.

---

## Dashboard Behavior

### Basic Auth
- Simple dashboard with **direct service links**
- Click a service → navigate directly (no re-prompting)
- No user info display
- No logout button
- Once authenticated, all services accessible

### Entra ID & Google
- Modern dashboard with **embedded iframes**
- Click a service → loads in iframe while keeping sidebar visible
- Displays authenticated user info (name, email)
- Logout button in sidebar
- Sessions managed server-side
- Secure session cookies

---

## Troubleshooting

### OAuth Not Working

**Issue**: Redirect loop or "Invalid state" error
- Check `REDIRECT_URI` matches exactly in provider configuration
- Ensure HTTPS is working properly
- Check crypto passphrase is set (auto-generated if not provided)

**Issue**: User info not displaying
- Verify scopes are set correctly (`openid profile email`)
- Check API permissions granted (for Entra)
- Look at Apache error logs: `/var/log/apache2/error.log`

### Basic Auth Issues

**Issue**: Credentials not working
- Verify format: `username:password|user2:pass2`
- Check `.htpasswd` file created: `docker exec <container> cat /etc/apache2/.htpasswd`
- Password should be bcrypt hashed

**Issue**: Re-prompting on every click
- This shouldn't happen with the direct-link dashboard
- Check auth config isn't protecting service paths

---

## Security Best Practices

### All Methods
- ✅ Use HTTPS only (never HTTP)
- ✅ Store credentials in Docker secrets or env vars, never hardcoded
- ✅ Use strong, unique credentials/secrets
- ✅ Rotate secrets regularly

### Basic Auth
- ✅ Change default credentials immediately
- ✅ Use bcrypt hashing (done automatically)
- ✅ Limit number of users

### OAuth (Entra & Google)
- ✅ Keep Client Secret safe (not in code/containers)
- ✅ Use appropriate OAuth scopes (not more than needed)
- ✅ Monitor active sessions
- ✅ Regularly audit app permissions
- ✅ Set session timeout (default 1 hour)

---

## Advanced Configuration

### Session Timeout (OAuth)

Edit relevant config file:

**Entra** (`apache-conf/oauth2-entra.conf`):
```apache
OIDCSessionInactivityTimeout 3600      # 1 hour
OIDCSessionMaxDuration 86400           # 24 hours
```

**Google** (`apache-conf/oauth2-google.conf`):
```apache
OIDCSessionInactivityTimeout 3600      # 1 hour
OIDCSessionMaxDuration 86400           # 24 hours
```

Adjust values in seconds as needed.

### Custom OAuth Scopes

Modify `OIDCScope` in OAuth config files:

```apache
OIDCScope "openid profile email custom-scope"
```

### Debug OAuth Issues

Uncomment in OAuth config to enable debug logging:

```apache
OIDCDebug On
```

Logs will appear in `/var/log/apache2/error.log` (verbose).

---

## Environment File Example

```env
# Domain & Email
DOMAIN=transfers.limosani.au
EMAIL=admin@limosani.au

# Choose ONE authentication method:

# OPTION 1: Basic Auth
AUTHTYPE=basic
BASIC_AUTH_CREDENTIALS=admin:SecurePassword123|user:AnotherPassword456

# OPTION 2: Entra ID (Microsoft)
# AUTHTYPE=entra
# ENTRA_CLIENT_ID=12345678-1234-1234-1234-123456789012
# ENTRA_CLIENT_SECRET=abc123~def456_GHI789.jkl~mno
# ENTRA_REDIRECT_URI=https://transfers.limosani.au/oauth2callback
# ENTRA_PROVIDER_METADATA_URL=https://login.microsoftonline.com/12345678-1234-1234-1234-123456789012/v2.0/.well-known/openid-configuration

# OPTION 3: Google OAuth
# AUTHTYPE=google
# GOOGLE_CLIENT_ID=123456789-abcdefghijklmnop.apps.googleusercontent.com
# GOOGLE_CLIENT_SECRET=GOCSPX-abc123def456ghi
# GOOGLE_REDIRECT_URI=https://transfers.limosani.au/oauth2callback

# Services (example)
ENABLE_RADARR=true
ENABLE_SONARR=true
ENABLE_JELLYFIN=true
```

---

## FAQ

**Q: Can I use OAuth for some services but basic auth for others?**
A: No, authentication is global. All services use the same auth method.

**Q: Do I need to configure both Entra and Google?**
A: No, set only one `AUTHTYPE`. The unused OAuth config is ignored.

**Q: What if I forget my password (Basic Auth)?**
A: Restart the container with updated credentials in environment variables.

**Q: Can I limit access to specific email domains?**
A: Not built-in currently. This can be added via Apache config modifications.

**Q: How often should I rotate secrets?**
A: For OAuth: Every 90 days. For Basic Auth: Every 6 months minimum.

---

## Next Steps

1. Choose your authentication method
2. Gather required credentials/secrets
3. Set environment variables in `.env`
4. Start/restart the container
5. Test authentication by visiting `https://transfers.limosani.au`
6. Configure dashboard preferences (if using OAuth)

---

For support or issues, check Apache error logs:
```bash
docker logs <container-id>
docker exec <container-id> tail -f /var/log/apache2/error.log
```
