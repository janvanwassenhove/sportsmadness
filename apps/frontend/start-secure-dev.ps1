# Hockey Madness - Secure Development Start
Write-Host "Hockey Madness - Secure Environment Setup" -ForegroundColor Green
Write-Host ""

# Check if environment variables are already set
if ($env:VITE_SUPABASE_URL -and $env:VITE_SUPABASE_ANON_KEY) {
    Write-Host "Environment variables already configured" -ForegroundColor Green
    $maskedUrl = $env:VITE_SUPABASE_URL -replace "https://([^.]+)\.supabase\.co", "https://*****.supabase.co"
    Write-Host "Current URL: $maskedUrl" -ForegroundColor Gray
    Write-Host ""
    $useExisting = Read-Host "Use existing credentials? (y/n)"
    if ($useExisting -eq "n") {
        $env:VITE_SUPABASE_URL = $null
        $env:VITE_SUPABASE_ANON_KEY = $null
    }
}

if (-not $env:VITE_SUPABASE_URL -or -not $env:VITE_SUPABASE_ANON_KEY) {
    Write-Host "Please enter your Supabase credentials:" -ForegroundColor Yellow
    Write-Host "Get from: https://supabase.com -> Settings -> API" -ForegroundColor Gray
    Write-Host ""
    
    # Get Supabase URL
    do {
        $url = Read-Host "Supabase Project URL (https://xxxxx.supabase.co)"
        if (-not $url.StartsWith("https://") -or -not $url.Contains("supabase.co")) {
            Write-Host "Invalid format. Example: https://abcdefg.supabase.co" -ForegroundColor Red
        }
    } while (-not $url.StartsWith("https://") -or -not $url.Contains("supabase.co"))
    
    # Get Supabase Key
    do {
        $key = Read-Host "Supabase Anon Key (starts with eyJ...)"
        if (-not $key.StartsWith("eyJ")) {
            Write-Host "Invalid key format. Should start with 'eyJ'" -ForegroundColor Red
        }
    } while (-not $key.StartsWith("eyJ"))
    
    # Set environment variables
    $env:VITE_SUPABASE_URL = $url
    $env:VITE_SUPABASE_ANON_KEY = $key
    
    Write-Host ""
    Write-Host "Credentials configured securely (memory only)" -ForegroundColor Green
}

Write-Host ""
Write-Host "SECURITY: Credentials stored in memory only - safe to commit code" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starting development server..." -ForegroundColor Yellow

# Start the application
npm run dev