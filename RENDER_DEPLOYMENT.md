# 🚀 Deploying Privacy-Preserving Chatbot to Render

This project is fully configured for deployment on [Render](https://render.com).

You have two deployment options:
- **Option A (Recommended & 100% Free)**: **Render Static Site** — Instant global CDN, custom domains, free automatic SSL, zero server costs, and no sleep timeouts.
- **Option B**: **Render Docker Web Service** — Containerized Nginx deployment using the provided `Dockerfile`.

---

## ⚡ Option A: Render Static Site (Recommended - Free Tier)

### Method 1: Automatic Blueprint (Easiest)
1. Push your repository to **GitHub**.
2. Log in to [dashboard.render.com](https://dashboard.render.com).
3. Click **New +** > **Blueprint**.
4. Connect your GitHub repository.
5. Render will automatically detect `render.yaml` and configure:
   - **Name**: `privacy-preserving-chatbot`
   - **Environment**: `Static Site`
   - **Build Command**: `chmod +x render-build.sh && ./render-build.sh`
   - **Publish Directory**: `./build/web`
   - **SPA Routing Rule**: `/*` ➔ `/index.html`
6. Click **Apply**. Render will automatically clone, build, and deploy your site to `https://<your-app>.onrender.com`.

---

### Method 2: Manual Static Site Setup
If you prefer configuring via the Render Dashboard without Blueprints:

1. In the Render Dashboard, click **New +** > **Static Site**.
2. Connect your GitHub repository: `Flutter-Project` (or `PrivacyPreservingchatbot`).
3. Fill in the deployment settings:
   - **Name**: `privacy-preserving-chatbot`
   - **Branch**: `main`
   - **Build Command**:
     ```bash
     chmod +x render-build.sh && ./render-build.sh
     ```
   - **Publish Directory**:
     ```bash
     build/web
     ```
4. **Crucial for SPA Routing**:
   - Scroll down to **Redirects/Rewrites**.
   - Click **Add Rule**:
     - **Type**: `Rewrite`
     - **Source**: `/*`
     - **Destination**: `/index.html`
   *(This ensures refreshing on `/chat`, `/documents`, or `/settings` works without 404 errors).*
5. Click **Create Static Site**.

---

## 🐳 Option B: Render Web Service via Docker

If you prefer deploying as a containerized web server:

1. In the Render Dashboard, click **New +** > **Web Service**.
2. Connect your GitHub repository.
3. Select **Docker** as the Runtime.
4. Render will automatically detect `Dockerfile` and `nginx.conf`:
   - Stage 1 compiles the Flutter Web app.
   - Stage 2 serves the optimized bundle with Nginx on Render's dynamic `$PORT`.
5. Select the **Free** instance plan.
6. Click **Create Web Service**.

---

## 🔍 How the Render Build Works

During deployment on Render:
1. `render-build.sh` downloads a lightweight shallow clone of the stable Flutter SDK (`--depth 1`).
2. Configures Flutter Web with analytics disabled.
3. Runs `flutter pub get` and `flutter analyze`.
4. Runs `flutter build web --release` to produce the production-ready HTML, JavaScript, WebAssembly, and asset bundle in `build/web`.
5. Render deploys the contents of `build/web` directly to their high-speed edge CDN.

---

## ✅ Deployment Checklist

- [x] `render.yaml` Blueprint created with caching headers and SPA rewrite rules.
- [x] `render-build.sh` automated build script created with LF line endings.
- [x] `Dockerfile` and `nginx.conf` provided for Docker alternative.
- [x] Zero external backend dependencies — runs 100% in-browser.
- [x] Light, Dark, and High-Contrast themes supported out-of-the-box.
- [x] Persistent theme state in browser `SharedPreferences`.
