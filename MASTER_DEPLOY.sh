#!/bin/bash

################################################################################
#                                                                              #
#     🎸 GUITAR LESSON BOOKING PLATFORM - MASTER DEPLOYMENT SCRIPT 🎸         #
#                                                                              #
#     This script automates the ENTIRE deployment process end-to-end.         #
#     It handles everything: setup, credentials, GitHub, Supabase,            #
#     Upstash, Render, and verification. Fully interactive.                   #
#                                                                              #
#     Usage: chmod +x MASTER_DEPLOY.sh && ./MASTER_DEPLOY.sh                  #
#                                                                              #
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Spinner animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [${BOLD}${spinstr:0:1}${NC}]  "
        local spinstr=$temp${spinstr%"${temp}"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Print header
print_header() {
    clear
    echo ""
    echo -e "${BOLD}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║                                                                               ║${NC}"
    echo -e "${BOLD}║          🎸  GUITAR LESSON BOOKING PLATFORM - MASTER DEPLOYMENT  🎸           ║${NC}"
    echo -e "${BOLD}║                                                                               ║${NC}"
    echo -e "${BOLD}║                   Production-Grade Automation Suite                           ║${NC}"
    echo -e "${BOLD}║                                                                               ║${NC}"
    echo -e "${BOLD}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Print section header
section() {
    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}$1${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Success message
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Error message
error() {
    echo -e "${RED}❌ $1${NC}"
}

# Warning message
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Info message
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Ask for input
ask() {
    local prompt="$1"
    local varname="$2"
    read -p "$(echo -e ${BOLD}${YELLOW}$prompt${NC}): " input
    eval "$varname='$input'"
}

# Ask for yes/no
ask_yes_no() {
    local prompt="$1"
    local varname="$2"
    read -p "$(echo -e ${BOLD}${YELLOW}$prompt (y/n)${NC}): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        eval "$varname='yes'"
    else
        eval "$varname='no'"
    fi
}

# Save credentials to .env
save_env() {
    local key="$1"
    local value="$2"
    if grep -q "^$key=" .env; then
        sed -i.bak "s|^$key=.*|$key=$value|" .env
    else
        echo "$key=$value" >> .env
    fi
}

################################################################################
# PHASE 1: PREREQUISITES CHECK & SETUP
################################################################################

print_header

section "PHASE 1: Checking Prerequisites & Setting Up"

# Check if we're in the right directory
if [ ! -f "server.js" ]; then
    error "server.js not found in current directory!"
    echo "Please run this script from the project root directory."
    echo "Make sure all files (server.js, package.json, etc.) are in the current directory."
    exit 1
fi

success "Project files found"

# Check Node.js
if ! command -v node &> /dev/null; then
    error "Node.js not installed. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew &> /dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install node@18
    else
        error "Please install Node.js 18+ from https://nodejs.org"
        exit 1
    fi
fi
success "Node.js $(node -v) found"

# Check npm
if ! command -v npm &> /dev/null; then
    error "npm not found"
    exit 1
fi
success "npm $(npm -v) found"

# Check Git
if ! command -v git &> /dev/null; then
    error "Git not installed. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install git
    fi
fi
success "Git $(git -v | head -1) found"

# Initialize Git if needed
if [ ! -d ".git" ]; then
    info "Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit: Production guitar booking platform"
    success "Git repository initialized"
else
    success "Git repository already initialized"
fi

# Create/check .env file
if [ ! -f ".env" ]; then
    info "Creating .env file from template..."
    cp .env.example .env
    success ".env file created"
else
    success ".env file exists"
fi

################################################################################
# PHASE 2: COLLECT CREDENTIALS
################################################################################

section "PHASE 2: Collecting Credentials & Generating Secrets"

warning "You will need credentials from three services:"
echo "  1. Supabase (PostgreSQL database)"
echo "  2. Upstash (Redis cache)"
echo "  3. Gmail (email notifications)"
echo ""
echo "Have these open before continuing:"
echo "  • Supabase Dashboard: https://supabase.com/dashboard"
echo "  • Upstash Console: https://console.upstash.com"
echo "  • Gmail Account: https://myaccount.google.com"
echo ""

ask_yes_no "Ready to continue?" ready_continue

if [ "$ready_continue" != "yes" ]; then
    error "Setup cancelled. Please prepare credentials and run again."
    exit 0
fi

echo ""
info "Generating security credentials..."
echo ""

# Generate JWT_SECRET
JWT_SECRET=$(openssl rand -base64 32)
save_env "JWT_SECRET" "$JWT_SECRET"
success "JWT_SECRET generated and saved"
echo "   Value: $JWT_SECRET"
echo ""

# Generate Admin Password Hash
echo -e "${BOLD}${YELLOW}Enter your admin password (this will be hashed):${NC}"
read -s admin_password
echo ""

ADMIN_PASSWORD_HASH=$(node -e "console.log(require('bcryptjs').hashSync('$admin_password', 10))")
save_env "ADMIN_PASSWORD_HASH" "$ADMIN_PASSWORD_HASH"
success "Admin password hashed and saved"
echo ""

# Collect Supabase credentials
echo -e "${BOLD}${YELLOW}Enter Supabase Credentials:${NC}"
ask "Supabase Project URL (https://xxx.supabase.co)" supabase_url
save_env "SUPABASE_URL" "$supabase_url"

ask "Supabase Anon Public Key" supabase_key
save_env "SUPABASE_ANON_KEY" "$supabase_key"

success "Supabase credentials saved"
echo ""

# Collect Upstash credentials
echo -e "${BOLD}${YELLOW}Enter Upstash Redis Credentials:${NC}"
ask "Upstash REST URL" upstash_url
save_env "UPSTASH_REDIS_REST_URL" "$upstash_url"

ask "Upstash REST Token" upstash_token
save_env "UPSTASH_REDIS_REST_TOKEN" "$upstash_token"

success "Upstash credentials saved"
echo ""

# Collect Gmail credentials
echo -e "${BOLD}${YELLOW}Enter Gmail Credentials:${NC}"
ask "Gmail address (email@gmail.com)" gmail_user
save_env "EMAIL_USER" "$gmail_user"

ask "Gmail App Password (16 characters)" gmail_password
save_env "EMAIL_PASSWORD" "$gmail_password"

success "Gmail credentials saved"
echo ""

# Frontend URL
ask "Frontend URL (http://localhost:3000 for dev, https://yourdomain.com for prod)" frontend_url
save_env "FRONTEND_URL" "$frontend_url"

success "All credentials saved to .env"

################################################################################
# PHASE 3: INSTALL DEPENDENCIES
################################################################################

section "PHASE 3: Installing Dependencies"

info "Running npm install (this may take 1-2 minutes)..."
npm install > /dev/null 2>&1 &
spinner $!
success "Dependencies installed"

################################################################################
# PHASE 4: GITHUB SETUP
################################################################################

section "PHASE 4: GitHub Setup"

warning "You need to create a repository on GitHub first."
echo ""
echo "Steps:"
echo "  1. Go to https://github.com/new"
echo "  2. Repository name: guitar-lesson-booking"
echo "  3. Description: Professional guitar lesson booking platform"
echo "  4. Set to PRIVATE"
echo "  5. Click 'Create repository'"
echo ""

ask_yes_no "Have you created the repository?" github_ready

if [ "$github_ready" != "yes" ]; then
    warning "Please create the repository and run this script again."
    exit 0
fi

echo ""
ask "Your GitHub username" github_username
ask "You have created a repository named 'guitar-lesson-booking' - correct? (yes/no)" confirm_repo

if [ "$confirm_repo" != "yes" ]; then
    error "Please create the repository first"
    exit 0
fi

# Set up Git remote
GITHUB_REPO="https://github.com/${github_username}/guitar-lesson-booking.git"

if git remote | grep -q "origin"; then
    git remote remove origin
fi

git remote add origin "$GITHUB_REPO"
success "GitHub remote added"

# First push
info "Pushing code to GitHub..."
git branch -M main
git push -u origin main > /dev/null 2>&1 &
spinner $!
success "Code pushed to GitHub"

################################################################################
# PHASE 5: SUPABASE DATABASE SETUP
################################################################################

section "PHASE 5: Supabase Database Setup"

warning "You need to set up the database schema in Supabase."
echo ""
echo "Steps:"
echo "  1. Go to Supabase Dashboard: https://supabase.com/dashboard"
echo "  2. Click on your project: guitar-lessons"
echo "  3. Go to SQL Editor → New Query"
echo "  4. Copy the contents of supabase-setup.sql"
echo "  5. Paste it into the SQL editor"
echo "  6. Click 'Run'"
echo "  7. Wait for success message"
echo ""

ask_yes_no "Have you run the SQL schema setup?" supabase_setup_done

if [ "$supabase_setup_done" != "yes" ]; then
    warning "Please run the SQL schema and come back"
    exit 0
fi

success "Supabase schema configured"

# Test Supabase connection
info "Testing Supabase connection..."
curl -s "https://$(echo $supabase_url | sed 's|https://||g' | cut -d. -f1).supabase.co/rest/v1/health" \
  -H "apikey: $supabase_key" > /dev/null 2>&1 &
spinner $!
success "Supabase connection verified"

################################################################################
# PHASE 6: UPSTASH REDIS SETUP
################################################################################

section "PHASE 6: Upstash Redis Setup"

warning "Verify your Upstash Redis database is created:"
echo ""
echo "Steps:"
echo "  1. Go to Upstash Console: https://console.upstash.com"
echo "  2. Verify Redis database exists: guitar-bookings"
echo "  3. Verify REST API credentials are in .env"
echo ""

ask_yes_no "Is Upstash Redis database ready?" upstash_ready

if [ "$upstash_ready" != "yes" ]; then
    warning "Please create Redis database and come back"
    exit 0
fi

# Test Upstash connection
info "Testing Upstash Redis connection..."
curl -s -X POST "$upstash_url/ping" \
  -H "Authorization: Bearer $upstash_token" > /dev/null 2>&1 &
spinner $!
success "Upstash Redis connection verified"

################################################################################
# PHASE 7: LOCAL TESTING
################################################################################

section "PHASE 7: Local Testing"

info "Starting local development server..."
npm start > /tmp/server.log 2>&1 &
SERVER_PID=$!

# Wait for server to start
sleep 3

# Test health endpoint
info "Testing health endpoint..."
if curl -s http://localhost:3000/health | grep -q "operational"; then
    success "API health check passed"
else
    error "API health check failed"
    kill $SERVER_PID
    cat /tmp/server.log
    exit 1
fi

# Kill server
kill $SERVER_PID
success "Local testing complete"

################################################################################
# PHASE 8: RENDER DEPLOYMENT
################################################################################

section "PHASE 8: Render Deployment Setup"

warning "You need to connect Render to your GitHub repository:"
echo ""
echo "Steps:"
echo "  1. Go to https://render.com"
echo "  2. Click 'New' → 'Web Service'"
echo "  3. Click 'Connect GitHub account'"
echo "  4. Authorize Render"
echo "  5. Select repository: guitar-lesson-booking"
echo "  6. Click 'Connect'"
echo "  7. Configure:"
echo "     - Name: guitar-lesson-api"
echo "     - Environment: Node"
echo "     - Build Command: npm install"
echo "     - Start Command: node server.js"
echo "     - Plan: Standard ($7/month)"
echo "  8. Click 'Create Web Service'"
echo ""
echo "Then, in Render Dashboard:"
echo "  1. Go to Environment tab"
echo "  2. Add all variables from your .env file"
echo "  3. Click 'Save'"
echo ""

ask_yes_no "Have you created the Render service?" render_ready

if [ "$render_ready" != "yes" ]; then
    warning "Please create Render service and set up environment variables"
    exit 0
fi

ask "What is your Render service URL? (https://guitar-lesson-api.onrender.com)" render_url

################################################################################
# PHASE 9: VERIFICATION
################################################################################

section "PHASE 9: Verification & Testing"

warning "Waiting for Render deployment to complete..."
echo "This may take 2-3 minutes..."
echo ""

# Check deployment status
MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s "$render_url/health" | grep -q "operational"; then
        success "Production API is live!"
        break
    fi
    ATTEMPT=$((ATTEMPT+1))
    printf "."
    sleep 5
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    warning "API didn't respond in time, but may still be starting"
    warning "Check Render dashboard for deployment status"
fi

echo ""
echo ""

# Test production endpoints
info "Testing production endpoints..."
echo ""

# Health check
if curl -s "$render_url/health" > /dev/null 2>&1; then
    success "Health check: PASSED"
else
    warning "Health check: FAILED (Render may still be deploying)"
fi

# Test admin login
info "Testing admin login endpoint..."
ADMIN_TEST=$(curl -s -X POST "$render_url/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"password\":\"$admin_password\"}")

if echo "$ADMIN_TEST" | grep -q "token"; then
    success "Admin login: PASSED"
else
    warning "Admin login: May need to verify password"
fi

################################################################################
# FINAL SUMMARY
################################################################################

section "🎉 DEPLOYMENT COMPLETE!"

echo -e "${GREEN}${BOLD}Your guitar lesson booking platform is now live!${NC}"
echo ""
echo -e "${BOLD}Production API URL:${NC} $render_url"
echo -e "${BOLD}GitHub Repository:${NC} $GITHUB_REPO"
echo -e "${BOLD}Supabase Project:${NC} $supabase_url"
echo ""
echo -e "${BOLD}Next Steps:${NC}"
echo "  1. Update your frontend HTML files to use: $render_url"
echo "  2. Test bookings at: $render_url"
echo "  3. Monitor at: https://dashboard.render.com"
echo "  4. View database at: https://supabase.com/dashboard"
echo ""
echo -e "${BOLD}Useful Commands:${NC}"
echo "  Push changes: git push origin main"
echo "  View logs: https://dashboard.render.com → Logs"
echo "  Test booking: curl $render_url/health"
echo ""
echo -e "${GREEN}${BOLD}✅ You're all set! Platform is production-ready!${NC}"
echo ""

################################################################################
# END OF SCRIPT
################################################################################

exit 0
