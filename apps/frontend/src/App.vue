<script setup lang="ts">
import { RouterView, useRoute } from 'vue-router'
import { computed } from 'vue'
import AppNavigation from '@/components/AppNavigation.vue'
import AppFooter from '@/components/AppFooter.vue'

const route = useRoute()

// Hide navigation and footer on scoreboard view for full-screen display
const showNavigationAndFooter = computed(() => {
  return route.name !== 'scoreboard' && route.name !== 'scoreboard-match'
})
</script>

<template>
  <div id="app" class="min-h-screen flex flex-col">
    <AppNavigation v-if="showNavigationAndFooter" />
    <main class="flex-1">
      <RouterView />
    </main>
    <AppFooter v-if="showNavigationAndFooter" />
  </div>
</template>

<style>
html, body {
  height: 100%;
  margin: 0;
  padding: 0;
}

#app {
  min-height: 100vh;
}
</style>
