import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import TournamentBuilderView from '@/views/TournamentBuilderView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: () => import('@/views/HomeView.vue')
    },
    {
      path: '/theme-demo',
      name: 'theme-demo',
      component: () => import('@/views/ThemeDemoView.vue'),
      meta: { requiresAuth: true, requiresAdmin: true }
    },
    {
      path: '/auth-diagnostic',
      name: 'auth-diagnostic',
      component: () => import('@/views/AuthDiagnosticView.vue')
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue'),
    },
    {
      path: '/scoreboard',
      name: 'scoreboard',
      component: () => import('../views/ScoreboardView.vue'),
    },
    {
      path: '/scoreboard/:id',
      name: 'scoreboard-match',
      component: () => import('../views/ScoreboardView.vue'),
      props: true,
    },
    {
      path: '/admin',
      name: 'admin',
      component: () => import('../views/AdminView.vue'),
      meta: { requiresAuth: true, requiresAdmin: true },
    },
    {
      path: '/admin/match/:id',
      name: 'match-control',
      component: () => import('../views/MatchControlView.vue'),
      meta: { requiresAuth: true, requiresAdmin: true },
      props: true,
    },
    {
      path: '/admin/match/:id/stats',
      name: 'match-stats',
      component: () => import('../views/MatchStatsView.vue'),
      meta: { requiresAuth: true, requiresAdmin: true },
      props: true,
    },
    {
      path: '/admin/teams',
      name: 'teams-admin',
      component: () => import('../views/TeamsAdminView.vue'),
      meta: { requiresAuth: true, requiresAdmin: true },
    },
    {
      path: '/admin/boosters',
      name: 'boosters-admin',
      component: () => import('../views/BoostersAdminView.vue'),
      meta: { requiresAuth: true, requiresAdmin: true },
    },
    {
      path: '/admin/tournaments',
      name: 'tournaments-admin',
      component: () => import('../views/TournamentAdminView.vue'),
      meta: { requiresAuth: true, requiresAdmin: true },
    },
    {
      path: '/admin/tournaments/builder',
      name: 'tournament-builder',
      component: TournamentBuilderView,
      meta: { requiresAuth: true, requiresAdmin: true },
    },
    {
      path: '/admin/tournaments/division/:divisionId',
      name: 'division-management',
      component: () => import('../views/DivisionManagementView.vue'),
      meta: { requiresAuth: true, requiresAdmin: true },
      props: true,
    },
    {
      path: '/admin/users',
      name: 'user-management',
      component: () => import('../views/UserManagementView.vue'),
      meta: { requiresAuth: true, requiresAdmin: true },
    },
    {
      path: '/profile',
      name: 'profile',
      component: () => import('../views/ProfileView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/dashboard',
      name: 'user-dashboard',
      component: () => import('../views/UserDashboardView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/match/:id',
      name: 'match-center',
      component: () => import('../views/MatchCenterView.vue'),
      meta: { requiresAuth: true },
      props: true,
    },
    {
      path: '/game-guide',
      name: 'game-guide',
      component: () => import('../views/GameExplanationView.vue'),
      meta: { requiresAuth: true },
    },
  ],
})

