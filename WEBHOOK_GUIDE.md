# 🔗 GitHub to Jenkins Webhook Setup

This document explains how to enable automatic builds whenever code is pushed to this repository.

## 🛠️ Prerequisites
* Jenkins must be reachable by GitHub. 
* If Jenkins is on `localhost`, use **ngrok** to create a public tunnel: `ngrok http 8080`.

## 🛰️ Configuration Steps

### 1. Jenkins Side
1. Navigate to your Pipeline Job.
2. Click **Configure**.
3. Under **Build Triggers**, enable:
   - [x] **GitHub hook trigger for GITScm polling**
4. Click **Save**.

### 2. GitHub Side
1. Go to your GitHub Repository **Settings**.
2. Click **Webhooks** -> **Add webhook**.
3. Set the following:
   - **Payload URL**: `http://<your-public-ip>:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Secret**: (Leave empty unless configured in Jenkins)
4. Click **Add webhook**.

## 🧪 Testing the Integration
1. Make a small change to `app/app.py` (e.g., change the title text).
2. Commit and push: `git commit -am "Testing webhook" && git push origin main`.
3. Go to Jenkins; a new build should trigger **automatically** within seconds.

## ❓ Troubleshooting
* **Red X in GitHub:** Ensure your firewall allows traffic on port `8080`.
* **No trigger:** Check if the Jenkins URL in the webhook ends with `/github-webhook/`.