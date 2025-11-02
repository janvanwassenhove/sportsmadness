<template>
  <div class="min-h-screen transition-colors duration-300" 
       :style="{ backgroundColor: themeStore.currentTheme?.colors.background }">
    <div class="container mx-auto px-4 py-16">
      <!-- Header -->
      <div class="text-center mb-16">
        <h1 class="text-6xl font-bold mb-6 font-theme-title"
            :style="{ color: themeStore.currentTheme?.colors.text }">
          🎨 Theme Demo
        </h1>
        <p class="text-xl max-w-2xl mx-auto font-theme-text"
           :style="{ color: themeStore.currentTheme?.colors.textSecondary }">
          Experience the different themes available in Hockey Madness
        </p>
      </div>

      <!-- Current Theme Info -->
      <div class="max-w-4xl mx-auto mb-12 p-8 rounded-xl transition-colors duration-300"
           :style="{ backgroundColor: themeStore.currentTheme?.colors.surface }">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-3xl font-bold font-theme-title"
              :style="{ color: themeStore.currentTheme?.colors.text }">
            Current Theme: {{ themeStore.currentTheme?.name }}
          </h2>
          <img 
            v-if="themeStore.currentTheme?.logo" 
            :src="themeStore.currentTheme.logo" 
            :alt="themeStore.currentTheme.name"
            class="w-16 h-16"
          />
        </div>
        
        <!-- Color Palette -->
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <div class="text-center">
            <div class="w-full h-20 rounded-lg mb-2 border-2 border-white/20"
                 :style="{ backgroundColor: themeStore.currentTheme?.colors.primary }"></div>
            <p class="text-sm font-theme-text"
               :style="{ color: themeStore.currentTheme?.colors.textSecondary }">
              Primary
            </p>
          </div>
          <div class="text-center">
            <div class="w-full h-20 rounded-lg mb-2 border-2 border-white/20"
                 :style="{ backgroundColor: themeStore.currentTheme?.colors.secondary }"></div>
            <p class="text-sm font-theme-text"
               :style="{ color: themeStore.currentTheme?.colors.textSecondary }">
              Secondary
            </p>
          </div>
          <div class="text-center">
            <div class="w-full h-20 rounded-lg mb-2 border-2 border-white/20"
                 :style="{ backgroundColor: themeStore.currentTheme?.colors.accent }"></div>
            <p class="text-sm font-theme-text"
               :style="{ color: themeStore.currentTheme?.colors.textSecondary }">
              Accent
            </p>
          </div>
          <div class="text-center">
            <div class="w-full h-20 rounded-lg mb-2 border-2 border-white/20"
                 :style="{ backgroundColor: themeStore.currentTheme?.colors.surface }"></div>
            <p class="text-sm font-theme-text"
               :style="{ color: themeStore.currentTheme?.colors.textSecondary }">
              Surface
            </p>
          </div>
        </div>

        <!-- Typography Demo -->
        <div class="space-y-4">
          <h3 class="text-2xl font-bold font-theme-title"
              :style="{ color: themeStore.currentTheme?.colors.text }">
            Typography Examples
          </h3>
          
          <div class="space-y-2">
            <h1 class="text-4xl font-theme-title"
                :style="{ color: themeStore.currentTheme?.colors.text }">
              Title Font (H1) - Used for main headings
            </h1>
            <h2 class="text-2xl font-theme-subtitle"
                :style="{ color: themeStore.currentTheme?.colors.text }">
              Subtitle Font (H2) - Used for section headers
            </h2>
            <a href="#" class="text-lg font-theme-links hover:opacity-80 transition-opacity"
               :style="{ color: themeStore.currentTheme?.colors.primary }">
              Links Font - Used for navigation and clickable elements
            </a>
            <p class="text-base font-theme-text leading-relaxed"
               :style="{ color: themeStore.currentTheme?.colors.textSecondary }">
              Text Font - Used for body text and general content. This paragraph demonstrates how the theme's text font appears in regular content areas. The font should be readable and comfortable for extended reading.
            </p>
          </div>
        </div>
      </div>

      <!-- Theme Selector -->
      <div class="max-w-2xl mx-auto text-center">
        <h3 class="text-2xl font-bold mb-6 font-theme-subtitle"
            :style="{ color: themeStore.currentTheme?.colors.text }">
          Switch Themes
        </h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <button
            v-for="theme in themeStore.availableThemes"
            :key="theme.id"
            @click="themeStore.changeTheme(theme.id)"
            class="p-6 rounded-xl transition-all duration-300 border-2 hover:scale-105"
            :class="{
              'ring-4 ring-opacity-50': themeStore.currentThemeId === theme.id
            }"
            :style="{ 
              backgroundColor: theme.colors.surface,
              borderColor: theme.colors.primary,
              color: theme.colors.text,
              '--tw-ring-color': theme.colors.primary
            }"
          >
            <div class="flex items-center justify-center mb-4">
              <img 
                v-if="theme.logo" 
                :src="theme.logo" 
                :alt="theme.name"
                class="w-12 h-12"
              />
              <div v-else class="w-12 h-12 rounded-full flex items-center justify-center text-white text-xl font-bold"
                   :style="{ backgroundColor: theme.colors.primary }">
                {{ theme.name.charAt(0) }}
              </div>
            </div>
            <h4 class="text-xl font-bold font-theme-title mb-2">{{ theme.name }}</h4>
            <div class="flex justify-center space-x-2">
              <div class="w-4 h-4 rounded-full border border-white/30"
                   :style="{ backgroundColor: theme.colors.primary }"></div>
              <div class="w-4 h-4 rounded-full border border-white/30"
                   :style="{ backgroundColor: theme.colors.secondary }"></div>
              <div class="w-4 h-4 rounded-full border border-white/30"
                   :style="{ backgroundColor: theme.colors.accent }"></div>
            </div>
          </button>
        </div>
      </div>

      <!-- Navigation -->
      <div class="text-center mt-12">
        <RouterLink 
          to="/"
          class="inline-flex items-center px-6 py-3 rounded-lg font-medium transition-colors font-theme-links"
          :style="{ 
            backgroundColor: themeStore.currentTheme?.colors.primary,
            color: themeStore.currentTheme?.colors.text
          }"
        >
          ← Back to Home
        </RouterLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useThemeStore } from '@/stores/theme'

const themeStore = useThemeStore()
</script>

<style scoped>
/* Any additional scoped styles if needed */
</style>