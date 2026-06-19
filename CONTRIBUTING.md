# Contributing to Apache Reverse Proxy

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Getting Started

### Prerequisites

- Docker & Docker Compose
- Bash
- Git

### Setup Development Environment

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/apache-reverse-proxy.git
cd apache-reverse-proxy

# Create your feature branch
git checkout -b feature/your-feature-name

# Make your changes
# Test locally
docker-compose up -d
docker-compose logs -f apache-reverse-proxy
```

---

## Types of Contributions

### 1. Bug Fixes

**Before submitting:**
- [ ] Test the fix locally
- [ ] Include steps to reproduce
- [ ] Document the impact
- [ ] Reference any related issues

**Pull Request template:**
```markdown
## Fixes #(issue number)

### Description
Brief description of the bug and fix.

### Testing
How you tested the fix.

### Changes Made
- Change 1
- Change 2
```

### 2. New Features

**Before submitting:**
- [ ] Discuss in an issue first (optional but recommended)
- [ ] Follow the existing code style
- [ ] Update documentation
- [ ] Test thoroughly

**Examples of welcome features:**
- [ ] New authentication methods (LDAP, Authelia, etc.)
- [ ] Additional services (Sickgear, Mylar, Sonarr V4 features)
- [ ] Performance improvements
- [ ] Better error messages
- [ ] Security enhancements

### 3. Documentation

**Improvements welcome:**
- [ ] Clearer explanations
- [ ] Additional examples
- [ ] Troubleshooting guides
- [ ] Setup guides for specific platforms
- [ ] Tutorial videos/screenshots

### 4. Service Additions

Want to add a new service? Follow this process:

**1. Create the service config:**

```bash
cp apache-conf/services/sonarr.conf apache-conf/services/mynewservice.conf
# Edit the file with correct port and path
```

**2. Update scripts:**

```bash
# Edit generate-config.sh
# Add: ENABLE_MYNEWSERVICE="${ENABLE_MYNEWSERVICE:-false}"

# Edit generate-html-menu.sh
# Add to SERVICES array: [MYNEWSERVICE]="Service Name|port|#color|Description"

# Edit download-icons.sh
# Add to ICON_URLS array: [MYNEWSERVICE]="${ICON_URL_MYNEWSERVICE}"
```

**3. Update docker-compose.yml:**

```yaml
ENABLE_MYNEWSERVICE: "false"
ICON_URL_MYNEWSERVICE: ""
```

**4. Update .env.example:**

```bash
ENABLE_MYNEWSERVICE=false
ICON_URL_MYNEWSERVICE=""
```

**5. Document in docs/SERVICES.md**

**6. Test:**

```bash
docker-compose build
docker-compose up -d
docker-compose logs -f apache-reverse-proxy
# Verify it shows in the menu
```

---

## Code Style Guidelines

### Bash Scripts

```bash
#!/bin/bash
# Use set -e to exit on error
set -e

# Use meaningful variable names
SERVICE_NAME="example"

# Comment complex logic
if [[ $? -eq 0 ]]; then
    echo "Success: $SERVICE_NAME started"
fi
```

### Apache Configs

```apache
# Use consistent indentation (4 spaces)
<Location /service>
    ProxyPass http://service:port/
    ProxyPassReverse http://service:port/
    
    # Group related directives
    RequestHeader set X-Forwarded-For "%{REMOTE_ADDR}s"
    RequestHeader set X-Forwarded-Proto "https"
</Location>
```

### Documentation

- Use markdown with proper headings
- Include code examples
- Add section dividers for readability
- Keep line length reasonable (~80 chars)

---

## Testing Your Changes

### Local Testing

```bash
# Build image
docker-compose build

# Start container
docker-compose up -d

# Check logs
docker-compose logs -f apache-reverse-proxy

# Test specific service
curl -k https://localhost/sonarr

# View generated configs
docker-compose exec apache-reverse-proxy cat /etc/apache2/sites-enabled/reverse-proxy.conf

# Verify menu
docker-compose exec apache-reverse-proxy cat /var/www/html/index.html
```

### Checklist Before Submitting

- [ ] Code follows style guidelines
- [ ] Documentation is updated
- [ ] Changes tested locally
- [ ] No breaking changes (or documented)
- [ ] Error messages are clear
- [ ] Comments added for complex logic
- [ ] Commits are atomic and well-documented

---

## Commit Message Guidelines

```
Type: Brief description (50 chars)

Longer explanation if needed. Wrap at ~72 characters.

- Bullet point 1
- Bullet point 2

Fixes #123
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `refactor:` Code reorganization (no behavior change)
- `test:` Test additions/changes
- `chore:` Build/CI/dependency updates
- `perf:` Performance improvements

---

## Pull Request Process

1. **Fork the repository** on GitHub
2. **Create a feature branch**: `git checkout -b feature/description`
3. **Make your changes** with clear commits
4. **Test locally**: `docker-compose up -d && docker-compose logs`
5. **Push to your fork**: `git push origin feature/description`
6. **Open a Pull Request** with:
   - Clear description of changes
   - Link to related issues
   - Testing instructions
   - Screenshots if UI changes

### PR Template

```markdown
## Description
Brief summary of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## How to Test
Steps to verify the changes work.

## Checklist
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Tested locally
- [ ] No breaking changes
```

---

## Adding New Authentication Methods

If adding authentication (Authelia, LDAP, OAuth2, etc.):

1. **Create config template**: `apache-conf/auth-{method}.conf.template`
2. **Update Dockerfile**: Add required modules
3. **Update docker-entrypoint.sh**: Add setup logic
4. **Document**: Create `docs/{METHOD}-AUTH.md`
5. **Update .env.example**: Add all required variables
6. **Test**: Verify with test credentials

---

## Documentation Standards

### File Organization

```
docs/
├── README.md              # Main documentation index
├── QUICKSTART.md          # 5-minute setup
├── SERVICES.md            # All 15 services
├── {SERVICE}-SETUP.md     # Service-specific guides
├── {AUTH}-AUTH.md         # Authentication guides
├── TROUBLESHOOTING.md     # Problem solutions
└── CONTRIBUTING.md        # This file
```

### Documentation Template

```markdown
# Topic Title

## Overview
Brief description.

## Features
- Feature 1
- Feature 2

## Setup
Step-by-step instructions.

## Configuration
Configuration examples.

## Troubleshooting
Common issues and solutions.

## See Also
Links to related docs.
```

---

## Reporting Issues

### Bug Reports

Include:

```markdown
## Bug Description
Brief description of the issue.

## Steps to Reproduce
1. Step 1
2. Step 2

## Expected Behavior
What should happen.

## Actual Behavior
What actually happens.

## Environment
- OS: Ubuntu 20.04
- Docker: 20.10+
- Services enabled: Sonarr, Radarr

## Error Logs
```
docker-compose logs apache-reverse-proxy
```

## Screenshots
If applicable, add screenshots.
```

### Feature Requests

```markdown
## Feature Description
What you'd like to add.

## Use Case
Why you need this feature.

## Alternative Solutions
Other ways to solve this.

## Additional Context
Any other relevant information.
```

---

## Community Guidelines

- Be respectful and inclusive
- Provide constructive feedback
- Help others when you can
- Report security issues privately (security@example.com)
- No spam or self-promotion

---

## Questions?

- 📖 Check the [Documentation](./docs/)
- 💬 Open a Discussion on GitHub
- 🐛 Open an Issue for bugs

---

## Recognition

Contributors are recognized in:
- CONTRIBUTORS.md file
- Release notes
- GitHub contributors page

Thank you for contributing! 🙏
