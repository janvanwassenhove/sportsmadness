# Hockey Madness - Secure Development Start
Write-Host "� Starting Hockey Madness with secure environment..." -ForegroundColor Green
Write-Host ""

# Check if environment variables are already set
if ($env:VITE_SUPABASE_URL -and $env:VITE_SUPABASE_ANON_KEY) {
    Write-Host "✅ Environment variables already set" -ForegroundColor Green
} else {
    Write-Host "🔑 Please enter your Supabase credentials:" -ForegroundColor Yellow
    Write-Host "   (Get these from: https://supabase.com/dashboard/project/[your-project]/settings/api)" -ForegroundColor Gray
    Write-Host ""
    
    # Prompt for Supabase credentials
    $url = Read-Host "Supabase URL (https://xxxxx.supabase.co)"
    
    # Validate URL format
    if (-not $url.StartsWith("https://") -or -not $url.Contains(".supabase.co")) {
        Write-Host "❌ Invalid URL format. Should be: https://your-project-ref.supabase.co" -ForegroundColor Red
        pause
        exit 1
    }
    
    $key = Read-Host "Supabase Anon Key" -AsSecureString
    $keyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($key))
    
    # Validate key format (should be JWT)
    if (-not $keyPlain.StartsWith("eyJ")) {
        Write-Host "❌ Invalid key format. Should start with 'eyJ'" -ForegroundColor Red
        pause
        exit 1
    }
    
    # Set environment variables for this session
    $env:VITE_SUPABASE_URL = $url
    $env:VITE_SUPABASE_ANON_KEY = $keyPlain
    
    Write-Host "✅ Environment configured securely (session only)" -ForegroundColor Green
}

Write-Host ""
Write-Host "🔒 Security Status:" -ForegroundColor Cyan
Write-Host "   • Credentials stored in memory only" -ForegroundColor Gray
Write-Host "   • No files modified with secrets" -ForegroundColor Gray
Write-Host "   • Safe to commit code to GitHub" -ForegroundColor Gray
Write-Host ""

# Show masked URL for confirmation
$maskedUrl = $env:VITE_SUPABASE_URL -replace '(https://)[^.]+(.supabase.co)', '$1***$2'
Write-Host "🌐 Using Supabase URL: $maskedUrl" -ForegroundColor Gray

Write-Host ""
Write-Host "🚀 Starting development server..." -ForegroundColor Yellow
Write-Host "   Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

# Start the application
npm run dev