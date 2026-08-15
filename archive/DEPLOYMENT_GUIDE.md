# Production Deployment Guide
## Guitar Lesson Booking Platform

---

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [GitHub Setup](#github-setup)
3. [Supabase Configuration](#supabase-configuration)
4. [Upstash Redis Setup](#upstash-redis-setup)
5. [Render Deployment](#render-deployment)
6. [Environment Configuration](#environment-configuration)
7. [Security Hardening](#security-hardening)
8. [Post-Deployment Verification](#post-deployment-verification)
9. [Monitoring & Maintenance](#monitoring--maintenance)

---

## Prerequisites

Before you begin, ensure you have:

- ✅ GitHub account (already have)
- ✅ Render account (https://render.com)
- ✅ Supabase account (https://supabase.com)
- ✅ Upstash account (https://upstash.com)
- ✅ Gmail account with App Password enabled
- ✅ Domain name (optional but recommended)

---

## GitHub Setup

### Step 1: Create a New Repository

1. Go to https://github.com/new
2. Repository name: `guitar-lesson-booking`
3. Description: `Professional guitar lesson booking platform`
4. Set to **Private** (unless you want it public)
5. Initialize with README
6. Click "Create repository"

### Step 2: Clone and Add Files

```bash
git clone https://github.com/yourusername/guitar-lesson-booking.git
cd guitar-lesson-booking

# Copy all backend files (server.js, package.json, etc.)
# Copy all frontend files (HTML files)

git add .
git commit -m "Initial commit: Production-ready booking platform"
git push origin main
```

### Step 3: Create `render.yaml` Branch

```bash
# The render.yaml file is already created
# Render will automatically read this configuration
git add render.yaml
git commit -m "Add Render deployment configuration"
git push origin main
```

---

## Supabase Configuration

### Step 1: Create Supabase Project

1. Go to https://supabase.com and sign in
2. Click "New Project"
3. Name: `guitar-lessons`
4. Database password: Generate strong password (save it!)
5. Region: Select closest to your location
6. Click "Create new project" (wait ~2 minutes)

### Step 2: Set Up Database Schema

1. In Supabase dashboard, click "SQL Editor"
2. Click "New Query"
3. Copy entire content from `supabase-setup.sql` file
4. Click "Run"
5. Wait for all tables to create (you should see success message)

### Step 3: Get API Credentials

1. Go to Project Settings → API
2. Copy these values (you'll need them):
   - **Project URL** → `SUPABASE_URL`
   - **anon public** key → `SUPABASE_ANON_KEY`

### Step 4: Enable Row Level Security (RLS)

1. Go to Authentication → Policies
2. Verify that RLS is enabled on all tables
3. This is already configured in the SQL file

### Step 5: Set Up Email Notifications (Optional)

1. Go to Settings → Email Templates
2. Customize the default email templates if desired
3. Configure email sending via SMTP if needed

---

## Upstash Redis Setup

### Step 1: Create Upstash Database

1. Go to https://upstash.com and sign in
2. Click "Create Database"
3. Name: `guitar-bookings`
4. Region: Select same region as Render (closest to your location)
5. Database type: Redis
6. Click "Create"

### Step 2: Get Connection Details

1. Click on your database
2. Go to "REST API"
3. Copy these values:
   - **UPSTASH_REDIS_REST_URL** → Use the URL
   - **UPSTASH_REDIS_REST_TOKEN** → Use the token

### Step 3: Test Connection

You can test from Upstash console:

```
PING
```

Should return: `PONG`

### Step 4: Configure Retention (Optional)

1. Go to Settings
2. Set auto-expiration to prevent bloat
3. Recommended: 30 days

---

## Render Deployment

### Step 1: Connect GitHub to Render

1. Go to https://render.com and sign in
2. Click "New" → "Web Service"
3. Click "Connect account" (GitHub)
4. Authorize Render to access your GitHub
5. Select your repository: `guitar-lesson-booking`
6. Branch: `main`
7. Click "Connect"

### Step 2: Configure Render Service

1. **Name**: `guitar-lesson-api`
2. **Environment**: `Node`
3. **Build Command**: `npm install`
4. **Start Command**: `node server.js`
5. **Plan**: Standard ($7/month recommended for production)
6. Click "Create Web Service"

### Step 3: Add Environment Variables

Render will see `render.yaml` and configure automatically, but you need to add secrets:

1. Go to your service dashboard
2. Click "Environment"
3. Add each variable (see `.env.example`):

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-key-here
UPSTASH_REDIS_REST_URL=https://your-url.upstash.io
UPSTASH_REDIS_REST_TOKEN=your-token-here
JWT_SECRET=your-strong-random-secret
ADMIN_PASSWORD_HASH=your-bcrypt-hash
EMAIL_USER=your-gmail@gmail.com
EMAIL_PASSWORD=your-gmail-app-password
FRONTEND_URL=https://yourdomain.com,https://www.yourdomain.com
NODE_ENV=production
```

4. Click "Save Changes"

### Step 4: Deploy

1. Render will automatically deploy when you push to GitHub
2. Watch the deployment logs
3. Once "Build succeeded", your API is live!
4. Your API URL will be: `https://guitar-lesson-api.onrender.com`

---

## Environment Configuration

### Creating JWT_SECRET

Generate a secure secret:

```bash
# On macOS/Linux
openssl rand -base64 32

# On Windows
# Use: https://www.random.org/bytes/ and convert to base64
```

### Creating ADMIN_PASSWORD_HASH

You need to hash your password with bcrypt:

```bash
# Install bcryptjs globally
npm install -g bcryptjs

# Generate hash
node -e "console.log(require('bcryptjs').hashSync('YourPassword123!', 10))"
```

Use the output as `ADMIN_PASSWORD_HASH`

### Gmail App Password

1. Go to https://myaccount.google.com/security
2. Enable "2-Step Verification"
3. Go to "App passwords"
4. Select "Mail" and "Windows Computer" (or your device)
5. Copy the generated password
6. Use as `EMAIL_PASSWORD`

---

## Security Hardening

### Step 1: Configure Domain

1. In Render, go to "Settings" → "Custom Domain"
2. Add your domain: `api.yourdomain.com`
3. Follow DNS instructions
4. Wait for SSL certificate (automatic)

### Step 2: Enable Auto-Deployments

1. This is already enabled via `render.yaml`
2. Every push to `main` will redeploy

### Step 3: Set Up Monitoring

1. Render dashboard shows logs and metrics
2. Set up alerts (Render → Settings → Notifications)
3. Monitor error rates daily

### Step 4: Database Backups

1. Supabase automatically backs up daily
2. Go to Settings → Backups to restore if needed
3. Redis backups via Upstash dashboard

### Step 5: Rate Limiting

The server includes rate limiting:
- Booking endpoint: 5 requests/minute
- General API: 100 requests/15 minutes  
- Login: 5 attempts/15 minutes

This is handled server-side via Upstash Redis.

---

## Post-Deployment Verification

### Step 1: Test Health Check

```bash
curl https://guitar-lesson-api.onrender.com/health
```

Should return:
```json
{
  "status": "operational",
  "timestamp": "2024-01-15T...",
  "uptime": ...
}
```

### Step 2: Test Admin Login

```bash
curl -X POST https://guitar-lesson-api.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"password":"YourPassword123!"}'
```

Should return auth token.

### Step 3: Test Booking Creation

```bash
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
```

### Step 4: Verify Database

1. Open Supabase dashboard
2. Click "bookings" table
3. Should see your test booking
4. Check if device fingerprint is logged

---

## Monitoring & Maintenance

### Daily Checks

- [ ] Check Render logs for errors
- [ ] Monitor Upstash Redis memory usage
- [ ] Review new bookings in Supabase
- [ ] Check email delivery status

### Weekly Checks

- [ ] Review admin session logs
- [ ] Audit failed login attempts
- [ ] Check for duplicate bookings
- [ ] Monitor API performance metrics

### Monthly Checks

- [ ] Rotate JWT_SECRET
- [ ] Review and update admin password
- [ ] Audit all bookings and questionnaires
- [ ] Check storage usage across all services
- [ ] Review security logs

### Error Handling

Common errors and solutions:

**CORS Error:**
- Check `FRONTEND_URL` environment variable
- Ensure it includes your actual domain

**Database Connection Error:**
- Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY`
- Check if Supabase project is active

**Redis Connection Error:**
- Verify Upstash credentials
- Check if Redis database is active
- Test connection via Upstash console

**Email Not Sending:**
- Verify Gmail app password is correct
- Check if Gmail account has SMTP enabled
- Review Render logs for error details

---

## Disaster Recovery

### If Database Corrupted

1. Go to Supabase → Settings → Backups
2. Click "Restore from backup"
3. Select desired backup point
4. Confirm restoration

### If Redis Cache Lost

1. Not critical - Redis is only cache
2. Bookings still in Supabase
3. Rate limiting will reset
4. Upstash automatically recovers

### If API Crashes

1. Render monitors health endpoint
2. Automatic restart on failure
3. Check logs: Render → Logs
4. Manual restart: Render → Settings → Reboot

---

## Frontend Integration

### Update Frontend Files

In your HTML files (index_artistic.html, instructor-schedule.html):

Change API calls from localStorage to backend:

```javascript
// Old (localStorage):
const bookings = JSON.parse(localStorage.getItem('bookedSlots'));

// New (backend):
const response = await fetch('https://guitar-lesson-api.onrender.com/api/bookings', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ name, email, date, time, isFirstTime, deviceFingerprint })
});
```

### Deploy Frontend

Option 1: Render Static Site
1. Create "Static Site" service on Render
2. Connect same GitHub repo
3. Build command: (leave empty - static files)
4. Publish directory: `.` (or create `/public`)

Option 2: Custom Domain
1. Add domain via Render settings
2. Configure DNS records
3. Enable auto SSL

---

## Performance Optimization

### Caching Strategy

1. **Browser Cache**: Static files cached for 1 hour
2. **Redis Cache**: Slot availability cached for 24 hours
3. **Database Indexes**: Automatically optimized for queries

### CDN (Optional)

For even better performance, add Cloudflare:
1. Point domain to Cloudflare
2. Enable caching rules
3. Automatic optimization included

### Monitoring

Render provides:
- CPU usage
- Memory usage
- Request count
- Response times
- Error rates

Check these weekly to identify optimization needs.

---

## Rollback Procedure

If something goes wrong:

```bash
# Render automatically keeps previous builds
# Go to Render Dashboard → Deploys
# Click previous deployment → "Redeploy"
# Service will revert to previous version
```

---

## Scaling for Growth

When you outgrow current resources:

1. **Render**: Upgrade plan (Professional: $25/mo)
2. **Supabase**: Upgrade from $25/mo to higher tier
3. **Upstash**: Increase Redis memory if needed
4. **Add CDN**: Cloudflare for global distribution

---

## Support & Documentation

- **Render Docs**: https://render.com/docs
- **Supabase Docs**: https://supabase.com/docs
- **Upstash Docs**: https://upstash.com/docs
- **Express.js**: https://expressjs.com
- **Node.js**: https://nodejs.org/docs

---

## Security Checklist Before Going Live

- [ ] Changed `ADMIN_PASSWORD_HASH` to your own password
- [ ] Generated strong `JWT_SECRET`
- [ ] Configured `FRONTEND_URL` correctly
- [ ] Gmail app password created and stored
- [ ] Supabase RLS policies enabled
- [ ] Render auto-deployments enabled
- [ ] Custom domain configured with SSL
- [ ] Database backups tested
- [ ] Monitoring alerts set up
- [ ] All environment variables validated
- [ ] Load tested with 100+ simultaneous bookings
- [ ] Email notifications tested
- [ ] Admin dashboard password tested
- [ ] Device limits tested and verified

---

## Next Steps

1. Follow all steps above
2. Test thoroughly before advertising
3. Monitor logs for first week
4. Collect feedback from early users
5. Optimize based on performance data
6. Scale infrastructure as needed

**You now have a production-grade, secure, scalable booking platform!** 🚀

