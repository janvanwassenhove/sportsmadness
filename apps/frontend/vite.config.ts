import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    vueDevTools(),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    },
  },
  base: '/sportsmadness/',
  build: {
    outDir: 'dist',
    sourcemap: false,
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
})
