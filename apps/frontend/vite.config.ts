import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

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
    rollupOptions: {
      output: {
        chunkFileNames: 'assets/[name]-[hash].js',
        entryFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash].[ext]'
      }
    }
  },
  // Prioritize system environment variables over .env files
  define: {
    __VITE_SUPABASE_URL__: JSON.stringify(
      process.env.VITE_SUPABASE_URL
    ),
    __VITE_SUPABASE_ANON_KEY__: JSON.stringify(
      process.env.VITE_SUPABASE_ANON_KEY 
    )
  },
  // Enable environment variable loading
  envPrefix: 'VITE_'
}))
