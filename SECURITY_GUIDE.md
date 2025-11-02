# 🔒 Hockey Madness - Secure Environment Setup

## Method 1: PowerShell Environment Variables (Recommended)

### Step 1: Set Environment Variables in PowerShell
```powershell
# Set for current session only
$env:VITE_SUPABASE_URL="https://your-project-ref.supabase.co"
$env:VITE_SUPABASE_ANON_KEY="your-anon-key-here"

# Start the app
npm run dev
```

### Step 2: Or create a secure startup script
```powershell
# Create apps/frontend/start-secure.ps1
@"
# Hockey Madness - Secure Development Start
Write-Host "🏒 Starting Hockey Madness with secure environment..." -ForegroundColor Green

# Prompt for Supabase credentials (hidden input for key)
`$url = Read-Host "Enter Supabase URL"
`$key = Read-Host "Enter Supabase Anon Key" -AsSecureString
`$keyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(`$key))

# Set environment variables
`$env:VITE_SUPABASE_URL = `$url
`$env:VITE_SUPABASE_ANON_KEY = `$keyPlain

Write-Host "✅ Environment configured securely" -ForegroundColor Green
Write-Host "🚀 Starting development server..." -ForegroundColor Yellow

# Start the application
npm run dev
"@
```

## Method 2: Windows System Environment Variables

### Using Windows Settings:
1. Press `Win + R`, type `sysdm.cpl`
2. Click "Environment Variables"
3. Add User variables:
   - `VITE_SUPABASE_URL` = your project URL
   - `VITE_SUPABASE_ANON_KEY` = your anon key
4. Restart VS Code/terminal

### Using PowerShell (Permanent):
```powershell
# Set permanent user environment variables
[Environment]::SetEnvironmentVariable("VITE_SUPABASE_URL", "https://your-project-ref.supabase.co", "User")
[Environment]::SetEnvironmentVariable("VITE_SUPABASE_ANON_KEY", "your-anon-key-here", "User")

# Restart terminal to pick up changes
```

## Method 3: Azure Key Vault / GitHub Secrets (Production)

### For Production Deployment:
- Use GitHub repository secrets
- Variables are set in GitHub Actions
- Never exposed in code

### For Azure deployment:
- Use Azure Key Vault
- Application reads from secure vault
- Managed identities for authentication

## Method 4: Docker Compose with External Env File

### Create docker-compose.local.yml:
```yaml
version: '3.8'
services:
  hockey-madness:
    build: .
    env_file:
      - .env.local.secure  # This file is in .gitignore
    ports:
      - "5173:5173"
```

## Current Recommended Approach:

**For Local Development:**
Use PowerShell environment variables or Windows system variables

**For Production:**
GitHub repository secrets are automatically configured in your deployment workflow

## Security Best Practices:

✅ **DO:**
- Use environment variables for secrets
- Keep `.env.local` in `.gitignore`
- Use GitHub secrets for production
- Rotate keys regularly

❌ **DON'T:**
- Commit any file with real credentials
- Share credentials in chat/email
- Use production keys for development
- Store secrets in code comments