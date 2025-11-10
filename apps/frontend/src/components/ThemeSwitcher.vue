<template>
  <div class="relative" ref="themeSwitcherRef">
    <button
      @click="showDropdown = !showDropdown"
      class="flex items-center justify-center w-10 h-10 rounded-lg transition-colors hover:bg-white/10"
      :title="$t('theme.switchTheme')"
    >
      <!-- Logo or Icon for current theme -->
      <img 
        v-if="themeStore.currentTheme?.logo" 
        :src="themeStore.currentTheme.logo" 
        :alt="themeStore.currentTheme.name"
        class="w-6 h-6 rounded-full"
      />
      <div v-else class="w-6 h-6 rounded-full bg-gradient-to-br from-blue-500 to-purple-600"></div>
    </button>
    
    <!-- Theme Dropdown -->
    <div 
      v-show="showDropdown"
      class="absolute right-0 mt-2 w-64 bg-white/95 backdrop-blur-sm rounded-lg shadow-lg border border-white/20 py-2 z-50"
    >
      <div class="px-3 py-2 text-xs font-semibold text-gray-600 uppercase tracking-wider border-b border-gray-200 mb-2">
        {{ $t('theme.selectTheme') }}
      </div>
      
      <button
        v-for="theme in themeStore.availableThemes"
        :key="theme.id"
        @click="selectTheme(theme.id)"
        class="w-full px-3 py-2 text-left hover:bg-gray-100 transition-colors flex items-center space-x-3"
        :class="{ 'bg-blue-50 text-blue-600': themeStore.currentThemeId === theme.id }"
      >
        <!-- Theme preview -->
        <div class="relative">
          <img 
            v-if="theme.logo" 
            :src="theme.logo" 
            :alt="theme.name"
            class="w-8 h-8 rounded-full border-2"
            :style="{ borderColor: theme.colors.primary }"
          />
          <div 
            v-else 
            class="w-8 h-8 rounded-full border-2 flex items-center justify-center text-xs font-bold text-white"
            :style="{ 
              backgroundColor: theme.colors.primary,
              borderColor: theme.colors.secondary 
            }"
          >
            {{ theme.name.charAt(0) }}
          </div>
          
          <!-- Active indicator -->
          <div 
            v-if="themeStore.currentThemeId === theme.id"
            class="absolute -top-1 -right-1 w-3 h-3 bg-green-500 border-2 border-white rounded-full"
          ></div>
        </div>
        
        <div class="flex-1">
          <div class="font-medium text-gray-900">{{ theme.name }}</div>
          <div class="text-xs text-gray-500 flex items-center space-x-2">
            <span 
              class="w-3 h-3 rounded-full"
              :style="{ backgroundColor: theme.colors.primary }"
            ></span>
            <span 
              class="w-3 h-3 rounded-full"
              :style="{ backgroundColor: theme.colors.secondary }"
            ></span>
            <span 
              class="w-3 h-3 rounded-full"
              :style="{ backgroundColor: theme.colors.accent }"
            ></span>
          </div>
        </div>
        
        <!-- Check mark for active theme -->
        <svg 
          v-if="themeStore.currentThemeId === theme.id"
          class="w-5 h-5 text-green-500"
          fill="currentColor" 
          viewBox="0 0 20 20"
        >
          <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
        </svg>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useThemeStore } from '@/stores/theme'

const themeStore = useThemeStore()
const showDropdown = ref(false)
const themeSwitcherRef = ref<HTMLElement>()

function selectTheme(themeId: string) {
  themeStore.changeTheme(themeId)
  showDropdown.value = false
}

// Close dropdown when clicking outside
function handleClickOutside(event: Event) {
  if (themeSwitcherRef.value && !themeSwitcherRef.value.contains(event.target as Node)) {
    showDropdown.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>

<style scoped>
/* Additional styling for theme previews if needed */
</style>