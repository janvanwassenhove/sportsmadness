import { createClient } from '@supabase/supabase-js'

// Priority order: System env vars (via define) -> Vite env vars -> fallback defaults
const supabaseUrl = (globalThis as any).__VITE_SUPABASE_URL__ || 
                   import.meta.env.VITE_SUPABASE_URL || 
                   'http://localhost:54321'

// Use the new publishable key format (sb_publishable_*) for production
// or fallback to local development key
const supabaseAnonKey = (globalThis as any).__VITE_SUPABASE_ANON_KEY__ || 
                       import.meta.env.VITE_SUPABASE_ANON_KEY || 
                       'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'

// Validate that we're using the correct key format
const isLegacyKey = supabaseAnonKey.startsWith('eyJ')
const isNewPublishableKey = supabaseAnonKey.startsWith('sb_publishable_')
const isLocalDevKey = supabaseUrl.includes('localhost')

// Debug logging in development
if (import.meta.env.DEV) {
  console.log('🔧 Supabase Config Debug:', {
    url: supabaseUrl,
    keyPreview: supabaseAnonKey.substring(0, 20) + '...',
    keyType: isLocalDevKey ? 'local-dev' : (isNewPublishableKey ? 'publishable' : 'legacy'),
    source: (globalThis as any).__VITE_SUPABASE_URL__ ? 'system-env-define' : 
            import.meta.env.VITE_SUPABASE_URL ? 'vite-env-file' : 'default-fallback',
    systemDefineUrl: (globalThis as any).__VITE_SUPABASE_URL__,
    systemDefineKey: (globalThis as any).__VITE_SUPABASE_ANON_KEY__ ? 
      (globalThis as any).__VITE_SUPABASE_ANON_KEY__.substring(0, 20) + '...' : 'not-set',
    viteEnvUrl: import.meta.env.VITE_SUPABASE_URL,
    viteEnvKey: import.meta.env.VITE_SUPABASE_ANON_KEY ? 
      import.meta.env.VITE_SUPABASE_ANON_KEY.substring(0, 20) + '...' : 'not-set'
  })
  
  // Warn if using legacy key in production
  if (!isLocalDevKey && isLegacyKey) {
    console.warn('⚠️ Using legacy API key. Consider upgrading to new publishable key format.')
  }
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export type Database = {
  public: {
    Tables: {
      teams: {
        Row: {
          id: string
          name: string
          players: any[]
          created_at?: string
        }
        Insert: {
          id?: string
          name: string
          players: any[]
        }
        Update: {
          id?: string
          name?: string
          players?: any[]
        }
      }
      matches: {
        Row: {
          id: string
          team_a: string
          team_b: string
          score_a: number
          score_b: number
          status: 'pending' | 'active' | 'paused' | 'finished'
          time_left: number
          maddie: boolean
          boosters: any
          cards: any
          created_at?: string
        }
        Insert: {
          id?: string
          team_a: string
          team_b: string
          score_a?: number
          score_b?: number
          status?: 'pending' | 'active' | 'paused' | 'finished'
          time_left?: number
          maddie?: boolean
          boosters?: any
          cards?: any
        }
        Update: {
          id?: string
          team_a?: string
          team_b?: string
          score_a?: number
          score_b?: number
          status?: 'pending' | 'active' | 'paused' | 'finished'
          time_left?: number
          maddie?: boolean
          boosters?: any
          cards?: any
        }
      }
      users: {
        Row: {
          id: string
          email: string
          role: 'admin' | 'user'
          created_at?: string
        }
        Insert: {
          id?: string
          email: string
          role?: 'admin' | 'user'
        }
        Update: {
          id?: string
          email?: string
          role?: 'admin' | 'user'
        }
      }
    }
  }
}