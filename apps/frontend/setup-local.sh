#!/bin/bash

# Setup script for local development
# This script helps configure environment variables for local development

echo "🏒 Hockey Madness - Local Development Setup"
echo "=========================================="

# Check if .env.local exists
if [ ! -f ".env.local" ]; then
    echo "Creating .env.local from template..."
    cp .env.example .env.local
    echo "✅ .env.local created from template"
else
    echo "ℹ️  .env.local already exists"
fi

echo ""
echo "📝 Next steps:"
echo "1. Edit .env.local and add your Supabase project details:"
echo "   - VITE_SUPABASE_URL=https://your-project-id.supabase.co"
echo "   - VITE_SUPABASE_ANON_KEY=sb_publishable_your_key_here"
echo ""
echo "2. For GitHub Pages deployment, set repository variables:"
echo "   - Go to: Settings > Secrets and variables > Actions > Variables"
echo "   - Add: VITE_SUPABASE_URL"
echo "   - Add: VITE_SUPABASE_ANON_KEY (use your publishable key)"
echo ""
echo "🔧 To get your new API keys:"
echo "   1. Go to your Supabase dashboard"
echo "   2. Navigate to Settings > API"
echo "   3. Use the 'Publishable key' (starts with sb_publishable_)"
echo "   4. This key is safe to use in browser environments"
echo ""

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    echo "✅ Dependencies installed"
fi

echo "🚀 Ready to start development!"
echo "Run: npm run dev"