# 🚀 Get Your Project to GitHub in 5 Minutes

**Step-by-step guide to find your files and push them to GitHub**

---

## WHERE ARE YOUR FILES?

All your project files are automatically saved here on your computer:

**Finder Path:**
```
~/Library/Application Support/Claude/local-agent-mode-sessions/
  → [session-folder]/agent/
    → local_ditto_[session-folder]/
      → outputs/
```

**Or simpler - open Terminal and paste this:**
```bash
open ~/Library/Application\ Support/Claude/local-agent-mode-sessions/*/agent/local_ditto_*/outputs/
```

This opens a Finder window showing ALL your files.

---

## QUICKEST WAY (5 minutes)

### Step 1: Open Terminal

```bash
# This one command opens your files in Finder
open ~/Library/Application\ Support/Claude/local-agent-mode-sessions/*/agent/local_ditto_*/outputs/
```

You'll see a Finder window with all your files:
- MASTER_DEPLOY.sh
- server.js
- package.json
- .env.example
- render.yaml
- supabase-setup.sql
- All HTML files
- All documentation

### Step 2: Create Project Folder

```bash
# In Terminal:
cd ~
mkdir -p Projects/guitar-lesson-booking
cd Projects/guitar-lesson-booking
```

### Step 3: Copy Files

**Option A: Drag & Drop (Easiest)**
1. Keep the Terminal window and Finder window open side by side
2. In Finder, select ALL files (Cmd+A)
3. Drag them to the `~/Projects/guitar-lesson-booking/` folder
4. Done!

**Option B: Terminal Command**
```bash
# Replace with actual path from step 1
cp -r ~/Library/Application\ Support/Claude/local-agent-mode-sessions/*/agent/local_ditto_*/outputs/* ~/Projects/guitar-lesson-booking/

# Verify they're there:
ls ~/Projects/guitar-lesson-booking/
# Should show: MASTER_DEPLOY.sh, server.js, package.json, etc.
```

### Step 4: Initialize Git & Push to GitHub

```bash
cd ~/Projects/guitar-lesson-booking

# Initialize Git
git init
git add .
git commit -m "Initial commit: Production guitar booking platform"

# Set up remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/guitar-lesson-booking.git

# Push to GitHub
git branch -M main
git push -u origin main
```

---

## COMPLETE WALKTHROUGH (If Above Doesn't Work)

### 1. Open Terminal

Click the Terminal icon in your Applications → Utilities, or press `Cmd + Space` and type "Terminal".

### 2. Find Your Files

```bash
# This command shows the exact path
echo ~/Library/Application\ Support/Claude/local-agent-mode-sessions/*/agent/local_ditto_*/outputs/

# This opens Finder to that location
open ~/Library/Application\ Support/Claude/local-agent-mode-sessions/*/agent/local_ditto_*/outputs/
```

You'll see a Finder window with all your files. **Keep this open.**

### 3. Create Project Folder on Your Computer

```bash
# Create folder
mkdir -p ~/Projects/guitar-lesson-booking

# Navigate into it
cd ~/Projects/guitar-lesson-booking

# Verify you're in the right place
pwd
# Should show: /Users/jcunningham/Projects/guitar-lesson-booking
```

### 4. Copy All Files

**Easy way - Drag & Drop:**
1. In Finder (from step 2), select all files: `Cmd + A`
2. Drag them into the `guitar-lesson-booking` folder you just created
3. Wait for copy to finish
4. Done!

**Terminal way:**
```bash
# Copy all files
cp -r ~/Library/Application\ Support/Claude/local-agent-mode-sessions/*/agent/local_ditto_*/outputs/* ~/Projects/guitar-lesson-booking/

# Check they copied
cd ~/Projects/guitar-lesson-booking
ls -la

# Should show (among others):
# MASTER_DEPLOY.sh
# server.js
# package.json
# render.yaml
# index_artistic.html
# etc.
```

### 5. Create GitHub Repository

```bash
# Go to https://github.com/new
# Fill in:
# - Repository name: guitar-lesson-booking
# - Description: Professional guitar lesson booking platform
# - Set to PRIVATE
# - Click "Create repository"
# - DO NOT initialize with README, .gitignore, or license

# You'll see instructions. Come back to Terminal and run:
```

### 6. Connect to GitHub

