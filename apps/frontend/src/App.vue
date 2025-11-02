<script setup lang="ts">
import { RouterView, useRoute } from 'vue-router'
import { computed } from 'vue'
import AppNavigation from '@/components/AppNavigation.vue'

const route = useRoute()

// Hide navigation on scoreboard view for full-screen display
const showNavigation = computed(() => {
  return route.name !== 'scoreboard'
})
</script>

<template>
  <div id="app" style="min-height: 100vh;">
    <AppNavigation v-if="showNavigation" />
    <RouterView />
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
