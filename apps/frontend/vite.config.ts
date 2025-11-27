import { fileURLToPath, URL } from 'node:url'
import { execSync } from 'node:child_process'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

// Function to get environment variable from system or user scope on Windows
function getEnvVar(name: string): string | undefined {
  // First check process.env (system variables and current session)
  if (process.env[name]) {
    return process.env[name]
  }
  
  // On Windows, check user environment variables
  if (process.platform === 'win32') {
    try {
      const result = execSync(`powershell -Command "[Environment]::GetEnvironmentVariable('${name}', 'User')"`, 
        { encoding: 'utf-8' }).trim()
      if (result && result !== '') {
        return result
      }
    } catch (error) {
      // Silently ignore errors, fallback to undefined
    }
  }
  
  return undefined
}

// https://vite.dev/config/
export default defineConfig(({ mode }) => ({
  plugins: [
    vue(),
    vueDevTools(),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    },
  },
  // Use /sportsmadness/ for production (GitHub Pages), / for development
  base: mode === 'production' ? '/sportsmadness/' : '/',
  build: {
    outDir: 'dist',
    sourcemap: false,
    // Clear output directory before build to prevent stale files
    emptyOutDir: true,
    rollupOptions: {
      output: {
        // Use shorter hashes but ensure they change with content
        chunkFileNames: 'assets/[name]-[hash].js',
        entryFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash].[ext]',
        // Ensure proper code splitting
        manualChunks(id) {
          if (id.includes('node_modules')) {
            return 'vendor'
          }
          // Remove ScoreboardView specific chunking since we're using static import
        }
      }
    },
    // Improve asset handling for better reliability
    assetsInlineLimit: 0, // Don't inline any assets to avoid base64 issues
    cssCodeSplit: true,
    minify: 'esbuild' // Use esbuild instead of terser to avoid dependency issues
  },
  // Prioritize system/user environment variables over .env files
  define: {
    __VITE_SUPABASE_URL__: JSON.stringify(
      getEnvVar('VITE_SUPABASE_URL')
    ),
    __VITE_SUPABASE_ANON_KEY__: JSON.stringify(
      getEnvVar('VITE_SUPABASE_ANON_KEY')
    )
  },
  // Enable environment variable loading
  envPrefix: 'VITE_'
}))