```bash
cd ~/Projects/guitar-lesson-booking

# Initialize Git
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit: Production guitar booking platform"

# Add remote (replace YOUR_USERNAME with your actual GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/guitar-lesson-booking.git

# Rename branch to main if needed
git branch -M main

# Push to GitHub
git push -u origin main

# Verify it worked
git remote -v
# Should show your GitHub URL
```

### 7. Connect to Render

```bash
# Go to https://render.com
# Click "New" → "Web Service"
# Click "Connect GitHub account"
# Authorize Render
# Select your repository: guitar-lesson-booking
# Click "Connect"
# Configure and deploy!
```

---

## FIND YOUR FILES - VISUAL GUIDE

**On your Mac, use Finder:**

1. Press `Cmd + Shift + G` (Go to Folder)
2. Paste this:
```
~/Library/Application Support/Claude/local-agent-mode-sessions
```
3. Press Enter
4. Navigate: Look for a folder, open it → "agent" folder → "local_ditto_..." folder → "outputs" folder
5. **This is where all your files are!**

---

## GITHUB SETUP QUICK REFERENCE

### If you need to find your GitHub username:
1. Go to https://github.com
2. Click your profile icon (top right)
3. Click "Your profile"
4. Look at the URL: `https://github.com/YOUR_USERNAME`

### Replace YOUR_USERNAME in this command:
```bash
git remote add origin https://github.com/YOUR_USERNAME/guitar-lesson-booking.git
```

### Example:
If your GitHub username is "jacobcunningham", it would be:
```bash
git remote add origin https://github.com/jacobcunningham/guitar-lesson-booking.git
```

---

## VERIFY IT WORKED

After pushing to GitHub, check:

```bash
# 1. Check git status
git status
# Should say: "On branch main" and "nothing to commit"

# 2. Check remote
git remote -v
# Should show your GitHub URL

# 3. Go to GitHub website
# Visit: https://github.com/YOUR_USERNAME/guitar-lesson-booking
# Should see all your files there!
```

---

## IF SOMETHING GOES WRONG

**"fatal: not a git repository"**
```bash
# Make sure you're in the right folder
cd ~/Projects/guitar-lesson-booking
pwd  # Should show that path

# Then try again
git init
```

**"fatal: could not read Username"**
```bash
# You need to authenticate with GitHub
# GitHub asks for your password - use a Personal Access Token instead
# Go to: https://github.com/settings/tokens
# Click "Generate new token (classic)"
# Check: repo, write:packages, read:packages
# Copy the token
# When git asks for password, paste the token
```

**"Permission denied (publickey)"**
```bash
# You need SSH keys or HTTPS authentication
# Easier: use HTTPS (what we're doing above)
# When prompted for password, use Personal Access Token (see above)
```

**"fatal: remote origin already exists"**
```bash
# Remove the old remote and add new one
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/guitar-lesson-booking.git
```

---

## DONE!

Once you see your files on GitHub:
1. Go to https://render.com
2. Click "New" → "Web Service"
3. Click "Connect GitHub account"
4. Select your repository
5. Render auto-deploys on every push! 🚀

---

## TLDR - COPY & PASTE COMMANDS

```bash
# 1. Create folder
mkdir -p ~/Projects/guitar-lesson-booking
cd ~/Projects/guitar-lesson-booking

# 2. Copy files (this finds them automatically)
cp -r ~/Library/Application\ Support/Claude/local-agent-mode-sessions/*/agent/local_ditto_*/outputs/* .

# 3. Setup Git
git init
git add .
git commit -m "Initial commit: Production guitar booking platform"

# 4. Connect to GitHub (REPLACE YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/guitar-lesson-booking.git
git branch -M main
git push -u origin main

# 5. Done! Check GitHub website to verify
```

**That's it! Files are now on GitHub and ready for Render!** 🎸✨

---

## NEXT: CONNECT TO RENDER

Once files are on GitHub:

1. Go to https://render.com
2. Click "New" → "Web Service"
3. Click "Connect GitHub account" → Authorize
4. Select repository: guitar-lesson-booking
5. Click "Connect"
6. Configure:
   - Name: guitar-lesson-api
   - Build Command: npm install
   - Start Command: node server.js
   - Plan: Standard ($7/month)
7. Add Environment Variables (from your .env file)
8. Click "Create Web Service"
9. Watch deployment complete
10. Get your live API URL!

Your platform goes live! 🚀
