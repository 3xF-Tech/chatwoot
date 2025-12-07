<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import EvolutionApi from 'dashboard/api/evolutionApi';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const connectionStatus = ref('unknown');
const isLoading = ref(false);
const qrCode = ref('');
const errorMessage = ref('');
let pollingInterval = null;

const statusIcon = computed(() => {
  switch (connectionStatus.value) {
    case 'open':
      return 'i-lucide-check-circle';
    case 'connecting':
      return 'i-lucide-loader';
    case 'close':
      return 'i-lucide-x-circle';
    default:
      return 'i-lucide-help-circle';
  }
});

const statusColor = computed(() => {
  switch (connectionStatus.value) {
    case 'open':
      return 'text-green-500';
    case 'connecting':
      return 'text-yellow-500';
    case 'close':
      return 'text-red-500';
    default:
      return 'text-slate-500';
  }
});

const statusText = computed(() => {
  switch (connectionStatus.value) {
    case 'open':
      return t('INBOX_MGMT.WHATSAPP_WEB.STATUS.CONNECTED');
    case 'connecting':
      return t('INBOX_MGMT.WHATSAPP_WEB.STATUS.CONNECTING');
    case 'close':
      return t('INBOX_MGMT.WHATSAPP_WEB.STATUS.DISCONNECTED');
    default:
      return t('INBOX_MGMT.WHATSAPP_WEB.STATUS.UNKNOWN');
  }
});

const instanceName = computed(() => {
  return props.inbox.channel?.instance_name || '';
});

const inboxId = computed(() => {
  return props.inbox.id;
});

async function fetchConnectionStatus() {
  if (!inboxId.value) return;

  try {
    isLoading.value = true;
    const response = await EvolutionApi.getConnectionStatus(inboxId.value);
    connectionStatus.value = response.data.state || 'unknown';
    errorMessage.value = '';
  } catch (error) {
    console.error('Error fetching connection status:', error);
    connectionStatus.value = 'unknown';
    errorMessage.value =
      error.response?.data?.error ||
      t('INBOX_MGMT.WHATSAPP_WEB.ERROR.FETCH_STATUS');
  } finally {
    isLoading.value = false;
  }
}

async function fetchQrCode() {
  if (!inboxId.value) return;

  try {
    isLoading.value = true;
    qrCode.value = '';
    errorMessage.value = '';

    const response = await EvolutionApi.getQrCode(inboxId.value);

    if (response.data.base64) {
      qrCode.value = response.data.base64;
      startPolling();
    } else if (response.data.state === 'open') {
      connectionStatus.value = 'open';
      useAlert(t('INBOX_MGMT.WHATSAPP_WEB.SUCCESS.ALREADY_CONNECTED'));
    }
  } catch (error) {
    console.error('Error fetching QR code:', error);
    errorMessage.value =
      error.response?.data?.error ||
      t('INBOX_MGMT.WHATSAPP_WEB.ERROR.FETCH_QR');
  } finally {
    isLoading.value = false;
  }
}

async function disconnect() {
  if (!inboxId.value) return;

  try {
    isLoading.value = true;
    await EvolutionApi.disconnectInstance(inboxId.value);
    connectionStatus.value = 'close';
    useAlert(t('INBOX_MGMT.WHATSAPP_WEB.SUCCESS.DISCONNECTED'));
  } catch (error) {
    console.error('Error disconnecting:', error);
    errorMessage.value =
      error.response?.data?.error ||
      t('INBOX_MGMT.WHATSAPP_WEB.ERROR.DISCONNECT');
  } finally {
    isLoading.value = false;
  }
}

function startPolling() {
  stopPolling();
  pollingInterval = setInterval(async () => {
    await fetchConnectionStatus();
    if (connectionStatus.value === 'open') {
      qrCode.value = '';
      stopPolling();
      useAlert(t('INBOX_MGMT.WHATSAPP_WEB.SUCCESS.CONNECTED'));
    }
  }, 5000);
}

