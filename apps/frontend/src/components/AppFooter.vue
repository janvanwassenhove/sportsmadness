<template>
  <footer class="bg-gradient-to-r from-blue-900 via-purple-900 to-indigo-900 text-white py-6 mt-auto">
    <div class="container mx-auto px-4">
      <div class="flex flex-col md:flex-row items-center justify-between space-y-4 md:space-y-0">
        <!-- Left side - App info -->
        <div class="text-center md:text-left">
          <div class="flex items-center justify-center md:justify-start space-x-2 mb-2">
            <span class="text-xl">🏑</span>
            <span class="font-bold">Hockey Madness</span>
          </div>
          <p class="text-sm text-blue-200">{{ $t('footer.subtitle') }}</p>
        </div>

        <!-- Center - References -->
        <div class="flex flex-col md:flex-row items-center space-y-2 md:space-y-0 md:space-x-6">
          <div class="text-center">
            <p class="text-xs text-blue-300 mb-1">{{ $t('footer.poweredBy') }}</p>
            <a 
              href="https://mityjohn.com/" 
              target="_blank" 
              rel="noopener noreferrer"
              class="text-blue-200 hover:text-white transition-colors duration-200 text-sm font-medium"
            >
              MityJohn.com
            </a>
          </div>
          
          <div class="hidden md:block w-px h-8 bg-blue-700"></div>
          
          <div class="text-center">
            <p class="text-xs text-blue-300 mb-1">{{ $t('footer.officialSite') }}</p>
            <a 
              href="https://www.hockeylokeren.be/" 
              target="_blank" 
              rel="noopener noreferrer"
              class="text-blue-200 hover:text-white transition-colors duration-200 text-sm font-medium"
            >
              HC Lokeren
            </a>
          </div>
        </div>

        <!-- Right side - Copyright -->
        <div class="text-center md:text-right">
          <p class="text-xs text-blue-300">
            © {{ currentYear }} {{ $t('footer.copyright') }}
          </p>
        </div>
      </div>
    </div>
  </footer>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n()

const currentYear = computed(() => new Date().getFullYear())
</script>

<style scoped>
footer {
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

a:hover {
  text-decoration: underline;
}
</style>