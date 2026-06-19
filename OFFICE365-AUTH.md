# Office 365 / Azure AD Authentication Guide

## Overview

This guide shows how to protect all your media server services with Office 365 / Azure AD authentication. Users will need to log in with their Microsoft account before accessing any services.

## Benefits

✅ **Single Sign-On (SSO)** - Users log in once with their Microsoft account  
✅ **Centralized Control** - Manage who can access via Azure AD  
✅ **No Password Management** - Uses Office 365 credentials  
✅ **Audit Trail** - Azure AD logs all access  
✅ **Multi-factor Authentication** - Can require MFA for extra security  
✅ **Domain Restriction** - Only allow users from specific email domains  

## Prerequisites

- Microsoft/Office 365 account or Azure AD tenant
- Access to Azure AD/Microsoft Entra ID admin portal
- A registered domain (yourdomain.com)
- Docker setup already running

## Step 1: Register an Application in Azure AD

### 1.1 Go to Azure AD Portal

1. Visit: https://portal.azure.com
2. Sign in with your Microsoft/Office 365 account
3. Navigate to **Azure Active Directory** → **App registrations**
4. Click **+ New registration**

### 1.2 Create New Application

Fill in the form:

- **Name**: `Media Server Reverse Proxy` (or any name you prefer)
- **Supported account types**: Choose based on your needs:
  - `Accounts in this organizational directory only` - Only your organization
  - `Accounts in any organizational directory` - Any Azure AD organization
  - `Accounts in any organizational directory and personal Microsoft accounts` - Anyone
- **Redirect URI**: 
  - Platform: `Web`
  - URI: `https://yourdomain.com/oauth2callback`

Click **Register**

### 1.3 Get Application Details

After registration, you'll see the application page:

**Copy these values:**
1. **Application (client) ID** - You'll need this for `OAUTH2_CLIENT_ID`
2. **Directory (tenant) ID** - Optional, but useful for specific tenant access

### 1.4 Create Client Secret

1. Go to **Certificates & secrets**
2. Click **+ New client secret**
3. Fill in:
   - **Description**: `Docker Reverse Proxy Secret`
   - **Expires**: Choose duration (24 months recommended)
4. Click **Add**
5. **Copy the VALUE** (not the ID) - You'll need this for `OAUTH2_CLIENT_SECRET`

⚠️ **Important**: Save this secret securely - you won't see it again!

### 1.5 Configure API Permissions

1. Go to **API permissions**
2. Click **+ Add a permission**
3. Select **Microsoft Graph**
4. Choose **Delegated permissions**
5. Search for and select:
   - `User.Read` - Allow sign in and read profile
   - `email` - Access email address
   - `profile` - Access basic profile info
6. Click **Add permissions**
7. Click **Grant admin consent** to approve permissions

## Step 2: Configure Docker Environment Variables

Edit `docker-compose.yml` and set:

```yaml
environment:
  # Enable Office 365 authentication
  ENABLE_AUTH_OFFICE365: "true"
  
  # From Azure AD app registration
  OAUTH2_CLIENT_ID: "YOUR_APPLICATION_CLIENT_ID"
  OAUTH2_CLIENT_SECRET: "YOUR_CLIENT_SECRET"
  
  # Where users return after login
  OAUTH2_REDIRECT_URI: "https://yourdomain.com/oauth2callback"
  
  # Email domains allowed to access (comma-separated)
  OAUTH2_ALLOWED_DOMAINS: "yourdomain.com,company.com"
  
  # Random string for session encryption (generate new one)
  OAUTH2_CRYPTO_PASSPHRASE: "your-random-secure-passphrase-here"
```

### Generate Secure Passphrase

Use this command to generate a random passphrase:

```bash
openssl rand -base64 24
```

Copy the output and set it as `OAUTH2_CRYPTO_PASSPHRASE`.

**Example:**
```yaml
OAUTH2_CRYPTO_PASSPHRASE: "aBc1dE2fG3hI4jK5lM6nO7pQ8rS9tU=="
```

## Step 3: Update Redirect URI in Azure AD

The redirect URI must match exactly in both places:

1. **In Azure AD**: Applications → Your app → Authentication
   - Set Redirect URI to: `https://yourdomain.com/oauth2callback`
   - Mark as Public client: **No**

2. **In docker-compose.yml**:
   ```yaml
   OAUTH2_REDIRECT_URI: "https://yourdomain.com/oauth2callback"
   ```

