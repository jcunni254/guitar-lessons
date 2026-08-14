# 🚀 Quick Start - Copy & Paste Terminal Commands

**This is your terminal command roadmap. Copy-paste each section in order.**

---

## Phase 1: Local Setup (5 minutes)

```bash
# 1️⃣ Create project directory
cd ~/Projects
mkdir guitar-lesson-booking
cd guitar-lesson-booking

# 2️⃣ Copy all files to this directory
# (You should have: server.js, package.json, .env.example, render.yaml, etc.)

# 3️⃣ Initialize Git
git init
git add .
git commit -m "Initial commit: Production guitar booking platform"
```

---

## Phase 2: Generate Security Credentials (3 minutes)

```bash
# 4️⃣ Generate JWT_SECRET (copy the output)
openssl rand -base64 32

# 5️⃣ Generate ADMIN_PASSWORD_HASH (replace 'YourPassword123!' with your password, copy the output)
node -e "console.log(require('bcryptjs').hashSync('YourPassword123!', 10))"

# 6️⃣ Get Gmail App Password
# Go to: https://myaccount.google.com/security → App passwords
# Enable 2-Step Verification if needed
# Select Mail + your device → Copy the 16-character password
```

---

## Phase 3: Setup Environment (2 minutes)

```bash
# 7️⃣ Create .env file from template
cp .env.example .env

# 8️⃣ Edit .env with your credentials
nano .env

# Fill in:
# SUPABASE_URL=https://your-project.supabase.co
# SUPABASE_ANON_KEY=eyJhbGc...
# UPSTASH_REDIS_REST_URL=https://your-url.upstash.io
# UPSTASH_REDIS_REST_TOKEN=AbCdEfGhIj...
# JWT_SECRET=<paste from step 4️⃣>
# ADMIN_PASSWORD_HASH=<paste from step 5️⃣>
# EMAIL_USER=your-gmail@gmail.com
# EMAIL_PASSWORD=<paste from step 6️⃣>
# FRONTEND_URL=http://localhost:3000,https://yourdomain.com
# NODE_ENV=production

# Save and exit: Ctrl+X, then Y, then Enter
```

---

## Phase 4: Install Dependencies (2 minutes)

```bash
# 9️⃣ Run setup script
chmod +x LOCAL_SETUP.sh
./LOCAL_SETUP.sh

# This installs all Node.js dependencies
```

---

## Phase 5: GitHub Setup (3 minutes)

```bash
# 🔟 Go to https://github.com/new and create repository
# Name: guitar-lesson-booking
# Set to Private
# Click Create

# Then run these commands (replace YOUR_USERNAME):
git remote add origin https://github.com/YOUR_USERNAME/guitar-lesson-booking.git
git branch -M main
git push -u origin main

# Verify
git remote -v
```

---

## Phase 6: Supabase Setup (5 minutes)

```bash
# 1️⃣1️⃣ Go to https://supabase.com → Create new project
# Project name: guitar-lessons
# Database password: Use strong password (save it!)
# Region: Choose closest to you
# Wait ~2 minutes for project creation

# 1️⃣2️⃣ In Supabase Dashboard → SQL Editor → New Query
# Paste ALL contents of supabase-setup.sql file
# Click "Run"
# Wait for success message

# 1️⃣3️⃣ Get API credentials
# Settings → API → Copy:
# - Project URL → SUPABASE_URL
# - anon public key → SUPABASE_ANON_KEY
# Update your .env file with these

# 1️⃣4️⃣ Test connection
curl https://your-project.supabase.co/rest/v1/health \
  -H "apikey: YOUR_ANON_KEY"
# Should return: {"ok":true}
```

---

## Phase 7: Upstash Redis Setup (3 minutes)

```bash
# 1️⃣5️⃣ Go to https://upstash.com → Create Database
# Name: guitar-bookings
# Type: Redis
# Region: Same as your server
# Click Create

# 1️⃣6️⃣ In Redis Dashboard → REST API → Copy:
# - UPSTASH_REDIS_REST_URL
# - UPSTASH_REDIS_REST_TOKEN
# Update your .env file with these

# 1️⃣7️⃣ Test connection
curl -X POST https://YOUR_UPSTASH_URL/ping \
  -H "Authorization: Bearer YOUR_UPSTASH_TOKEN"
# Should return: PONG
```

---

## Phase 8: Test Locally (3 minutes)

```bash
# 1️⃣8️⃣ Start development server (Terminal 1)
npm run dev

# Should see:
# ╔═══════════════════════════════════════════════════════╗
# ║     🎸 Guitar Lesson Booking Platform - Server       ║
# ║     Environment: production                          ║
# ║     Port: 3000                                        ║
# ║     Status: ✅ Running                                ║
# ╚═══════════════════════════════════════════════════════╝

# 1️⃣9️⃣ Test API (Terminal 2)
curl http://localhost:3000/health

# Should return: {"status":"operational",...}

# 2️⃣0️⃣ Test admin login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"password":"YourPassword123!"}'

# Should return auth token
```

