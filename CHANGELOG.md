# HomELabPortal (HeLP) - Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Authelia authentication support
- LDAP / Active Directory integration
- Web-based configuration UI
- Service health checks dashboard
- Rate limiting per service
- Request logging and analytics
- Automatic service discovery

---

## [2.1.0] - 2026-06-25

### Added
- **New Service** ⭐
  - Bazarr (Subtitle management) in SEARCH category
  - Total services now: 17

- **Service Reorganization**
  - Restructured categories: CONTENT, SEARCH, USENET, TORRENTS, MEDIA
  - Added USENET category: SABnzbd, NZBGet, NZBHydra
  - Added TORRENTS category: Deluge, Transmission, qBittorrent
  - Added CONTENT category: Sonarr, Radarr, Lidarr, Whisparr
  - Added SEARCH category: Seerr, Prowlarr, Bazarr
  - Added MEDIA category: Emby, Plex, Jellyfin, Tautulli

- **NZBGet Authentication**
  - HTTP Basic Auth support for NZBGet with NZBGET_USER/NZBGET_PASS
  - Automatic Base64 encoding of credentials

- **Dashboard Improvements**
  - Custom service grouping via DASHBOARD_ORDER
  - Multiple dashboard styles: modern, classic, sleek, minimal
  - Configurable landing page via DASHBOARD_LANDING

### Changed
- Environment variable naming: LANDING → DASHBOARD_LANDING, DASH_ORDER → DASHBOARD_ORDER
- Unraid template network mode: bridge → br0
- Environment variable organization in templates and scripts
- Documentation structure to reflect new category organization

### Removed
- Readarr service (no longer supported)
- Overseerr service (replaced with Seerr)
- CUSTOM_HTML mount point (HTML generated inside container)
- Unused Crypto Passphrase variables

### Fixed
- Modern dashboard React library loading
- qBittorrent proxy path handling (trailing slash fixes)
- Menu item targeting across all dashboard styles
- Jellyfin WebSocket configuration

---

## [2.0.0] - 2026-06-18

### Added
- **New Services** ⭐
  - SABnzbd (Usenet download client)
  - Deluge (Torrent client)
  - Total services now: 15

- **Enhanced Documentation**
  - GitHub-ready project structure
  - Contributing guidelines
  - MIT License
  - Proper .gitignore

- **Service Management**
  - Service-focused deployment guide
  - Complete feature summary
  - Icon download system with auto-resize
  - Dynamic HTML menu generation

- **Authentication**
  - Office 365 / Azure AD (OpenID Connect)
  - X-Remote-User header passing
  - Role-based access control

- **Media Services** (13 pre-configured)
  - Sonarr, Radarr, Whisparr, Lidarr, Readarr, Prowlarr
  - Overseerr, Jellyfin, Emby, Plex, Tautulli
  - Transmission, qBittorrent, SABnzbd, Deluge

### Changed
- Restructured documentation for clarity
- Improved icon system with fallback colored SVGs
- Enhanced error pages (502, 503)
- Better timeout handling for all services
- Updated .env.example with all options

### Fixed
- Broken icon URLs (removed non-working sources)
- WebSocket proxying for real-time services
- Long connection timeouts (300 seconds)
- Icon validation and resizing

---

## [1.5.0] - 2026-06-10

### Added
- Dynamic HTML menu system
- Icon auto-download and resize
- HTML menu customization guide
- Icon management documentation

### Changed
- Menu generation from static to dynamic
- Icon system from manual to auto-download
- Service configuration templating

---

## [1.4.0] - 2026-06-05

### Added
- Unraid native template support
- Office 365 authentication setup guide
- Complete features documentation
- Service descriptions and metadata

### Changed
- Apache module configuration
- OAuth2 setup process
- Certificate renewal handling

---

## [1.3.0] - 2026-06-01

### Added
- Custom backend support
- Extended service configuration
- Per-service proxy settings

### Changed
- Config generation script improvements
- Better error handling

---

## [1.2.0] - 2026-05-28

### Added
- 10 core services (Sonarr, Radarr, Lidarr, etc.)
- SSL/TLS configuration
- Let's Encrypt integration
- Service templating system

### Changed
- Apache configuration structure
- Docker entry point orchestration

---

## [1.1.0] - 2026-05-25

### Added
- Base Docker image
- Docker Compose setup
- Core reverse proxy functionality
- Basic service routing

---

## [1.0.0] - 2026-05-20

### Added
- Initial project setup
- Apache reverse proxy foundation
- Docker containerization
- Basic documentation

---

## Migration Guides

### From 1.x to 2.0

**New features require no action:**
- SABnzbd and Deluge are optional
- Enable in `.env` if desired:
  ```env
  ENABLE_SABNZBD=true
  ENABLE_DELUGE=true
  ```

**Docker image rebuild recommended:**
```bash
docker-compose build --no-cache
docker-compose up -d
```

**No breaking changes** — all existing configurations remain compatible.

---

## Roadmap

### Q3 2026
- [ ] Authelia authentication
- [ ] LDAP integration
- [ ] Basic Auth (htpasswd)

### Q4 2026
- [ ] Generic OAuth2 support
- [ ] Keycloak integration
- [ ] Web-based UI

### 2027
- [ ] Service discovery
- [ ] Health monitoring
- [ ] Rate limiting
- [ ] Advanced analytics

---

## Support

- **Questions:** Open a GitHub Discussion
- **Issues:** Open a GitHub Issue
- **Suggestions:** Open a GitHub Discussion
- **Security:** Email security concerns privately

---

## Credits

- Apache Software Foundation - Web Server
- Let's Encrypt - SSL/TLS Certificates
- Debian Foundation - Base OS
- Docker - Containerization

---

## License

This project is licensed under the MIT License.
See the [LICENSE](LICENSE) file for details.

---

**[⬆ back to top](#changelog)**