⚠️ These must match exactly (including protocol https://)!

## Step 4: Deploy

```bash
# Build and start
docker-compose build
docker-compose up -d

# Watch logs
docker-compose logs -f apache-reverse-proxy
```

Check for errors:
```
Office 365 Authentication configured
  Client ID: YOUR_CLIENT_ID...
  Redirect URI: https://yourdomain.com/oauth2callback
```

## Step 5: Test Authentication

1. Open browser to: `https://yourdomain.com`
2. You should be redirected to Microsoft login page
3. Enter your Office 365 credentials
4. You'll be asked to consent to permissions
5. After login, you'll be redirected back to your dashboard
6. You should now see your media services

## Troubleshooting

### Login Redirects But Shows Error

**Problem**: OAuth2 callback returns an error

**Solutions**:
1. Verify `OAUTH2_REDIRECT_URI` in docker-compose matches Azure AD exactly
2. Check `OAUTH2_CLIENT_ID` and `OAUTH2_CLIENT_SECRET` are correct
3. Verify API permissions are granted in Azure AD
4. Check logs: `docker-compose logs apache-reverse-proxy | grep -i oauth`

### "Invalid client ID" Error

- Copy the correct Application (client) ID from Azure AD
- Make sure you're copying the ID, not the description

### "Secret expired" or "Invalid secret"

- Generate a new client secret in Azure AD
- Update `OAUTH2_CLIENT_SECRET` in docker-compose
- Rebuild and restart

### "Redirect URI mismatch"

- The redirect URI must match EXACTLY (including https://)
- Common mistake: `http://` vs `https://`
- Check for trailing slashes or differences in domain

### Users Can't Login

**Check permissions in Azure AD:**
1. Go to App registrations
2. Select your app
3. Go to API permissions
4. Verify `User.Read` is granted
5. Check "Grant admin consent" shows a green checkmark

### "Unauthorized" After Login

**Problem**: User is from wrong email domain

**Solution**: Update `OAUTH2_ALLOWED_DOMAINS` to include their domain

```yaml
OAUTH2_ALLOWED_DOMAINS: "yourdomain.com,otherdomain.com,user@example.com"
```

### Session Expires Too Quickly

Adjust in `apache-conf/oauth2-office365.conf`:

```apache
OIDCSessionInactivityTimeout 3600  # Change to 7200 for 2 hours
OIDCSessionMaxDuration 86400       # Change to 604800 for 1 week
```

Then rebuild:
```bash
docker-compose build
docker-compose up -d
```

## Advanced Configuration

### Restrict to Specific Users

Instead of allowing all users from a domain, restrict to specific users:

```yaml
OAUTH2_ALLOWED_DOMAINS: "user1@yourdomain.com,user2@yourdomain.com,admin@yourdomain.com"
```

### Require Multi-Factor Authentication

In Azure AD:
1. Go to **Conditional Access**
2. Create new policy
3. Select your application
4. Require MFA for access

### Different Access Levels

You can set up Azure AD groups and assign different permissions:

In `auth-office365-protect.conf`, you can add:
```apache
# Only allow users in "Media Server Admins" group
Require ldap-group cn=Media Server Admins,ou=groups,dc=example,dc=com
```

### Logout Functionality

Users can logout by accessing:
```
https://yourdomain.com/oauth2/logout
```

They'll be logged out and their session cleared.

## User Experience

### First Login
1. User visits `https://yourdomain.com`
2. Redirected to Microsoft login page
3. Enters Office 365 email and password
4. Grants permission to app
5. Redirected back to dashboard
6. Sees all enabled services

### Subsequent Logins
- User remains logged in
- Session lasts based on configured duration
- Refresh/reopen browser - stays logged in
- SSO with other Microsoft apps

### Headers Passed to Services

When authenticated, these headers are passed to backend services:

```
X-Remote-User: user@domain.com           # Email
X-Remote-Name: John Doe                  # Full name
X-Remote-ID: azure-ad-user-id            # Unique ID
X-Auth-Method: Office365                 # Auth method
```

Some services (Sonarr, Radarr, etc.) can read these headers for user-specific features.

## Security Best Practices

1. **Use HTTPS only** - Always use https:// for redirect URI
2. **Protect your secret** - Never commit OAUTH2_CLIENT_SECRET to git
3. **Rotate secrets** - Generate new secrets periodically in Azure AD
4. **Monitor access** - Check Azure AD logs for suspicious activity
5. **Use strong passphrase** - Make OAUTH2_CRYPTO_PASSPHRASE long and random
6. **Limit domains** - Restrict `OAUTH2_ALLOWED_DOMAINS` to your organization
7. **Enable MFA** - Require multi-factor authentication in Azure AD
8. **Review permissions** - Only grant necessary API permissions

## Disable Authentication

To turn off Office 365 authentication:

```yaml
ENABLE_AUTH_OFFICE365: "false"
```

Then restart:
```bash
docker-compose restart apache-reverse-proxy
```

Services will be accessible without login.

## Complete Configuration Example

```yaml
apache-reverse-proxy:
  environment:
    DOMAIN: media.example.com
    EMAIL: admin@example.com
    
    # Services
    ENABLE_SONARR: "true"
    ENABLE_RADARR: "true"
    ENABLE_JELLYFIN: "true"
    
    # Office 365 Auth ← NEW
    ENABLE_AUTH_OFFICE365: "true"
    OAUTH2_CLIENT_ID: "1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d"
    OAUTH2_CLIENT_SECRET: "YOUR_SECRET_HERE~abc1234567-_=DEF"
    OAUTH2_REDIRECT_URI: "https://media.example.com/oauth2callback"
    OAUTH2_ALLOWED_DOMAINS: "example.com"
    OAUTH2_CRYPTO_PASSPHRASE: "RandomSecurePassphrase123456="
```

## Additional Resources

- [Azure AD Documentation](https://learn.microsoft.com/en-us/azure/active-directory/)
- [App Registration Guide](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
- [OpenID Connect Protocol](https://openid.net/connect/)
- [OAuth 2.0 Standards](https://oauth.net/2/)

## Support

If you encounter issues:

1. Check logs: `docker-compose logs -f apache-reverse-proxy | grep -i oauth`
2. Verify Azure AD configuration
3. Ensure domain/DNS is correct
4. Check that HTTPS is working
5. Verify redirect URI matches exactly

---

**You now have enterprise-grade authentication for your media server!** 🔐
