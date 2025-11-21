# Hockey Madness

A real-time tournament management application for hockey tournaments.

## 🏒 Features

- **Admin Match Control**: Manage live matches with timer, scores, cards, and effects
- **Public Scoreboard**: Full-screen display with real-time updates
- **Tournament Management**: CRUD operations for teams, players, and matches
- **Real-time Updates**: Live synchronization using Supabase channels
- **Authentication**: Secure admin access with Supabase Auth
- **Multi-Theme Support**: Switch between default and custom themes (including HC Lokeren)
- **Internationalization**: Support for English, Dutch, and French languages

## 🛠 Tech Stack

- **Frontend**: Vue 3 + Vite + Pinia + TailwindCSS
- **Backend**: Supabase (Auth + Database + Realtime)
- **Deployment**: GitHub Pages

## 🚀 Getting Started

### Prerequisites

- Node.js (v18 or higher)
- npm or yarn
- Supabase CLI

### Local Development

1. **Clone and install dependencies**:
   ```bash
   git clone <repository-url>
   cd hockeymadness
   cd apps/frontend
   npm install
   ```

2. **Start Supabase locally**:
   ```bash
   cd ../../supabase
   supabase start
   ```

3. **Start the frontend**:
   ```bash
   cd ../apps/frontend
   npm run dev
   ```

4. **Access the application**:
   - Frontend: http://localhost:5173
   - Supabase Studio: http://localhost:54323

## 📁 Project Structure

```
hockeymadness/
├── apps/
│   └── frontend/          # Vue 3 application
│       ├── src/
│       │   ├── components/
│       │   ├── views/
│       │   ├── stores/     # Pinia stores
│       │   └── lib/        # Supabase client
│       ├── public/
│       └── package.json
├── supabase/              # Supabase configuration
│   ├── migrations/        # Database migrations
│   ├── seed.sql          # Sample data
│   └── config.toml       # Supabase config
└── README.md
```

## 🎮 Views

### Admin Match Control
- Start/stop match timer
- Update team scores
- Manage player cards (yellow/green/red)
- Handle substitutions
- Trigger special effects (Booster/Maddie)

### Public Scoreboard
- Full-screen match display
- Real-time score updates
- Visual effects and animations
- Automatic refresh from database

### Tournament Admin
- Manage teams and players
- Schedule matches
- View tournament results

## 📊 Database Schema

- `teams(id, name, players jsonb)`
- `matches(id, team_a, team_b, score_a, score_b, status, time_left, maddie, boosters jsonb, cards jsonb)`
- `users(id, email, role)`

## 🎨 Theme System

Hockey Madness includes a flexible theme system with support for multiple visual themes:

- **Default Theme**: Standard Hockey Madness branding with blue color scheme
- **HC Lokeren Theme**: Custom theme with navy blue (#121238) and light blue (#478dcb) colors, custom logo, and specialized fonts (League Spartan, Bebas Neue, Quicksand, Futura)

### Features:
- Live theme switching via navigation dropdown
- Persistent theme selection (localStorage)
- Theme-aware colors and typography
- CSS custom properties integration
- Custom logos per theme
- Google Fonts integration with fallbacks

See [THEME_SYSTEM.md](./THEME_SYSTEM.md) for detailed documentation.

## 🚀 Deployment

The frontend automatically deploys to GitHub Pages on push to main branch.

## 📝 License

MIT License