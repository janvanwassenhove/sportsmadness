# Hockey Madness - Development Startup Script
# This script checks system environment variables and starts the dev server

Write-Host "🏒 Hockey Madness - Development Startup" -ForegroundColor Cyan
Write-Host "======================================="

# Check if system environment variables are set
Write-Host "`n🔍 Checking system environment variables..." -ForegroundColor Yellow

$supabaseUrl = [System.Environment]::GetEnvironmentVariable("VITE_SUPABASE_URL", "User")
$supabaseKey = [System.Environment]::GetEnvironmentVariable("VITE_SUPABASE_ANON_KEY", "User")

if (-not $supabaseUrl) {
    $supabaseUrl = [System.Environment]::GetEnvironmentVariable("VITE_SUPABASE_URL", "Machine")
}

if (-not $supabaseKey) {
    $supabaseKey = [System.Environment]::GetEnvironmentVariable("VITE_SUPABASE_ANON_KEY", "Machine")
}

Write-Host "VITE_SUPABASE_URL: " -NoNewline
if ($supabaseUrl) {
    Write-Host $supabaseUrl -ForegroundColor Green
} else {
    Write-Host "NOT SET" -ForegroundColor Red
}

Write-Host "VITE_SUPABASE_ANON_KEY: " -NoNewline
if ($supabaseKey) {
    $keyPreview = $supabaseKey.Substring(0, [Math]::Min(20, $supabaseKey.Length)) + "..."
    Write-Host $keyPreview -ForegroundColor Green
} else {
    Write-Host "NOT SET" -ForegroundColor Red
}

if (-not $supabaseUrl -or -not $supabaseKey) {
    Write-Host "`n⚠️  System environment variables not found!" -ForegroundColor Red
    Write-Host "To set them permanently, run:" -ForegroundColor Yellow
    Write-Host 'setx VITE_SUPABASE_URL "https://your-project.supabase.co"' -ForegroundColor White
    Write-Host 'setx VITE_SUPABASE_ANON_KEY "your-publishable-key"' -ForegroundColor White
    Write-Host "`nOr set them for this session:" -ForegroundColor Yellow
    Write-Host '$env:VITE_SUPABASE_URL="https://your-project.supabase.co"' -ForegroundColor White
    Write-Host '$env:VITE_SUPABASE_ANON_KEY="your-publishable-key"' -ForegroundColor White
    Write-Host "`n📝 Using fallback values from .env.local for now..." -ForegroundColor Blue
}

Write-Host "`n🚀 Starting development server..." -ForegroundColor Green

# Set environment variables for this session if system ones exist
if ($supabaseUrl) {
    $env:VITE_SUPABASE_URL = $supabaseUrl
}
if ($supabaseKey) {
    $env:VITE_SUPABASE_ANON_KEY = $supabaseKey
}

# Start the development server
npm run dev