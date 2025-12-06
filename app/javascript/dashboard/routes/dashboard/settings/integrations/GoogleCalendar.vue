<script setup>
import { useI18n } from 'vue-i18n';
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  code: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();
const store = useStore();
const route = useRoute();

// State
const isConnecting = ref(false);
const isSyncing = ref(false);

// Computed
const integrations = computed(
  () => store.getters['calendarIntegrations/getIntegrations']
);
const isLoading = computed(
  () => store.getters['calendarIntegrations/getUIFlags'].isFetching
);
const googleIntegration = computed(() =>
  integrations.value.find(i => i.provider === 'google')
);

// Methods
const handleConnect = async () => {
  isConnecting.value = true;
  try {
    const response = await store.dispatch(
      'calendarIntegrations/getAuthUrl',
      'google'
    );
    if (response.auth_url) {
      window.location.href = response.auth_url;
    }
  } catch (error) {
    // Show the actual error message from the server
    const errorMessage =
      error.message ||
      t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.CONNECT_ERROR');
    useAlert(errorMessage);
  } finally {
    isConnecting.value = false;
  }
};

const handleDisconnect = async () => {
  if (confirm(t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.DISCONNECT_CONFIRM'))) {
    try {
      await store.dispatch(
        'calendarIntegrations/delete',
        googleIntegration.value.id
      );
      useAlert(t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.DISCONNECT_SUCCESS'));
    } catch (error) {
      useAlert(t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.DISCONNECT_ERROR'));
    }
  }
};

const handleSync = async () => {
  isSyncing.value = true;
  try {
    await store.dispatch(
      'calendarIntegrations/sync',
      googleIntegration.value.id
    );
    useAlert(t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.SYNC_SUCCESS'));
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.SYNC_ERROR'));
  } finally {
    isSyncing.value = false;
  }
};

const processOAuthCallback = async () => {
  if (props.code) {
    isConnecting.value = true;
    try {
      await store.dispatch('calendarIntegrations/handleCallback', {
        provider: 'google',
        code: props.code,
      });
      useAlert(t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.CONNECT_SUCCESS'));
      // Remove code from URL
      window.history.replaceState({}, '', window.location.pathname);
    } catch (error) {
      useAlert(t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.CONNECT_ERROR'));
    } finally {
      isConnecting.value = false;
    }
  }
};

// Lifecycle
onMounted(async () => {
  try {
    await store.dispatch('calendarIntegrations/get');
    processOAuthCallback();
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Failed to fetch calendar integrations:', error);
  }
});

watch(
  () => props.code,
  newCode => {
    if (newCode) {
      processOAuthCallback();
    }
  }
);

const formatDate = dateStr => {
  if (!dateStr) return '-';
  return new Date(dateStr).toLocaleString();
};
</script>

<template>
  <SettingsLayout :is-loading="isLoading">
    <template #header>
      <BaseSettingsHeader
        :title="$t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.TITLE')"
        :description="$t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.DESCRIPTION')"
        feature-name="google_calendar"
      />
    </template>
    <template #body>
      <div class="flex flex-col gap-6">
        <!-- Integration Card -->
        <div
          class="flex flex-col items-start justify-between lg:flex-row lg:items-center p-6 outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow gap-6"
        >
          <div
            class="flex items-start lg:items-center justify-start flex-1 m-0 gap-6 flex-col lg:flex-row"
          >
            <div class="flex h-16 w-16 items-center justify-center flex-shrink-0">
              <div
                class="flex h-14 w-14 items-center justify-center rounded-lg bg-n-alpha-2"
              >
                <fluent-icon icon="calendar" size="28" class="text-n-slate-11" />
              </div>
            </div>
            <div>
              <h3 class="mb-1 text-xl font-medium text-n-slate-12">
                Google Calendar
              </h3>
              <p class="text-n-slate-11 text-sm leading-6">
                {{ $t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.CARD_DESCRIPTION') }}
              </p>
            </div>
          </div>
          <div class="flex gap-2">
            <template v-if="googleIntegration">
              <Button
                variant="ghost"
                size="sm"
                :label="$t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.SYNC')"
                :is-loading="isSyncing"
                @click="handleSync"
              />
              <Button
                variant="ghost"
                size="sm"
                color="ruby"
                :label="$t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.DISCONNECT')"
                @click="handleDisconnect"
              />
            </template>
            <template v-else>
              <Button
                variant="solid"
                size="sm"
                color="blue"
                :label="$t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.CONNECT')"
                :is-loading="isConnecting"
                @click="handleConnect"
              />
            </template>
          </div>
        </div>

        <!-- Connected Account Info -->
        <div
          v-if="googleIntegration"
          class="rounded-lg border border-n-weak bg-n-alpha-1 p-6"
        >
          <h3 class="mb-4 font-medium text-n-slate-12">
            {{ $t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.CONNECTED_ACCOUNT') }}
          </h3>

          <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
            <div>
              <label class="text-xs font-medium text-n-slate-10">
                {{ $t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.EMAIL') }}
              </label>
              <p class="text-sm text-n-slate-12">
                {{ googleIntegration.provider_email }}
              </p>
            </div>
            <div>
              <label class="text-xs font-medium text-n-slate-10">
                {{ $t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.STATUS') }}
              </label>
              <p class="text-sm">
                <span
                  class="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs"
                  :class="
                    googleIntegration.sync_status === 'synced'
                      ? 'bg-n-teal-3 text-n-teal-11'
                      : 'bg-n-amber-3 text-n-amber-11'
                  "
                >
                  <span
                    class="h-1.5 w-1.5 rounded-full"
                    :class="
                      googleIntegration.sync_status === 'synced'
                        ? 'bg-n-teal-9'
                        : 'bg-n-amber-9'
                    "
                  />
                  {{ googleIntegration.sync_status }}
                </span>
              </p>
            </div>
            <div>
              <label class="text-xs font-medium text-n-slate-10">
                {{ $t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.LAST_SYNC') }}
              </label>
              <p class="text-sm text-n-slate-12">
                {{ formatDate(googleIntegration.last_synced_at) }}
              </p>
            </div>
            <div>
              <label class="text-xs font-medium text-n-slate-10">
                {{ $t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.CONNECTED_AT') }}
              </label>
              <p class="text-sm text-n-slate-12">
                {{ formatDate(googleIntegration.created_at) }}
              </p>
            </div>
          </div>
        </div>

        <!-- Features Section -->
        <div class="rounded-lg border border-n-weak bg-n-alpha-1 p-6">
          <h3 class="mb-4 font-medium text-n-slate-12">
            {{ $t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.FEATURES_TITLE') }}
          </h3>
          <ul class="space-y-3 text-sm text-n-slate-11">
            <li class="flex items-start gap-2">
              <fluent-icon
                icon="checkmark-circle"
                size="16"
                class="mt-0.5 text-n-teal-11"
              />
              {{ $t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.FEATURE_SYNC') }}
            </li>
            <li class="flex items-start gap-2">
              <fluent-icon
                icon="checkmark-circle"
                size="16"
                class="mt-0.5 text-n-teal-11"
              />
              {{ $t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.FEATURE_CREATE') }}
            </li>
            <li class="flex items-start gap-2">
              <fluent-icon
                icon="checkmark-circle"
                size="16"
                class="mt-0.5 text-n-teal-11"
              />
              {{ $t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.FEATURE_LINK') }}
            </li>
            <li class="flex items-start gap-2">
              <fluent-icon
                icon="checkmark-circle"
                size="16"
                class="mt-0.5 text-n-teal-11"
              />
              {{ $t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.FEATURE_REALTIME') }}
            </li>
          </ul>
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
