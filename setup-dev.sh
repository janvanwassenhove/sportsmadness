#!/bin/bash

# Hockey Madness Development Setup Script

echo "🏒 Setting up Hockey Madness development environment..."

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Please install it first:"
    echo "npm install -g supabase"
    echo "Or visit: https://supabase.com/docs/guides/cli"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js 18+ first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Navigate to project root
cd "$(dirname "$0")"

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
cd apps/frontend
npm install

# Go back to project root
cd ../..

# Initialize Supabase (if not already done)
if [ ! -d "supabase/.git" ]; then
    echo "🗄️  Initializing Supabase project..."
    cd supabase
    supabase init
    cd ..
fi

# Start Supabase services
echo "🚀 Starting Supabase services..."
cd supabase
supabase start

# Apply migrations
echo "📝 Applying database migrations..."
supabase db reset

echo ""
echo "🎉 Setup complete!"
echo ""
echo "🏒 Hockey Madness is ready for development!"
echo ""
echo "📋 Next steps:"
echo "1. Open a new terminal and run: cd apps/frontend && npm run dev"
echo "2. Visit http://localhost:5173 to see your app"
echo "3. Visit http://localhost:54323 to access Supabase Studio"
echo "4. Create an admin account at /login (use admin@hockeymadness.com)"
echo "5. Update the user role to 'admin' in Supabase Studio"
echo ""
echo "📊 Supabase Services:"
echo "- API URL: http://localhost:54321"
echo "- Studio: http://localhost:54323"
echo "- DB URL: postgresql://postgres:postgres@localhost:54322/postgres"