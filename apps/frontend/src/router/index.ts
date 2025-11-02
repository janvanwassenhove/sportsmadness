import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

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
      component: () => import('@/views/ThemeDemoView.vue')
    },
    {
      path: '/test',
      name: 'test',
      component: () => import('@/views/SimpleTestView.vue')
    },
    {
      path: '/debug',
      name: 'debug',
      component: () => import('@/views/DebugView.vue')
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
      meta: { requiresAuth: true, requiresUserRole: true },
    },
    {
      path: '/match/:id',
      name: 'match-center',
      component: () => import('../views/MatchCenterView.vue'),
      meta: { requiresAuth: true },
      props: true,
    },
  ],
})

// Route guards
router.beforeEach(async (to, from, next) => {
  try {
    console.log('🚏 Router guard triggered for:', to.path)
    const authStore = useAuthStore()
    console.log('🚏 Auth loading state:', authStore.loading)
    
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
      try {
        await Promise.race([
          new Promise(resolve => {
            const unwatch = authStore.$subscribe(() => {
              if (!authStore.loading) {
                console.log('🚏 Auth loading completed!')
                unwatch()
                resolve(undefined)
              }
            })
          }),
          new Promise((_, reject) => 
            setTimeout(() => reject(new Error('Auth loading timeout')), 8000)
          )
        ])
      } catch (error) {
        console.warn('🚏 Auth loading timed out for protected route:', error)
        next({ name: 'home' })
        return
      }
    }

    // Check if route requires authentication
    if (requiresAuth && !authStore.isAuthenticated) {
      next({ name: 'login', query: { redirect: to.fullPath } })
      return
    }

    // Check if route requires admin access
    if (requiresAdmin && !authStore.isAdmin) {
      next({ name: 'home' })
      return
    }

    // Restrict team role users to specific routes only
    if (authStore.isTeam) {
      const allowedRoutesForTeam = ['home', 'scoreboard', 'profile', 'user-dashboard', 'match-center']
      if (!allowedRoutesForTeam.includes(to.name as string)) {
        next({ name: 'home' })
        return
      }
    }

    // Check if route requires user role (not admin or team)
    const requiresUserRole = to.matched.some(record => record.meta.requiresUserRole)
    if (requiresUserRole && !authStore.isUser) {
      next({ name: 'home' })
      return
    }

    console.log('🚏 Route guard completed, proceeding to:', to.path)
    next()
  } catch (error) {
    console.warn('Route guard error:', error)
    next() // Continue navigation even if auth fails
  }
})

export default router
