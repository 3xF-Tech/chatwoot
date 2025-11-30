<script setup>
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import Sidebar from './components/CalendarSidebar.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();

const accountId = computed(() => route.params.accountId);

onMounted(async () => {
  await store.dispatch('calendarIntegrations/get');
});
</script>

<template>
  <div class="flex h-full w-full">
    <Sidebar />
    <div class="flex-1 overflow-auto bg-n-background">
      <router-view />
    </div>
  </div>
</template>
