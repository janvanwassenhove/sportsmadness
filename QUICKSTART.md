# 🚀 Quick Start Guide

Your Hockey Madness application is now running locally!

## 🎯 **Current Status**
✅ Frontend server running at: **http://localhost:5173**
✅ Dependencies installed
⚠️ Database setup required

## 📋 **Next Steps to Complete Setup**

### 1. **Set up Supabase Database**

**Option A: Use Supabase Cloud (Recommended)**
1. Go to [https://supabase.com](https://supabase.com)
2. Create a new project (it's free!)
3. Go to Settings > API
4. Copy your Project URL and anon key
5. Update `apps/frontend/.env.local` with your values

**Option B: Local Supabase (Advanced)**
- Install Docker Desktop
- Install Supabase CLI via package manager
- Run `supabase start` in the supabase folder

### 2. **Set up the Database Schema**
1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Copy the content from `supabase/migrations/20241030000001_initial_schema.sql`
4. Paste and run the SQL script
5. (Optional) Run `supabase/seed.sql` for sample data

### 3. **Create Admin Account**
1. Visit: **http://localhost:5173/login**
2. Sign up with: `admin@hockeymadness.com`
3. Go to Supabase Dashboard > Table Editor > users
4. Change the `role` column from 'user' to 'admin'

## 🏒 **Using the Application**

### **Public Views**
- **Home**: http://localhost:5173
- **Live Scoreboard**: http://localhost:5173/scoreboard

### **Admin Views** (after login)
- **Dashboard**: http://localhost:5173/admin
- **Teams Management**: http://localhost:5173/admin/teams
- **Match Control**: http://localhost:5173/admin/match/:id

## 🎮 **Tournament Workflow**

1. **Setup Teams**: Go to Admin → Manage Teams
2. **Add Players**: Create team rosters with player details
3. **Create Match**: From Admin Dashboard, create team matchups
4. **Start Match**: Click "Start Match" to begin live control
5. **Control Live**: Use Match Control for real-time management
6. **Public Display**: Open Scoreboard on separate screen/device

## 🛠 **Development Commands**

```bash
# Start development server
cd apps/frontend
npm run dev

# Build for production
npm run build

# Run type checking
npm run type-check

# Format code
npm run format
```

## 🔧 **Troubleshooting**

**Can't connect to database?**
- Check your .env.local file has correct Supabase URL and key
- Verify your Supabase project is active

**Build errors?**
- Run `npm install` in apps/frontend
- Check for TypeScript errors

**Authentication not working?**
- Ensure database schema is set up correctly
- Check user role is set to 'admin' in Supabase

## 📱 **Access Points**

- **Frontend**: http://localhost:5173
- **Supabase Dashboard**: [Your project dashboard]
- **API Documentation**: In your Supabase project settings

---

**🏒 Ready to manage your hockey tournament!**

Need help? Check `DEPLOYMENT.md` for detailed setup instructions.