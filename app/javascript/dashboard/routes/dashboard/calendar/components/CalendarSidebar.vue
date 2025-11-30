<script setup>
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { computed } from 'vue';
import { useStore } from 'vuex';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();

const accountId = computed(() => route.params.accountId);

const integrations = computed(
  () => store.getters['calendarIntegrations/getIntegrations']
);

const menuItems = computed(() => [
  {
    key: 'calendar',
    label: t('CALENDAR.SIDEBAR.CALENDAR'),
    icon: 'calendar',
    to: `/app/accounts/${accountId.value}/calendar`,
  },
  {
    key: 'settings',
    label: t('CALENDAR.SIDEBAR.SETTINGS'),
    icon: 'settings',
    to: `/app/accounts/${accountId.value}/calendar/settings`,
  },
]);

const isActiveRoute = to => {
  return route.path === to;
};

const navigateTo = to => {
  router.push(to);
};
</script>

<template>
  <aside
    class="flex w-56 flex-col border-r border-n-weak bg-n-alpha-1 dark:bg-n-solid-1"
  >
    <div class="flex items-center justify-between p-4">
      <h2 class="text-lg font-semibold text-n-slate-12">
        {{ t('CALENDAR.TITLE') }}
      </h2>
    </div>

    <nav class="flex-1 space-y-1 p-2">
      <button
        v-for="item in menuItems"
        :key="item.key"
        class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm transition-colors"
        :class="
          isActiveRoute(item.to)
            ? 'bg-n-brand text-white'
            : 'text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12'
        "
        @click="navigateTo(item.to)"
      >
        <fluent-icon :icon="item.icon" size="16" />
        {{ item.label }}
      </button>
    </nav>

    <div class="border-t border-n-weak p-4">
      <h3 class="mb-2 text-xs font-medium uppercase text-n-slate-10">
        {{ t('CALENDAR.SIDEBAR.INTEGRATIONS') }}
      </h3>
      <div v-if="integrations.length === 0" class="text-sm text-n-slate-10">
        {{ t('CALENDAR.SIDEBAR.NO_INTEGRATIONS') }}
      </div>
      <div v-else class="space-y-2">
        <div
          v-for="integration in integrations"
          :key="integration.id"
          class="flex items-center gap-2 text-sm"
        >
          <span
            class="h-2 w-2 rounded-full"
            :class="
              integration.sync_status === 'synced'
                ? 'bg-n-teal-9'
                : 'bg-n-amber-9'
            "
          />
          <span class="truncate text-n-slate-11">
            {{ integration.provider_email }}
          </span>
        </div>
      </div>
    </div>
  </aside>
</template>
