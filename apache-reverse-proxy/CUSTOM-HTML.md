# Customizing HTML & Styling

## Quick Start - Modify Existing Files

The easiest way to customize is to edit the existing HTML files directly in the `html/` directory:

```bash
html/
├── index.html                  # Home/root page
└── error-pages/
    ├── 502.html               # Bad Gateway error
    └── 503.html               # Service Unavailable error
```

### Step 1: Edit the HTML
Open any file in `html/` and modify the styling, content, or layout.

### Step 2: Rebuild
```bash
docker-compose build
docker-compose restart apache-reverse-proxy
```

### Step 3: Test
Visit `https://yourdomain.com/` to see changes

---

## Using Your Own Custom HTML

If you have your own HTML files, you can use them instead:

### Option 1: Direct File Replacement (Simplest)

1. **Backup originals** (optional):
   ```bash
   mv html html.backup
   mkdir html
   mkdir html/error-pages
   ```

2. **Copy your files**:
   ```bash
   # Your custom home page
   cp /path/to/your/index.html html/
   
   # Your custom error pages
   cp /path/to/your/502.html html/error-pages/
   cp /path/to/your/503.html html/error-pages/
   ```

3. **Rebuild**:
   ```bash
   docker-compose build
   docker-compose up -d
   ```

### Option 2: Volume Mount (For Development)

If you want to change HTML without rebuilding, use volume mounts in `docker-compose.yml`:

```yaml
apache-reverse-proxy:
  # ... other config ...
  volumes:
    - letsencrypt-data:/etc/letsencrypt
    - apache-logs:/var/log/apache2
    - ./html:/var/www/html          # ← Add this line
```

Now changes to `html/` are live without rebuilding:

```bash
# Edit your HTML
nano html/index.html

# Restart Apache (or just refresh browser in many cases)
docker-compose restart apache-reverse-proxy
```

### Option 3: Mount Entire Custom Directory

If you have a separate HTML directory elsewhere:

```yaml
volumes:
  - /path/to/your/custom/html:/var/www/html
```

---

## HTML File Structure

Your HTML directory should look like this:

```
html/
├── index.html                    # Served at: /
├── error-pages/
│   ├── 502.html                 # Served for 502 errors
│   └── 503.html                 # Served for 503 errors
└── [optional other files]
    ├── css/
    ├── js/
    ├── images/
    └── ...
```

### File Paths

- **Home page**: `html/index.html` → accessed at `https://yourdomain.com/`
- **502 error**: `html/error-pages/502.html` → shown when backend unavailable
- **503 error**: `html/error-pages/503.html` → shown when services offline
- **Static assets**: `html/css/`, `html/js/`, `html/images/` → accessed normally

---

## Styling & CSS

### Use CSS Variables for Theming

The provided HTML uses CSS variables, making theming easy:

```css
:root {
    --primary-color: #667eea;
    --secondary-color: #764ba2;
    --success-color: #10b981;
    --danger-color: #f5576c;
    --warning-color: #fa709a;
    --text-color: #333;
    --bg-color: #ffffff;
}
```

Just override in your CSS:

```css
:root {
    --primary-color: #0066cc;
    --secondary-color: #00ccff;
    --success-color: #00ff00;
    --danger-color: #ff0000;
}
```

### Complete HTML Template

