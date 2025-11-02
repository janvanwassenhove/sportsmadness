# 🏒 Hockey Madness - Setup & Deployment Guide

## 🚀 Quick Start (Local Development)

### Prerequisites
- Node.js 18+
- Supabase CLI (`npm install -g supabase`)

### Setup Steps

1. **Run the setup script** (Windows):
   ```bash
   setup-dev.bat
   ```
   
   Or (Unix/Mac):
   ```bash
   chmod +x setup-dev.sh
   ./setup-dev.sh
   ```

2. **Start the development server**:
   ```bash
   cd apps/frontend
   npm run dev
   ```

3. **Access the application**:
   - Frontend: http://localhost:5173
   - Supabase Studio: http://localhost:54323

### Create Admin Account

1. Go to http://localhost:5173/login
2. Sign up with email: `admin@hockeymadness.com`
3. Open Supabase Studio at http://localhost:54323
4. Navigate to Table Editor > users
5. Change the `role` column from 'user' to 'admin' for your account

## 📊 Application Features

### Public Views
- **Home Page** (`/`): Landing page with navigation
- **Live Scoreboard** (`/scoreboard`): Full-screen public display

### Admin Views (Requires Authentication)
- **Admin Dashboard** (`/admin`): Tournament overview
- **Match Control** (`/admin/match/:id`): Live match management
- **Teams Management** (`/admin/teams`): CRUD for teams and players

### Real-time Features
- Live score updates
- Match timer synchronization
- Special effects (Maddie, Boosters)
- Card tracking (Yellow, Green, Red)

## 🎮 Using the Application

### Tournament Setup
1. Login as admin
2. Go to "Manage Teams" to create teams and add players
3. Create matches from the Admin Dashboard
4. Use "Start Match" to begin a tournament game

### Match Control
1. Click "Control Match" on an active match
2. Use the timer controls (Play/Pause/Finish)
3. Update scores with +/- buttons
4. Add player cards as needed
5. Trigger special effects (Maddie/Boosters)

### Public Display
1. Open `/scoreboard` on a separate screen/device
2. The scoreboard updates automatically during matches
3. Shows live scores, timer, cards, and special effects

## 🚀 Production Deployment

### GitHub Pages (Frontend)

1. **Set up repository secrets**:
   - `VITE_SUPABASE_URL`: Your Supabase project URL
   - `VITE_SUPABASE_ANON_KEY`: Your Supabase anon key

2. **Configure Vite base path**:
   ```typescript
   // In vite.config.ts
   base: '/your-repo-name/'
   ```

3. **Push to main branch** - GitHub Actions will automatically build and deploy

### Supabase (Backend)

1. **Create Supabase project** at https://supabase.com
2. **Run migrations**:
   ```bash
   supabase db push
   ```
3. **Seed data** (optional):
   ```bash
   supabase db seed
   ```
4. **Update environment variables** in your frontend deployment

## 🔧 Configuration

### Environment Variables

Create `.env.local` in `apps/frontend/`:
```bash
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Database Schema

The application uses three main tables:
- `users`: Authentication and roles
- `teams`: Team information and player rosters
- `matches`: Match data with real-time updates

### Row Level Security (RLS)

- Public read access for scoreboard data
- Admin-only write access for match control
- User-specific access for profiles

## 🎨 Customization

### Styling
- Tailwind CSS classes in components
- Custom animations for special effects
- Responsive design for all screen sizes

### Sound Effects
Add sound files to `apps/frontend/public/sounds/`:
- `maddie.mp3` - Maddie trigger sound
- `goal.mp3` - Goal celebration
- `whistle.mp3` - Match events

### Special Effects
- **Maddie**: Triggers screen flash and sound
- **Boosters**: Visual indicators for power-ups
- **Cards**: Track player penalties and achievements

## 🐛 Troubleshooting

### Common Issues

1. **Build errors**: Ensure TailwindCSS v3.x is installed
2. **Database connection**: Check Supabase URL and keys
3. **Real-time not working**: Verify Supabase realtime is enabled
4. **Admin access denied**: Check user role in database

### Development Tips

- Use browser dev tools to inspect real-time updates
- Check Supabase logs for database errors
- Monitor network tab for API calls
- Use Vue DevTools for component debugging

## 📱 Mobile Support

The application is responsive and works on:
- Tablets (recommended for admin controls)
- Phones (scoreboard viewing)
- Large displays (public scoreboard)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

---

**🏒 Ready to manage your hockey tournament like a pro!**