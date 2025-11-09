# Supabase API Keys Migration Guide

This project has been updated to use Supabase's new API key format instead of legacy JWT tokens.

## Key Differences

### Legacy Keys (Old)
- Format: JWT tokens starting with `eyJ...`
- Example: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### New Publishable Keys
- Format: Prefixed keys starting with `sb_publishable_`
- Example: `sb_publishable_OUC15DEEP1Q17985HbHqw_yu2V1aTD`
- Safer for client-side use
- Better security and monitoring

## Setup Instructions

### Local Development

1. **Copy the environment template:**
   ```bash
   cp .env.example .env.local
   ```

2. **Get your new API keys:**
   - Go to your Supabase dashboard
   - Navigate to Settings > API
   - Copy the **Publishable key** (starts with `sb_publishable_`)
   - Copy your project URL

3. **Update `.env.local`:**
   ```env
   VITE_SUPABASE_URL=https://your-project-id.supabase.co
   VITE_SUPABASE_ANON_KEY=sb_publishable_your_publishable_key_here
   ```

4. **Run the setup script (optional):**
   ```bash
   # On Windows
   .\setup-local.ps1
   
   # On macOS/Linux
   ./setup-local.sh
   ```

### GitHub Pages Deployment

Since publishable keys are safe for client-side use, we use **repository variables** instead of secrets:

1. Go to your repository on GitHub
2. Navigate to: **Settings** > **Secrets and variables** > **Actions** > **Variables** tab
3. Add these repository variables:
   - `VITE_SUPABASE_URL`: Your Supabase project URL
   - `VITE_SUPABASE_ANON_KEY`: Your publishable key

### Local Supabase Development

For local Supabase instances, the configuration automatically falls back to the standard local development key:

```env
VITE_SUPABASE_URL=http://localhost:54321
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Security Benefits

1. **Publishable keys are designed for client-side use**
2. **Better monitoring and rate limiting**
3. **Easier to rotate and manage**
4. **No risk of exposing service role capabilities**

## Verification

The application will log the key type being used in development mode:

```
🔧 Supabase Config: {
  url: "https://your-project.supabase.co",
  keyPreview: "sb_publishable_OUC15D...",
  keyType: "publishable",
  source: "vite-env"
}
```

If you see a warning about using legacy keys, update to the new format for better security.