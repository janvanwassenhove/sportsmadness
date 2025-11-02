# 🗄️ Hockey Madness - Database Schema Verification

## Tables Created:

### 1. `users` table
- `id` (UUID, primary key)
- `email` (text, unique)
- `role` (text: 'admin' or 'user', default: 'user')
- `created_at` (timestamp)

### 2. `teams` table  
- `id` (UUID, primary key)
- `name` (text)
- `players` (jsonb array)
- `created_at` (timestamp)

### 3. `matches` table
- `id` (UUID, primary key)
- `team_a` (UUID, references teams)
- `team_b` (UUID, references teams) 
- `score_a` (integer, default: 0)
- `score_b` (integer, default: 0)
- `status` (text: 'pending', 'active', 'paused', 'finished')
- `time_left` (integer, default: 1800 seconds = 30 minutes)
- `maddie` (boolean, default: false)
- `boosters` (jsonb object)
- `cards` (jsonb object)
- `created_at` (timestamp)

## Security Features:
- ✅ Row Level Security (RLS) enabled
- ✅ Public read access for matches and teams
- ✅ Admin-only write access
- ✅ Realtime subscriptions enabled

## Verification Steps:

1. **Check Tables Created**
   - Go to Supabase Dashboard → Database → Tables
   - Should see: users, teams, matches

2. **Test Sample Query**
   ```sql
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public';
   ```

3. **Verify RLS Policies**
   - Go to Authentication → Policies
   - Should see policies for each table

## Optional: Add Sample Data

If you want test data, you can also run the seed file:
- Open: `supabase/seed.sql`
- Copy and run in SQL Editor
- This adds sample teams and matches for testing