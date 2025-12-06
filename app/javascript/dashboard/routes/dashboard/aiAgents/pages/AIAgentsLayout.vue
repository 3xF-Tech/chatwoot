<script setup>
// AIAgentsLayout - Wrapper component for AI Agents module
// Provides consistent layout for Dashboard, MyAgents, and Marketplace pages
</script>

<template>
  <div
    class="flex flex-col w-full h-full m-0 p-6 sm:py-8 lg:px-16 overflow-auto bg-n-background font-inter"
  >
    <div class="flex flex-col items-start w-full max-w-7xl mx-auto">
      <router-view />
    </div>
  </div>
</template>