function stopPolling() {
  if (pollingInterval) {
    clearInterval(pollingInterval);
    pollingInterval = null;
  }
}

onMounted(() => {
  fetchConnectionStatus();
});

onUnmounted(() => {
  stopPolling();
});
</script>

<template>
  <div class="flex flex-col gap-6">
    <SettingsSection
      :title="$t('INBOX_MGMT.WHATSAPP_WEB.TITLE')"
      :sub-title="$t('INBOX_MGMT.WHATSAPP_WEB.DESCRIPTION')"
    >
      <div class="flex flex-col gap-4">
        <!-- Connection Status -->
        <div class="flex items-center gap-3 p-4 rounded-lg bg-slate-50 dark:bg-slate-800">
          <div class="flex items-center gap-2">
            <span
              :class="[statusColor, isLoading ? 'animate-spin' : '']"
              class="text-2xl"
            >
              <i :class="isLoading ? 'i-lucide-loader' : statusIcon" />
            </span>
            <div>
              <p class="font-medium text-slate-800 dark:text-slate-100">
                {{ $t('INBOX_MGMT.WHATSAPP_WEB.CONNECTION_STATUS') }}
              </p>
              <p :class="statusColor" class="text-sm">
                {{ statusText }}
              </p>
            </div>
          </div>
        </div>

        <!-- Error Message -->
        <div
          v-if="errorMessage"
          class="p-4 rounded-lg bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400"
        >
          {{ errorMessage }}
        </div>

        <!-- QR Code Section -->
        <div
          v-if="qrCode"
          class="flex flex-col items-center gap-4 p-6 rounded-lg bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700"
        >
          <p class="text-sm text-slate-600 dark:text-slate-400">
            {{ $t('INBOX_MGMT.WHATSAPP_WEB.SCAN_QR') }}
          </p>
          <img
            :src="qrCode"
            alt="QR Code"
            class="w-64 h-64 rounded-lg"
          />
          <p class="text-xs text-slate-500 dark:text-slate-500">
            {{ $t('INBOX_MGMT.WHATSAPP_WEB.QR_HELP') }}
          </p>
        </div>

        <!-- Action Buttons -->
        <div class="flex flex-wrap gap-3">
          <NextButton
            v-if="connectionStatus !== 'open'"
            :is-loading="isLoading"
            icon="i-lucide-qr-code"
            @click="fetchQrCode"
          >
            {{ $t('INBOX_MGMT.WHATSAPP_WEB.ACTIONS.SHOW_QR') }}
          </NextButton>

          <NextButton
            v-if="connectionStatus === 'open'"
            :is-loading="isLoading"
            variant="secondary"
            icon="i-lucide-log-out"
            color-scheme="alert"
            @click="disconnect"
          >
            {{ $t('INBOX_MGMT.WHATSAPP_WEB.ACTIONS.DISCONNECT') }}
          </NextButton>

          <NextButton
            :is-loading="isLoading"
            variant="ghost"
            icon="i-lucide-refresh-cw"
            @click="fetchConnectionStatus"
          >
            {{ $t('INBOX_MGMT.WHATSAPP_WEB.ACTIONS.REFRESH') }}
          </NextButton>
        </div>

        <!-- Instance Info -->
        <div class="mt-4 p-4 rounded-lg bg-slate-50 dark:bg-slate-800">
          <p class="text-sm text-slate-600 dark:text-slate-400">
            <span class="font-medium">{{ $t('INBOX_MGMT.WHATSAPP_WEB.INSTANCE_NAME') }}:</span>
            {{ instanceName }}
          </p>
          <p v-if="inbox.phone_number" class="text-sm text-slate-600 dark:text-slate-400 mt-1">
            <span class="font-medium">{{ $t('INBOX_MGMT.WHATSAPP_WEB.PHONE_NUMBER') }}:</span>
            {{ inbox.phone_number }}
          </p>
        </div>
      </div>
    </SettingsSection>
  </div>
</template>
