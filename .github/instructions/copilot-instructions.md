# Hockey Madness - Full-Stack Tournament Management

## Project Overview
Hockey Madness is a real-time tournament management application built with Vue 3 + Supabase.

## Tech Stack
- Frontend: Vue 3 + Vite + Pinia + TailwindCSS + Vue I18n
- Backend: Supabase (Auth + Database + Realtime)
- Deployment: GitHub Pages (frontend) + Supabase Cloud
- Internationalization: English, Dutch, French support

## Architecture
- Monorepo structure with apps/frontend and supabase/
- Real-time match updates via Supabase channels
- Admin authentication with protected routes
- Public scoreboard with read-only access

## Database Schema
- teams(id, name, players jsonb)
- matches(id, team_a, team_b, score_a, score_b, status, time_left, maddie, boosters jsonb, cards jsonb)
- users(id, email, role)

## Key Features
- Admin Match Control: Timer, scores, cards, substitutions, effects
- Public Scoreboard: Full-screen display with real-time updates
- Tournament Admin: CRUD for teams, players, matches

## Development
- Local: npm run dev + supabase start
- Build: npm run build
- Deploy: GitHub Pages (automatic on push to main)

## Internationalization Guidelines
- Project supports English (en), Dutch (nl), and French (fr)
- Use Vue I18n's $t() function for all user-facing text
- Translation keys are organized hierarchically (e.g., 'navigation.home', 'auth.login')
- Store user's language preference in localStorage
- Language selector available in top navigation menu
- Default language: English
- Translation files: src/i18n/locales/{en,nl,fr}.json
- Language store: src/stores/language.ts

### Translation Standards
- ALWAYS use $t() for user-visible text in templates
- Use structured keys: section.subsection.item
- Include proper context for translators
- Test all languages before deployment
- Maintain consistent terminology across languages