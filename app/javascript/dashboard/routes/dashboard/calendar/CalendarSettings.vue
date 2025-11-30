<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';

const store = useStore();

// State
const isConnecting = ref(false);
const isLoaded = ref(false);

// Computed
const integrations = computed(
  () => store.getters['calendarIntegrations/getIntegrations'] || []
);

// Providers configuration - hardcoded to avoid translation issues
const providers = [
  {
    id: 'google',
    name: 'Google Calendar',
    icon: 'calendar',
    description: 'Sync events with your Google Calendar account',
    disabled: false,
    comingSoon: false,
  },
  {
    id: 'outlook',
    name: 'Microsoft Outlook',
    icon: 'mail',
    description: 'Sync events with your Microsoft Outlook calendar',
    disabled: true,
    comingSoon: true,
  },
  {
    id: 'calendly',
    name: 'Calendly',
    icon: 'clock',
    description: 'Connect Calendly for scheduling meetings',
    disabled: true,
    comingSoon: true,
  },
];

// Methods
const getIntegrationForProvider = providerId => {
  return integrations.value.find(i => i.provider === providerId);
};

const handleConnect = async providerId => {
  isConnecting.value = true;
  try {
    const response = await store.dispatch(
      'calendarIntegrations/getAuthUrl',
      providerId
    );
    if (response && response.auth_url) {
      window.location.href = response.auth_url;
    }
  } catch (error) {
    const errorMessage =
      error.message || 'Failed to connect. Please try again.';
    useAlert(errorMessage);
  } finally {
    isConnecting.value = false;
  }
};

const handleDisconnect = async integrationId => {
  if (confirm('Are you sure you want to disconnect this calendar?')) {
    try {
      await store.dispatch('calendarIntegrations/delete', integrationId);
      useAlert('Calendar disconnected successfully');
    } catch (error) {
      useAlert('Failed to disconnect. Please try again.');
    }
  }
};

const handleSync = async integrationId => {
  try {
    await store.dispatch('calendarIntegrations/sync', integrationId);
    useAlert('Sync started successfully');
  } catch (error) {
    useAlert('Failed to sync. Please try again.');
  }
};

// Lifecycle
onMounted(async () => {
  try {
    await store.dispatch('calendarIntegrations/get');
  } catch (error) {
    // Silently handle - integrations list will be empty
  } finally {
    isLoaded.value = true;
  }
});
</script>

<template>
  <div class="max-w-4xl p-6">
    <div class="mb-6">
      <h1 class="text-xl font-semibold text-n-slate-12">Calendar Settings</h1>
      <p class="mt-1 text-sm text-n-slate-11">
        Connect your calendar to sync events and never miss a meeting.
      </p>
    </div>

    <!-- Loading State -->
    <div v-if="!isLoaded" class="flex items-center justify-center py-8">
      <span class="text-n-slate-11">Loading...</span>
    </div>

    <!-- Providers List -->
    <div v-else class="space-y-4">
      <div
        v-for="provider in providers"
        :key="provider.id"
        class="rounded-lg border border-n-weak bg-n-alpha-1 p-4"
      >
        <div class="flex items-start justify-between">
          <div class="flex items-start gap-3">
            <div
              class="flex h-10 w-10 items-center justify-center rounded-lg bg-n-alpha-2"
            >
              <fluent-icon :icon="provider.icon" size="20" />
            </div>
            <div>
              <div class="flex items-center gap-2">
                <h3 class="font-medium text-n-slate-12">{{ provider.name }}</h3>
                <span
                  v-if="provider.comingSoon"
                  class="rounded bg-n-amber-3 px-2 py-0.5 text-xs text-n-amber-11"
                >
                  Coming Soon
                </span>
              </div>
              <p class="mt-1 text-sm text-n-slate-11">
                {{ provider.description }}
              </p>

              <div
                v-if="getIntegrationForProvider(provider.id)"
                class="mt-2 text-sm"
              >
                <span class="text-n-slate-11">Connected as: </span>
                <span class="font-medium text-n-slate-12">
                  {{ getIntegrationForProvider(provider.id).provider_email }}
                </span>
              </div>
            </div>
          </div>

          <div class="flex gap-2">
            <template v-if="getIntegrationForProvider(provider.id)">
              <Button
                variant="faint"
                size="sm"
                label="Sync"
                @click="handleSync(getIntegrationForProvider(provider.id).id)"
              />
              <Button
                variant="faint"
                size="sm"
                color="ruby"
                label="Disconnect"
                @click="
                  handleDisconnect(getIntegrationForProvider(provider.id).id)
                "
              />
            </template>
            <template v-else>
              <Button
                v-if="!provider.disabled"
                variant="solid"
                size="sm"
                color="blue"
                label="Connect"
                :is-loading="isConnecting"
                @click="handleConnect(provider.id)"
              />
              <Button
                v-else
                variant="faint"
                size="sm"
                label="Connect"
                disabled
              />
            </template>
          </div>
        </div>
      </div>
    </div>

    <!-- Info Section -->
    <div class="mt-8 rounded-lg border border-n-weak bg-n-alpha-1 p-4">
      <h2 class="text-base font-medium text-n-slate-12 mb-2">
        About Calendar Integration
      </h2>
      <p class="text-sm text-n-slate-11 mb-3">
        To connect Google Calendar, you need to configure OAuth credentials in
        your environment. Contact your administrator to set up the following
        environment variables:
      </p>
      <ul class="text-sm text-n-slate-11 space-y-1 list-disc list-inside">
        <li>
          <code class="bg-n-alpha-2 px-1 rounded"
            >GOOGLE_CALENDAR_CLIENT_ID</code
          >
        </li>
        <li>
          <code class="bg-n-alpha-2 px-1 rounded"
            >GOOGLE_CALENDAR_CLIENT_SECRET</code
          >
        </li>
      </ul>
    </div>
  </div>
</template>
