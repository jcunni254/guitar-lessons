#!/bin/bash

# ==================== GUITAR LESSON BOOKING PLATFORM ====================
# Local Development Setup Script
# Run this script to set up your development environment completely
# chmod +x LOCAL_SETUP.sh && ./LOCAL_SETUP.sh

set -e  # Exit on error

echo "╔═══════════════════════════════════════════════════════╗"
echo "║   🎸 Guitar Lesson Booking Platform - Local Setup    ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# ==================== CHECK PREREQUISITES ====================
echo "📋 Checking prerequisites..."

# Check if Homebrew is installed (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "✅ Homebrew found"
    fi
fi

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not installed. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install node@18
    else
        echo "Please install Node.js 18+ from https://nodejs.org"
        exit 1
    fi
else
    NODE_VERSION=$(node -v)
    echo "✅ Node.js $NODE_VERSION found"
fi

# Check npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm not found"
    exit 1
else
    NPM_VERSION=$(npm -v)
    echo "✅ npm $NPM_VERSION found"
fi

# Check Git
if ! command -v git &> /dev/null; then
    echo "❌ Git not installed. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install git
    fi
else
    GIT_VERSION=$(git --version)
    echo "✅ $GIT_VERSION found"
fi

echo ""
echo "📦 Installing dependencies..."
npm install

echo ""
echo "🔑 Setting up environment variables..."

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "✅ .env file created (edit with your credentials)"
    echo ""
    echo "⚠️  IMPORTANT: Update .env with your credentials:"
    echo "   - SUPABASE_URL"
    echo "   - SUPABASE_ANON_KEY"
    echo "   - UPSTASH_REDIS_REST_URL"
    echo "   - UPSTASH_REDIS_REST_TOKEN"
    echo "   - JWT_SECRET (generate: openssl rand -base64 32)"
    echo "   - ADMIN_PASSWORD_HASH (see instructions below)"
    echo "   - EMAIL_USER & EMAIL_PASSWORD"
    echo "   - FRONTEND_URL"
else
    echo "✅ .env file already exists"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║           🎉 Setup Complete!                         ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "📖 Next Steps:"
echo ""
echo "1️⃣  GENERATE JWT SECRET:"
echo "   openssl rand -base64 32"
echo "   Add to .env as JWT_SECRET"
echo ""
echo "2️⃣  GENERATE ADMIN PASSWORD HASH:"
echo "   node -e \"console.log(require('bcryptjs').hashSync('YourPassword123!', 10))\""
echo "   Add to .env as ADMIN_PASSWORD_HASH"
echo ""
echo "3️⃣  CONFIGURE .env WITH YOUR CREDENTIALS:"
echo "   nano .env  (or use your preferred editor)"
echo ""
echo "4️⃣  START DEVELOPMENT SERVER:"
echo "   npm run dev"
echo ""
echo "5️⃣  OR START PRODUCTION SERVER:"
echo "   npm start"
echo ""
echo "✅ Your API will run at: http://localhost:3000"
echo "✅ Health check: curl http://localhost:3000/health"
echo ""
