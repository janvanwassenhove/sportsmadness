# Setup script for local development (Windows PowerShell)
# This script helps configure environment variables for local development

Write-Host "🏒 Hockey Madness - Local Development Setup" -ForegroundColor Cyan
Write-Host "=========================================="

# Check if .env.local exists
if (-not (Test-Path ".env.local")) {
    Write-Host "Creating .env.local from template..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env.local"
    Write-Host "✅ .env.local created from template" -ForegroundColor Green
} else {
    Write-Host "ℹ️  .env.local already exists" -ForegroundColor Blue
}

Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host "1. Edit .env.local and add your Supabase project details:"
Write-Host "   - VITE_SUPABASE_URL=https://your-project-id.supabase.co"
Write-Host "   - VITE_SUPABASE_ANON_KEY=sb_publishable_your_key_here"
Write-Host ""
Write-Host "2. For GitHub Pages deployment, set repository variables:"
Write-Host "   - Go to: Settings > Secrets and variables > Actions > Variables"
Write-Host "   - Add: VITE_SUPABASE_URL"
Write-Host "   - Add: VITE_SUPABASE_ANON_KEY (use your publishable key)"
Write-Host ""
Write-Host "🔧 To get your new API keys:" -ForegroundColor Cyan
Write-Host "   1. Go to your Supabase dashboard"
Write-Host "   2. Navigate to Settings > API"
Write-Host "   3. Use the 'Publishable key' (starts with sb_publishable_)"
Write-Host "   4. This key is safe to use in browser environments"
Write-Host ""

# Check if node_modules exists
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
    npm install
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
}

Write-Host "🚀 Ready to start development!" -ForegroundColor Green
Write-Host "Run: npm run dev"