// Route guards
router.beforeEach(async (to, from, next) => {
  try {
    console.log('🚏 Router guard triggered for:', to.path, 'from:', from.path)
    const authStore = useAuthStore()
    console.log('🚏 Auth loading state:', authStore.loading)
    console.log('🚏 Auth authenticated state:', authStore.isAuthenticated)
    console.log('🚏 Auth admin state:', authStore.isAdmin)
    
    // Check if route requires authentication or admin access
    const requiresAuth = to.matched.some(record => record.meta.requiresAuth)
    const requiresAdmin = to.matched.some(record => record.meta.requiresAdmin)
    
    // If route doesn't require authentication, allow immediate access
    if (!requiresAuth && !requiresAdmin) {
      console.log('🚏 Public route - proceeding immediately to:', to.path)
      next()
      return
    }
    
    // Wait for auth to initialize only for protected routes
    if (authStore.loading) {
      console.log('🚏 Protected route - waiting for auth to finish loading...')
      
      // Immediate check if auth is already loaded (prevents race condition)
      if (!authStore.loading) {
        console.log('🚏 Auth already loaded (race condition avoided)')
      } else {
        try {
          // Wait for auth with multiple fallback strategies
          await Promise.race([
            // Strategy 1: Subscribe to store changes
            new Promise(resolve => {
              const unwatch = authStore.$subscribe(() => {
                if (!authStore.loading) {
                  console.log('🚏 Auth loading completed via subscription!')
                  unwatch()
                  resolve(undefined)
                }
              })
              // Immediately check in case it already finished
              if (!authStore.loading) {
                console.log('🚏 Auth already completed before subscription')
                unwatch()
                resolve(undefined)
              }
            }),
            // Strategy 2: Timeout after 8 seconds
            new Promise((_, reject) => 
              setTimeout(() => reject(new Error('Auth loading timeout')), 8000)
            )
          ])
        } catch (error) {
          console.warn('🚏 Auth loading timed out for protected route:', error)
          // Don't redirect to home if user might be authenticated
          // Instead, let them through and the auth check below will handle it
          console.log('🚏 Proceeding despite timeout - auth state will be checked below')
        }
      }
    }

    // Double-check auth state after waiting
    console.log('🚏 Auth state after waiting - isAuthenticated:', authStore.isAuthenticated, 'isAdmin:', authStore.isAdmin)

    // Check if route requires authentication
    if (requiresAuth && !authStore.isAuthenticated) {
      console.log('🚏 Route requires auth but user not authenticated, redirecting to login')
      next({ name: 'login', query: { redirect: to.fullPath } })
      return
    }

    // Check if route requires admin access
    if (requiresAdmin && !authStore.isAdmin) {
      console.log('🚏 Route requires admin but user is not admin, redirecting to home')
      next({ name: 'home' })
      return
    }

    // Restrict team role users to specific routes only
    if (authStore.isTeam) {
      const allowedRoutesForTeam = ['home', 'scoreboard', 'profile', 'user-dashboard', 'match-center', 'game-guide']
      if (!allowedRoutesForTeam.includes(to.name as string)) {
        console.log('🚏 Team user trying to access restricted route, redirecting to home')
        next({ name: 'home' })
        return
      }
    }

    // Check if route requires user role (not admin or team)
    const requiresUserRole = to.matched.some(record => record.meta.requiresUserRole)
    if (requiresUserRole && !authStore.isUser) {
      console.log('🚏 Route requires user role but user has different role, redirecting to home')
      next({ name: 'home' })
      return
    }

    console.log('🚏 Route guard completed successfully, proceeding to:', to.path)
    next()
  } catch (error) {
    console.warn('🚏 Route guard error:', error)
    next() // Continue navigation even if auth fails
  }
})

// Global error handler for chunk loading failures (typically due to cache issues after deployment)
router.onError((error) => {
  console.error('🚨 Router error:', error)
  
  // Check if it's a chunk loading error
  if (error.message.includes('Failed to fetch dynamically imported module') || 
      error.message.includes('ERR_ABORTED') ||
      error.message.includes('Importing a module script failed')) {
    console.warn('🔄 Chunk loading failed - likely due to deployment update. Reloading page...')
    
    // Reload the page to get the latest version
    // Add a flag to prevent infinite reload loops
    const hasReloaded = sessionStorage.getItem('chunk-load-reload')
    if (!hasReloaded) {
      sessionStorage.setItem('chunk-load-reload', 'true')
      window.location.reload()
    } else {
      console.error('🚨 Chunk load failed after reload. Please clear your browser cache.')
      sessionStorage.removeItem('chunk-load-reload')
      alert('An error occurred loading the application. Please clear your browser cache and try again.')
    }
  }
})

// Clear the reload flag on successful navigation
router.afterEach(() => {
  sessionStorage.removeItem('chunk-load-reload')
})

export default router
