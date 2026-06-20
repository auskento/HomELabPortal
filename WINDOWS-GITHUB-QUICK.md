# Windows Git Quick Reference - TL;DR

## 5-Minute Setup

### 1. Install Git
- Download: https://git-scm.com/download/win
- Run installer, click next through defaults
- Verify: `git --version` in Command Prompt

### 2. Configure Git
```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### 3. Create GitHub Repo
- Go to https://github.com/new
- Name: `apache-reverse-proxy`
- Click Create
- Copy the HTTPS URL shown

### 4. In Your Project Folder
```bash
git init
git add .
git commit -m "Initial commit: Apache reverse proxy"
git remote add origin https://github.com/YOU/apache-reverse-proxy.git
git branch -M main
git push -u origin main
```

### 5. Done!
- GitHub automatically prompts for login first push
- All files are now on GitHub 🎉

---

## Common Commands

```bash
# Check status
git status

# View commits
git log --oneline -5

# Add and commit together
git add .
git commit -m "Your message"

# Push changes
git push

# Pull latest
git pull

# Create new branch
git checkout -b feature/name

# Switch branch
git checkout main

# Delete branch
git branch -d feature/name
```

---

## Opening Command Prompt in Project Folder (Windows)

1. In Windows Explorer, navigate to your project
2. Hold **Shift** + Right-click in empty space
3. Select **Open PowerShell window here**
4. Type `git` commands

---

## If Authentication Fails

**Option 1: Personal Access Token**
1. Go to https://github.com/settings/tokens
2. Click "Generate new token"
3. Check `repo` and `write:packages`
4. Copy token
5. When prompted for password, paste token instead

**Option 2: SSH Key**
```bash
ssh-keygen -t ed25519 -C "your@email.com"
# Press Enter for all prompts
type C:\Users\YourUsername\.ssh\id_ed25519.pub
# Copy output, add to https://github.com/settings/keys
# Then:
git remote set-url origin git@github.com:YOU/apache-reverse-proxy.git
```

---

## Directory Structure on Windows

```
C:\Users\YourUsername\projects\apache-reverse-proxy\
├── docker-compose.yml
├── Dockerfile
├── README.md
├── CONTRIBUTING.md
├── LICENSE
├── apache-conf\
├── html\
├── scripts\
└── docs\
```

---

## Visual Studio Code (Easier Way)

1. Install VS Code: https://code.visualstudio.com
2. Open your project folder in VS Code
3. Click Source Control (left sidebar)
4. Git is built-in - no command line needed!
5. Click Commit buttons instead of typing commands

---

## GitHub Desktop (GUI Way)

1. Download: https://desktop.github.com
2. Sign in with GitHub
3. File → Clone Repository → Choose your repo
4. Make changes, click Commit, click Push
5. All graphical - no command line!

---

## Still Having Issues?

See full guide: **WINDOWS-GITHUB-GUIDE.md**

Key steps:
1. Install Git
2. Configure name/email
3. Extract project files
4. Open command prompt in project folder
5. Run 4 git commands
6. Done!

---

## Remember

- **Username:** Your GitHub account name
- **Email:** Email you used for GitHub
- **Password:** Personal Access Token (not GitHub password)
- **Repository name:** apache-reverse-proxy

Good luck! 🚀
