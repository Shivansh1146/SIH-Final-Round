# 🚀 SHAYAK-AI Deployment Guide

This guide covers complete production deployment for both the **FastAPI Clinical ML Engine** and the **Flutter Frontend (Web + Android Mobile)**.

---

## 1. ⚡ Backend Deployment (FastAPI + ML + SHAP)

The backend provides clinical inference, multimodal kinematic fusion, and real-time SHAP explainability.

### Option A: Free 1-Click Cloud Hosting on Render (Recommended)
1. Push your project to **GitHub**.
2. Go to [Render.com](https://render.com) and click **New +** → **Web Service**.
3. Connect your GitHub repository.
4. Set the following parameters:
   * **Root Directory**: `backend`
   * **Runtime**: `Python 3`
   * **Build Command**: `pip install -r requirements.txt`
   * **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
5. Click **Deploy Web Service**.
6. Render will provide a public URL (e.g., `https://shayak-backend.onrender.com`).

---

### Option B: Deploy with Docker (Railway / Fly.io / Cloud Run / AWS)
The backend includes a pre-configured production [`backend/Dockerfile`](file:///c:/Users/souha/OneDrive/Desktop/SIH/backend/Dockerfile).

```bash
cd backend
docker build -t shayak-ai-backend .
docker run -p 8000:8000 shayak-ai-backend
```

---

## 2. 🌐 Frontend Web Deployment (Flutter Web)

The production web build is compiled into static, high-performance HTML/JS/WASM assets in `shayak_mobile/build/web`.

### Build Command:
```powershell
cd shayak_mobile
flutter build web --release
```

### Deploy to Vercel (Free & Instant):
1. Install Vercel CLI (or connect GitHub repository):
   ```bash
   npm i -g vercel
   cd shayak_mobile/build/web
   vercel --prod
   ```
2. Or in the [Vercel Dashboard](https://vercel.com):
   * Set **Root Directory**: `shayak_mobile`
   * Set **Build Command**: `flutter build web --release`
   * Set **Output Directory**: `build/web`

### Deploy to Netlify / GitHub Pages:
* Simply drag & drop the `shayak_mobile/build/web` folder directly into [Netlify Drop](https://app.netlify.com/drop).

---

## 3. 📱 Android Mobile App Deployment (.APK / Play Store)

To build a standalone installable APK file for Android phones:

```powershell
cd shayak_mobile

# 1. Build Debug APK (For direct testing on any Android phone)
flutter build apk --debug

# 2. Build Release APK (Optimized for production installation)
flutter build apk --release

# 3. Build Google Play Store App Bundle (.aab)
flutter build appbundle --release
```

The output file will be generated at:
`shayak_mobile/build/app/outputs/flutter-apk/app-release.apk`