---

## Phase 9: Deploy to Render (5 minutes)

```bash
# 2️⃣1️⃣ Push code to GitHub
git add .
git commit -m "Ready for deployment"
git push origin main

# 2️⃣2️⃣ Go to https://render.com → Click "New" → "Web Service"
# Click "Connect GitHub account"
# Select: guitar-lesson-booking
# Click "Connect"

# 2️⃣3️⃣ Configure:
# Name: guitar-lesson-api
# Environment: Node
# Build Command: npm install
# Start Command: node server.js
# Plan: Standard ($7/month)
# Click "Create Web Service"

# 2️⃣4️⃣ Add Environment Variables (in Render Dashboard)
# Go to Environment tab and add each from your .env:
# SUPABASE_URL, SUPABASE_ANON_KEY, UPSTASH_REDIS_REST_URL, etc.
# Click "Save"

# 2️⃣5️⃣ Deployment will start automatically
# Watch dashboard until you see "Build succeeded"
# Your URL will be: https://guitar-lesson-api.onrender.com
```

---

## Phase 10: Production Verification (5 minutes)

```bash
# 2️⃣6️⃣ Test production API
curl https://guitar-lesson-api.onrender.com/health

# 2️⃣7️⃣ Test production login
curl -X POST https://guitar-lesson-api.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"password":"YourPassword123!"}'

# 2️⃣8️⃣ Test production booking
curl -X POST https://guitar-lesson-api.onrender.com/api/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "date": "2024-02-15",
    "time": "10:00 AM",
    "isFirstTime": true,
    "deviceFingerprint": "test-device"
  }'

# 2️⃣9️⃣ Verify in Supabase
# Go to Supabase Dashboard → bookings table
# Should see your test booking

# 3️⃣0️⃣ Update Frontend Files
# Update API_BASE_URL in HTML files to:
# https://guitar-lesson-api.onrender.com
# Push changes: git push origin main
```

---

## ✅ Deployment Complete Checklist

```
☐ Phase 1: Local Setup
☐ Phase 2: Generated JWT_SECRET & Admin Password Hash  
☐ Phase 3: Updated .env with all credentials
☐ Phase 4: Installed dependencies
☐ Phase 5: GitHub repository created & code pushed
☐ Phase 6: Supabase project created & database schema imported
☐ Phase 7: Upstash Redis database created
☐ Phase 8: Tested locally (health check passed)
☐ Phase 9: Deployed to Render (build succeeded)
☐ Phase 10: Production tests passed

🎉 YOUR BOOKING PLATFORM IS LIVE!
```

---

## 🔧 Useful Terminal Commands (After Deployment)

```bash
# View logs in Render dashboard
# https://dashboard.render.com → Your Service → Logs

# View database in Supabase
# https://supabase.com/dashboard → Your Project → bookings table

# View Redis stats
# https://console.upstash.com → Your Database → Stats

# Make changes to code
git add .
git commit -m "Your changes"
git push origin main
# (Render auto-deploys on push)

# Emergency: Kill backend process
kill -9 $(lsof -t -i:3000)

# Test specific endpoint
curl https://guitar-lesson-api.onrender.com/api/check-availability \
  -H "Content-Type: application/json" \
  -d '{"date":"2024-02-15","time":"10:00 AM"}'

# View current environment variables
cat .env
```

---

## ⚠️ If Something Goes Wrong

```bash
# Check API is running
curl https://guitar-lesson-api.onrender.com/health

# Check database connection
curl https://YOUR_SUPABASE_URL/rest/v1/health \
  -H "apikey: YOUR_ANON_KEY"

# Check Redis connection
curl -X POST https://YOUR_UPSTASH_URL/ping \
  -H "Authorization: Bearer YOUR_UPSTASH_TOKEN"

# View .env to verify all values
cat .env

# Restart Render service
# Go to https://dashboard.render.com → Service Settings → Reboot
```

---

## 📊 Total Time: ~40 Minutes

- Phase 1: 5 min
- Phase 2: 3 min
- Phase 3: 2 min
- Phase 4: 2 min
- Phase 5: 3 min
- Phase 6: 5 min
- Phase 7: 3 min
- Phase 8: 3 min
- Phase 9: 5 min
- Phase 10: 5 min

**That's it! You're done! 🎸**

---

## Next: Update Frontend

Update your HTML files to point to production API:

```javascript
// Replace this:
const API_URL = 'http://localhost:3000';

// With this:
const API_URL = 'https://guitar-lesson-api.onrender.com';
```

Then:
```bash
git add .
git commit -m "Connect frontend to production API"
git push origin main
```

**Your platform is now LIVE and SECURE!** 🚀

