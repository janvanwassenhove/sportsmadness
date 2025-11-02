# 🗄️ Hockey Madness - Database Setup Guide

## Option 1: Remote Database (Supabase Cloud) - RECOMMENDED

### Step 1: Create Supabase Project
1. Go to [https://supabase.com](https://supabase.com)
2. Click "Start your project"
3. Sign up/Login with GitHub
4. Click "New project"
5. Choose organization and fill details:
   - **Name**: `hockey-madness`
   - **Database Password**: Choose a strong password
   - **Region**: Choose closest to you
6. Click "Create new project" (takes ~2 minutes)

### Step 2: Get Your Credentials
1. In your project dashboard, go to **Settings** → **API**
2. Copy these values:
   - **Project URL**: `https://your-project-ref.supabase.co`
   - **anon/public key**: `eyJ...` (long string)

### Step 3: Update Environment File
Update `apps/frontend/.env.local`:
```env
VITE_SUPABASE_URL=https://your-actual-project-ref.supabase.co
VITE_SUPABASE_ANON_KEY=your-actual-anon-key-here
```

### Step 4: Set Up Database Schema
1. In Supabase dashboard, go to **SQL Editor**
2. Click "New query"
3. Copy ALL content from `supabase/migrations/20241030000001_initial_schema.sql`
4. Paste and click "Run"
5. ✅ Should see "Success. No rows returned"

### Step 5: Add Sample Data (Optional)
1. In SQL Editor, create another new query
2. Copy content from `supabase/seed.sql`
3. Run it to get sample teams and matches

### Step 6: Create Admin User
1. Start your app: `npm run dev`
2. Go to `/login` and sign up with your email
3. In Supabase dashboard → **Authentication** → **Users**
4. Find your user and edit to set `role` = `admin`

---

## Option 2: Local Database (Development Only)

### Prerequisites
- Docker Desktop installed and running
- Supabase CLI

### Step 1: Install Supabase CLI
```powershell
# Using npm (if Node.js installed)
npm install -g supabase

# OR using Chocolatey
choco install supabase

# OR download from GitHub releases
```

### Step 2: Initialize Local Supabase
```powershell
cd C:\Development\Workspaces\hockeymadness
supabase init
supabase start
```

### Step 3: Apply Migrations
```powershell
supabase db reset
```

### Step 4: Update Environment for Local
Update `apps/frontend/.env.local`:
```env
VITE_SUPABASE_URL=http://localhost:54321
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
```

---

## ✅ Verification Steps

After setup, verify everything works:

1. **Start the app**: `npm run dev`
2. **Check diagnostic page**: Should show "✅ Supabase: Configured"
3. **Test login**: Go to `/login` - should work without errors
4. **Check scoreboard**: Should load (empty if no data)
5. **Admin access**: Login as admin user to access `/admin`

---

## 🚨 Troubleshooting

### "Failed to fetch" errors
- Check your Supabase URL and key are correct
- Ensure project is not paused (free tier pauses after 1 week inactivity)

### Authentication issues
- Verify you set user role to 'admin' in Supabase dashboard
- Check browser console for errors

### Database connection
- Ensure RLS policies are enabled (included in migration)
- Check if tables were created successfully

---

## 📊 Database Schema Overview

Your database includes:
- **users**: Authentication with admin/user roles
- **teams**: Team information with player lists
- **matches**: Game data with real-time updates
- **RLS Policies**: Secure access controls
- **Realtime**: Live match updates

Ready to start managing hockey tournaments! 🏒