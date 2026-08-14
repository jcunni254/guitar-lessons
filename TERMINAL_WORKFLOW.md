# Terminal Workflow Guide
## Complete Step-by-Step for Deployment

This guide covers every command you need to type in your terminal to deploy the platform completely.

---

## 📋 Table of Contents

1. [Initial Setup](#initial-setup)
2. [GitHub Configuration](#github-configuration)
3. [Generating Security Credentials](#generating-security-credentials)
4. [Local Development](#local-development)
5. [Supabase Setup](#supabase-setup)
6. [Upstash Configuration](#upstash-configuration)
7. [Render Deployment](#render-deployment)
8. [Testing & Verification](#testing--verification)
9. [Common Commands Reference](#common-commands-reference)

---

## Initial Setup

### Step 1: Create a Project Directory

```bash
# Navigate to where you want the project
cd ~/Projects  # or any directory you prefer

# Create project folder
mkdir guitar-lesson-booking
cd guitar-lesson-booking

# Initialize as Git repository
git init
```

### Step 2: Copy All Files

Copy all the generated files (server.js, package.json, HTML files, etc.) to this directory.

```bash
# Check what you have
ls -la

# You should see:
# - server.js
# - package.json
# - .env.example
# - .gitignore
# - render.yaml
# - supabase-setup.sql
# - index_artistic.html
# - instructor-schedule.html
# - questionnaire.html
```

### Step 3: Run Setup Script

```bash
# Make the setup script executable
chmod +x LOCAL_SETUP.sh

# Run it
./LOCAL_SETUP.sh

# This will:
# ✅ Check Node.js installation
# ✅ Install npm dependencies
# ✅ Create .env file from template
# ✅ Give you next steps
```

---

## GitHub Configuration

### Step 1: Initialize GitHub Repository

```bash
# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Production guitar booking platform"

# Show current branch (should be 'master' or 'main')
git branch

# If on 'master', rename to 'main'
git branch -M main
```

### Step 2: Create GitHub Repository (via Web Browser)

1. Go to https://github.com/new
2. Repository name: `guitar-lesson-booking`
3. Description: `Professional guitar lesson booking platform with Supabase and Redis`
4. Set to **Private** (unless you want it public)
5. Initialize with README: **Unchecked** (we already have files)
6. Click "Create repository"

### Step 3: Connect Local to GitHub

After creating on GitHub, you'll see commands like these. Copy-paste them:

```bash
# Add remote (replace with YOUR username and repo)
git remote add origin https://github.com/yourusername/guitar-lesson-booking.git

# Verify it's connected
git remote -v
# Should show:
# origin  https://github.com/yourusername/guitar-lesson-booking.git (fetch)
# origin  https://github.com/yourusername/guitar-lesson-booking.git (push)

# Push code to GitHub
git branch -M main
git push -u origin main

# Verify push succeeded
git log --oneline
```

---

## Generating Security Credentials

### Step 1: Generate JWT Secret

This is a random key for token signing. Run this in terminal:

```bash
# Generate 32-byte random secret
openssl rand -base64 32

# Output will look like:
# rF8+3xK9mL2nP5q8vJ0sT1uW4yZ6aB7c8dE9fG0hI1jK2l=

# Copy this value
```

### Step 2: Generate Admin Password Hash

First, decide your admin password (example: `Guitar123!Strong`):

```bash
# Create hash (replace with YOUR password)
node -e "console.log(require('bcryptjs').hashSync('Guitar123!Strong', 10))"

# Output will look like:
# $2a$10$abcdefghijklmnopqrstuvwxyzABCDEFGHIJ...

# Copy this value
```

### Step 3: Generate Gmail App Password

1. Go to https://myaccount.google.com/security
2. Enable "2-Step Verification" if not enabled
3. Search for "App passwords"
4. Select Mail and Windows Computer
5. Copy the generated password (16 characters)

### Step 4: Update .env File

```bash
# Open .env in your editor
nano .env

# Or use your preferred editor (code, vim, etc.)
code .env

# Fill in these values:
# SUPABASE_URL=https://your-project.supabase.co
# SUPABASE_ANON_KEY=your-anon-key
# UPSTASH_REDIS_REST_URL=https://your-url.upstash.io
# UPSTASH_REDIS_REST_TOKEN=your-token
# JWT_SECRET=rF8+3xK9mL2nP5q8vJ0sT1uW4yZ6aB7c8dE9fG0hI1jK2l=
# ADMIN_PASSWORD_HASH=$2a$10$abcdefghijklmnopqrstuvwxyzABCDEFGHIJ...
# EMAIL_USER=your-gmail@gmail.com
# EMAIL_PASSWORD=your-app-password-16chars
# FRONTEND_URL=http://localhost:3000,https://yourdomain.com
# NODE_ENV=production

# Save and exit (Ctrl+X then Y then Enter in nano)
```

---

## Local Development

### Start Development Server

```bash
# Terminal 1: Start backend API
npm run dev

# Output should show:
# ╔═══════════════════════════════════════════════════════╗
# ║     🎸 Guitar Lesson Booking Platform - Server       ║
# ║     Environment: development                         ║
# ║     Port: 3000                                        ║
# ║     Status: ✅ Running                                ║
# ╚═══════════════════════════════════════════════════════╝
```

### In Another Terminal: Serve Frontend

```bash
# Terminal 2: Serve frontend files (macOS/Linux)
python3 -m http.server 8000

# Or on Windows:
python -m http.server 8000

# Output shows:
# Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...

# Visit: http://localhost:8000
```

### Test Health Endpoint

```bash
# Terminal 3: Test API
curl http://localhost:3000/health

# Should return:
# {"status":"operational","timestamp":"2024-01-15T...","uptime":...}
```

---

## Supabase Setup

### Step 1: Create Project

Visit https://supabase.com and create account, then:

```bash
# In terminal, generate a strong database password
openssl rand -32 | base64
# Copy this password - you'll need it in Supabase dashboard
```

### Step 2: Run Database Migrations

In Supabase dashboard:

1. Go to SQL Editor
2. Click "New Query"
3. Paste contents of `supabase-setup.sql`
4. Click "Run"

Or via terminal (if Supabase CLI is installed):

```bash
# Install Supabase CLI
npm install -g supabase

# Initialize Supabase project
supabase link --project-ref your-project-ref

# Run migrations
supabase migration up
```

### Step 3: Get API Keys

In Supabase Settings → API:

```bash
# Save these to your .env file
SUPABASE_URL=https://xxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...xxxxx

# Then update .env
nano .env
```

### Step 4: Verify Database

```bash
# Test connection from terminal
curl -X GET "https://your-project.supabase.co/rest/v1/bookings" \
  -H "apikey: your-anon-key" \
  -H "Authorization: Bearer your-anon-key"

# Should return: []  (empty array means success)
```

---

## Upstash Configuration

### Step 1: Create Redis Database

Visit https://upstash.com, create account, then:

1. Click "Create Database"
2. Name: `guitar-bookings`
3. Region: Select closest to you
4. Click "Create"

### Step 2: Get Connection Details

In Upstash console, go to "REST API":

```bash
# Copy these values to .env
UPSTASH_REDIS_REST_URL=https://your-url.upstash.io
UPSTASH_REDIS_REST_TOKEN=your-token-here

# Update .env
nano .env
```

### Step 3: Test Connection

```bash
# Test Redis connection
curl -X POST https://your-url.upstash.io/ping \
  -H "Authorization: Bearer your-token"

# Should return: PONG
```

---

## Render Deployment

### Step 1: Push Latest Code

```bash
# Make sure everything is committed
git status

# If changes, commit them
git add .
git commit -m "Add environment configuration"

# Push to GitHub
git push origin main
```

### Step 2: Create Render Service

Visit https://render.com:

1. Click "New" → "Web Service"
2. Click "Connect account" (authorize GitHub)
3. Select repository: `guitar-lesson-booking`
4. Click "Connect"

### Step 3: Configure Service

```bash
# In Render Dashboard:
Name: guitar-lesson-api
Environment: Node
Build Command: npm install
Start Command: node server.js
Plan: Standard ($7/month)

# Click "Create Web Service"
```

### Step 4: Add Environment Variables

In Render dashboard, go to Environment and add all from your .env:

```bash
# Via terminal, display your .env for reference
cat .env

# Then add each to Render manually (or via dashboard)
```

### Step 5: Trigger Deploy

```bash
# Push a commit to trigger deploy
echo "Deployment config ready" >> README.md
git add README.md
git commit -m "Trigger Render deployment"
git push origin main

# Watch deployment on Render dashboard
# Once complete, you'll get URL: https://guitar-lesson-api.onrender.com
```

---

## Testing & Verification

### Test 1: Health Check

```bash
# Check if API is running
curl https://guitar-lesson-api.onrender.com/health

# Should return:
# {"status":"operational",...}
```

### Test 2: Admin Login

```bash
# Test authentication
curl -X POST https://guitar-lesson-api.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"password":"Guitar123!Strong"}'

# Should return auth token
```

### Test 3: Create Booking

```bash
# Test booking creation
curl -X POST https://guitar-lesson-api.onrender.com/api/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "phone": "555-1234",
    "date": "2024-02-15",
    "time": "10:00 AM",
    "isFirstTime": true,
    "deviceFingerprint": "test-device-123"
  }'

# Should return booking confirmation
```

### Test 4: Verify Database

```bash
# Check bookings in Supabase
# Go to Supabase dashboard → bookings table
# You should see your test booking

# Or via terminal:
curl -X GET "https://your-project.supabase.co/rest/v1/bookings" \
  -H "apikey: your-anon-key" \
  -H "Authorization: Bearer your-anon-key"
```

### Test 5: Rate Limiting

```bash
# Test rate limiting (should fail on 6th request)
for i in {1..10}; do
  curl -X POST https://guitar-lesson-api.onrender.com/api/bookings \
    -H "Content-Type: application/json" \
    -d '{"name":"Test","email":"test@example.com","date":"2024-02-15","time":"10:00 AM","isFirstTime":true,"deviceFingerprint":"test-device"}' \
    -w "\n%{http_code}\n"
  sleep 1
done

# After 5 requests, should get: 429 (Too Many Requests)
```

---

## Common Commands Reference

### Git Commands

```bash
# Check status
git status

# View commit history
git log --oneline

# Add all changes
git add .

# Commit changes
git commit -m "Your message"

# Push to GitHub
git push origin main

# Pull latest changes
git pull origin main

# Create new branch
git checkout -b feature-name

# Switch branches
git checkout main

# Delete branch
git branch -d feature-name
```

### Node/npm Commands

```bash
# Install dependencies
npm install

# Install specific package
npm install package-name

# Update dependencies
npm update

# Start development server
npm run dev

# Start production server
npm start

# Check for outdated packages
npm outdated

# Audit for security issues
npm audit

# Fix security issues
npm audit fix
```

### Database Commands

```bash
# Test Supabase connection
curl https://your-project.supabase.co/rest/v1/health \
  -H "apikey: your-anon-key"

# Test Redis connection
curl -X POST https://your-url.upstash.io/ping \
  -H "Authorization: Bearer your-token"

# View logs (if using Supabase CLI)
supabase logs
```

### API Testing Commands

```bash
# Health check
curl http://localhost:3000/health

# Get all bookings (with auth)
curl -X GET http://localhost:3000/api/admin/bookings \
  -H "Authorization: Bearer your-jwt-token"

# Check slot availability
curl -X POST http://localhost:3000/api/check-availability \
  -H "Content-Type: application/json" \
  -d '{"date":"2024-02-15","time":"10:00 AM"}'
```

### Useful Utility Commands

```bash
# Generate random string
openssl rand -base64 32

# Check if port is in use
lsof -i :3000

# Kill process on port 3000
kill -9 $(lsof -t -i:3000)

# View environment variables
printenv

# Check Node version
node -v

# Check npm version
npm -v

# View file contents
cat .env

# Edit file (nano)
nano .env

# List files with details
ls -la
```

---

## Troubleshooting Commands

### If Backend Won't Start

```bash
# Check if port 3000 is already in use
lsof -i :3000

# Kill existing process
kill -9 $(lsof -t -i:3000)

# Try starting again
npm start

# Check Node version (should be 18+)
node -v
```

### If Can't Connect to Supabase

```bash
# Verify .env has correct values
cat .env | grep SUPABASE

# Test connection
curl https://your-project.supabase.co/rest/v1/health \
  -H "apikey: your-anon-key"
```

### If Can't Connect to Redis

```bash
# Verify .env has correct values
cat .env | grep UPSTASH

# Test connection
curl -X POST https://your-url.upstash.io/ping \
  -H "Authorization: Bearer your-token"
```

### View Application Logs

```bash
# Local development logs (shown in terminal where npm run dev is running)
# Ctrl+C to stop

# Render production logs
# View in Render dashboard → Logs

# Supabase logs
# View in Supabase dashboard → Database → Logs
```

---

## Complete Deployment Checklist

```bash
# Run this checklist to deploy completely:

# 1. Setup ✅
./LOCAL_SETUP.sh

# 2. Create credentials
openssl rand -base64 32  # JWT_SECRET
node -e "console.log(require('bcryptjs').hashSync('YourPassword', 10))"  # ADMIN_PASSWORD_HASH

# 3. Update .env
nano .env

# 4. Test locally
npm run dev
# In another terminal: curl http://localhost:3000/health

# 5. Push to GitHub
git add .
git commit -m "Production ready"
git push origin main

# 6. Deploy to Render
# (Set environment variables in Render dashboard)
# (Push triggers automatic deploy)

# 7. Test production
curl https://guitar-lesson-api.onrender.com/health

# 8. Verify database
# Check Supabase dashboard for bookings table

# 9. Monitor
# Watch Render logs: https://dashboard.render.com
# Watch Supabase: https://supabase.com/dashboard
```

---

## Quick Reference Card

Print this or keep in terminal:

```bash
# Development
npm run dev                 # Start dev server
npm start                   # Start prod server

# Deployment
git push origin main        # Deploy to Render
git status                  # Check uncommitted changes

# Testing
curl http://localhost:3000/health     # Test local API
curl https://your-api.onrender.com/health  # Test production

# Credentials
openssl rand -base64 32    # Generate JWT secret
node -e "console.log(require('bcryptjs').hashSync('pw', 10))"  # Hash password

# Files
nano .env                   # Edit environment variables
cat .env                    # View environment variables
ls -la                      # List all files
```

---

## Support

If you get stuck, check:

1. **Terminal output** - Error messages are usually clear
2. **Service status** - All three must be running:
   - Render API (check dashboard)
   - Supabase (check dashboard)
   - Upstash Redis (check dashboard)
3. **Environment variables** - Most errors come from wrong/missing .env values
4. **Network** - Make sure internet is connected for API calls

All commands in this guide are copy-paste ready! 🚀