Here's a minimal custom HTML file you can use as a starting point:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Media Server</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        :root {
            --primary: #667eea;
            --bg: #f5f5f5;
            --text: #333;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: var(--bg);
            color: var(--text);
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 40px 20px;
        }
        
        header {
            text-align: center;
            margin-bottom: 40px;
        }
        
        h1 {
            color: var(--primary);
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .services {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }
        
        .service-card {
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            text-decoration: none;
            color: var(--text);
            transition: transform 0.3s, box-shadow 0.3s;
        }
        
        .service-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 4px 16px rgba(0,0,0,0.15);
        }
        
        .service-card h2 {
            color: var(--primary);
            margin-bottom: 10px;
        }
        
        .service-card p {
            font-size: 0.9em;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🎬 My Media Server</h1>
            <p>Access your applications</p>
        </header>
        
        <div class="services">
            <a href="/sonarr" class="service-card">
                <h2>📺 Sonarr</h2>
                <p>TV show automation</p>
            </a>
            
            <a href="/radarr" class="service-card">
                <h2>🎥 Radarr</h2>
                <p>Movie automation</p>
            </a>
            
            <a href="/whisparr" class="service-card">
                <h2>💭 Whisparr</h2>
                <p>Comic & Manga automation</p>
            </a>
            
            <a href="/jellyfin" class="service-card">
                <h2>▶️ Jellyfin</h2>
                <p>Media streaming</p>
            </a>
            
            <a href="/qbittorrent" class="service-card">
                <h2>📥 qBittorrent</h2>
                <p>Torrent client</p>
            </a>
        </div>
    </div>
</body>
</html>
```

Save this as `html/index.html` and customize to your liking!

---

## Adding Custom Assets

You can serve CSS, JavaScript, images, and other files:

```
html/
├── index.html
├── css/
│   └── style.css
├── js/
│   └── script.js
├── images/
│   ├── logo.png
│   └── banner.jpg
└── error-pages/
    ├── 502.html
    └── 503.html
```

Reference them in your HTML:

```html
<link rel="stylesheet" href="/css/style.css">
<script src="/js/script.js"></script>
<img src="/images/logo.png" alt="Logo">
```

All files in the `html/` directory are served from the root `/` path.

---

## Advanced: Custom Error Pages

### 502 Error Page (Bad Gateway)

Create `html/error-pages/502.html` to show when a backend is unreachable.

Useful information to display:
- Service name that failed
- When service went down
- Suggested actions
- Status page link

```html
<!DOCTYPE html>
<html>
<head>
    <title>502 Bad Gateway</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
        }
        
        .container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            text-align: center;
            max-width: 500px;
        }
        
        h1 {
            color: #f5576c;
            margin: 0;
        }
        
        .error-code {
            font-size: 4em;
            font-weight: bold;
            margin: 20px 0;
        }
        
        p {
            color: #666;
            line-height: 1.6;
        }
        
        a {
            display: inline-block;
            margin-top: 20px;
            padding: 12px 30px;
            background: #f5576c;
            color: white;
            text-decoration: none;
            border-radius: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Bad Gateway</h1>
        <div class="error-code">502</div>
        <p>The service is temporarily unavailable. Please try again in a moment.</p>
        <a href="/">Back to Home</a>
    </div>
</body>
</html>
```

### 503 Error Page (Service Unavailable)

Similar to 502, but for when all backends are down or under maintenance.

---

## Docker & HTML Changes

### When Using Volume Mount

If you're using a volume mount for live editing:

```yaml
volumes:
  - ./html:/var/www/html
```

Changes are reflected **instantly** (no rebuild needed). Just refresh your browser!

### When Using COPY in Dockerfile

If you're copying files during build:

```dockerfile
COPY html/ /var/www/html/
```

You need to rebuild after changes:

```bash
docker-compose build
docker-compose restart apache-reverse-proxy
```

---

## Troubleshooting

### HTML Changes Not Appearing

**Check 1: Did you restart Apache?**
```bash
docker-compose restart apache-reverse-proxy
```

**Check 2: Are you using volume mount or COPY?**
- Volume mount: Changes instant, just refresh
- COPY: Rebuild needed

**Check 3: Check browser cache**
- Clear cache or use Ctrl+Shift+Delete
- Or use incognito/private mode

### CSS Not Loading

If your CSS isn't loading, check:

1. **File path is correct**: Should be `html/css/style.css`
2. **Reference is correct**: `<link rel="stylesheet" href="/css/style.css">`
3. **File exists in container**:
   ```bash
   docker-compose exec apache-reverse-proxy ls /var/www/html/css/
   ```

### Images Not Showing

```html
<!-- Correct: relative to root -->
<img src="/images/logo.png">

<!-- Wrong: relative paths -->
<img src="images/logo.png">
```

---

## Tips & Tricks

### Create a Dashboard

Make your home page a dashboard linking to all services:

```html
<style>
    .grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 20px;
    }
    
    .card {
        background: #f0f0f0;
        padding: 20px;
        border-radius: 8px;
        text-align: center;
    }
    
    .card a {
        display: block;
        padding: 20px 0;
        text-decoration: none;
        color: #333;
        font-weight: bold;
    }
    
    .card:hover {
        background: #e0e0e0;
    }
</style>

<div class="grid">
    <div class="card"><a href="/sonarr">📺 Sonarr</a></div>
    <div class="card"><a href="/radarr">🎥 Radarr</a></div>
    <div class="card"><a href="/jellyfin">▶️ Jellyfin</a></div>
    <!-- More services... -->
</div>
```

### Show Service Status

Use JavaScript to check if services are online:

```javascript
async function checkService(path) {
    try {
        const response = await fetch(path);
        return response.ok;
    } catch {
        return false;
    }
}

checkService('/sonarr').then(online => {
    const status = online ? '🟢 Online' : '🔴 Offline';
    console.log('Sonarr: ' + status);
});
```

### Responsive Design

Always include the viewport meta tag:

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

Use responsive CSS:

```css
@media (max-width: 768px) {
    .grid {
        grid-template-columns: 1fr;
    }
}
```

---

## Next Steps

1. **Copy example template** (provided above) and customize
2. **Place in `html/` directory**
3. **Use volume mount** for live editing or **rebuild** if using COPY
4. **Test** at `https://yourdomain.com/`

Your custom HTML will be served at the root path!
