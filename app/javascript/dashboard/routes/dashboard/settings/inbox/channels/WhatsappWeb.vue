<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import evolutionApi from 'dashboard/api/evolutionApi';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const router = useRouter();
const { t } = useI18n();
const { accountId } = useAccount();

// Form state
const inboxName = ref('');
const instanceName = ref('');
const phoneNumber = ref('');

// Settings
const rejectCalls = ref(true);
const ignoreGroups = ref(true);
const alwaysOnline = ref(true);
const readMessages = ref(true);
const syncFullHistory = ref(true);

// Connection state
const isLoading = ref(false);
const isCreatingInstance = ref(false);
const qrCodeData = ref(null);
const connectionStatus = ref('idle'); // idle, creating, waiting_qr, connected, error
const errorMessage = ref('');
const statusCheckInterval = ref(null);
const createdInstanceName = ref(null); // Store the instance name after creation

// Steps
const STEPS = {
  FORM: 'form',
  QR_CODE: 'qr_code',
  CONNECTED: 'connected',
};
const currentStep = ref(STEPS.FORM);

const isFormValid = computed(() => {
  return inboxName.value.trim() !== '' && 
         instanceName.value.trim() !== '' && 
         !instanceName.value.includes(' ') &&
         phoneNumber.value.trim() !== '' &&
         /^\+\d{10,15}$/.test(phoneNumber.value.replace(/\s/g, ''));
});

const sanitizedInstanceName = computed(() => {
  return instanceName.value.replace(/\s+/g, '_').toLowerCase();
});

const createInstance = async () => {
  if (!isFormValid.value) return;

  isCreatingInstance.value = true;
  connectionStatus.value = 'creating';
  errorMessage.value = '';

  try {
    const response = await evolutionApi.createInstance({
      instance_name: sanitizedInstanceName.value,
      inbox_name: inboxName.value,
      phone_number: phoneNumber.value.replace(/\s/g, ''),
      reject_call: rejectCalls.value,
      groups_ignore: ignoreGroups.value,
      always_online: alwaysOnline.value,
      read_messages: readMessages.value,
      sync_full_history: syncFullHistory.value,
    });

    if (response.data.success) {
      createdInstanceName.value = response.data.instance_name;
      qrCodeData.value = response.data.qrcode;
      currentStep.value = STEPS.QR_CODE;
      connectionStatus.value = 'waiting_qr';
      // Note: Status polling removed - Evolution API will create inbox automatically when connected
      useAlert(t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION.WAITING_QR'));
    } else {
      throw new Error(response.data.error || 'Failed to create instance');
    }
  } catch (error) {
    console.error('Error creating instance:', error);
    errorMessage.value = error.response?.data?.error || error.message || t('INBOX_MGMT.ADD.WHATSAPP_WEB.API.ERROR_INSTANCE');
    connectionStatus.value = 'error';
    useAlert(errorMessage.value);
  } finally {
    isCreatingInstance.value = false;
  }
};

const refreshQrCode = async () => {
  if (!createdInstanceName.value) return;

  isLoading.value = true;
  errorMessage.value = '';

  try {
    // For now, we can't refresh QR code without Evolution API endpoint for instance-based refresh
    // The user should restart the process if QR expires
    useAlert(t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION.QR_EXPIRED'));
  } catch (error) {
    console.error('Error refreshing QR code:', error);
    errorMessage.value = t('INBOX_MGMT.ADD.WHATSAPP_WEB.API.ERROR_QR');
    useAlert(errorMessage.value);
  } finally {
    isLoading.value = false;
  }
};

// Simplified - Evolution API creates inbox automatically when WhatsApp connects
const goToInboxList = () => {
  router.push({
    name: 'settings_inbox_list',
    params: { accountId: accountId.value },
  });
};

const startStatusPolling = () => {
  // Not needed - Evolution API handles connection status
};

const stopStatusPolling = () => {
  if (statusCheckInterval.value) {
    clearInterval(statusCheckInterval.value);
    statusCheckInterval.value = null;
  }
};

const goBack = () => {
  if (currentStep.value === STEPS.QR_CODE) {
    stopStatusPolling();
    currentStep.value = STEPS.FORM;
    qrCodeData.value = null;
  } else {
    router.back();
  }
};

onMounted(() => {
  // Generate a default instance name based on timestamp
  instanceName.value = `whatsapp_${Date.now()}`;
});

onUnmounted(() => {
  stopStatusPolling();
});
</script>

<template>
  <div class="overflow-auto col-span-6 p-6 w-full h-full">
    <div class="max-w-2xl mx-auto">
      <!-- Header -->
      <div class="mb-8 text-left">
        <h1 class="mb-2 text-lg font-medium text-n-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.TITLE') }}
        </h1>
        <p class="text-sm leading-relaxed text-n-slate-11">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.DESC') }}
        </p>
      </div>

      <!-- Step 1: Form -->
      <form v-if="currentStep === 'form'" class="space-y-6" @submit.prevent="createInstance">
        <div class="p-6 rounded-2xl border border-n-weak bg-n-alpha-1">
          <!-- Inbox Name -->
          <div class="flex-shrink-0 flex-grow-0 mb-6">
            <label :class="{ error: !inboxName.trim() && inboxName !== '' }">
              {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.INBOX_NAME.LABEL') }}
              <input
                v-model="inboxName"
                type="text"
                :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.INBOX_NAME.PLACEHOLDER')"
              />
              <span v-if="!inboxName.trim() && inboxName !== ''" class="message">
                {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.INBOX_NAME.ERROR') }}
              </span>
            </label>
          </div>

          <!-- Instance Name -->
          <div class="flex-shrink-0 flex-grow-0 mb-6">
            <label :class="{ error: instanceName.includes(' ') }">
              {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.INSTANCE_NAME.LABEL') }}
              <input
                v-model="instanceName"
                type="text"
                :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.INSTANCE_NAME.PLACEHOLDER')"
              />
              <span v-if="instanceName.includes(' ')" class="message">
                {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.INSTANCE_NAME.ERROR') }}
              </span>
              <p v-if="instanceName && !instanceName.includes(' ')" class="mt-1 text-xs text-n-slate-10">
                Instance ID: {{ sanitizedInstanceName }}
              </p>
            </label>
          </div>

          <!-- Phone Number -->
          <div class="flex-shrink-0 flex-grow-0 mb-6">
            <label :class="{ error: phoneNumber && !/^\+\d{10,15}$/.test(phoneNumber.replace(/\s/g, '')) }">
              {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.PHONE_NUMBER.LABEL') }}
              <input
                v-model="phoneNumber"
                type="tel"
                :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.PHONE_NUMBER.PLACEHOLDER')"
              />
              <span v-if="phoneNumber && !/^\+\d{10,15}$/.test(phoneNumber.replace(/\s/g, ''))" class="message">
                {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.PHONE_NUMBER.ERROR') }}
              </span>
              <p class="mt-1 text-xs text-n-slate-10">
                {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.PHONE_NUMBER.HELP') }}
              </p>
            </label>
          </div>

          <!-- Settings -->
          <div class="pt-6 border-t border-n-weak">
            <h3 class="mb-4 text-sm font-medium text-n-slate-12">
              Configurações
            </h3>
            <div class="space-y-3">
              <label class="flex items-center gap-3 cursor-pointer">
                <input
                  v-model="rejectCalls"
                  type="checkbox"
                  class="w-4 h-4 rounded border-n-weak text-woot-500 focus:ring-woot-500"
                />
                <span class="text-sm text-n-slate-11">
                  {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.SETTINGS.REJECT_CALLS') }}
                </span>
              </label>
              <label class="flex items-center gap-3 cursor-pointer">
                <input
                  v-model="ignoreGroups"
                  type="checkbox"
                  class="w-4 h-4 rounded border-n-weak text-woot-500 focus:ring-woot-500"
                />
                <span class="text-sm text-n-slate-11">
                  {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.SETTINGS.IGNORE_GROUPS') }}
                </span>
              </label>
              <label class="flex items-center gap-3 cursor-pointer">
                <input
                  v-model="alwaysOnline"
                  type="checkbox"
                  class="w-4 h-4 rounded border-n-weak text-woot-500 focus:ring-woot-500"
                />
                <span class="text-sm text-n-slate-11">
                  {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.SETTINGS.ALWAYS_ONLINE') }}
                </span>
              </label>
              <label class="flex items-center gap-3 cursor-pointer">
                <input
                  v-model="readMessages"
                  type="checkbox"
                  class="w-4 h-4 rounded border-n-weak text-woot-500 focus:ring-woot-500"
                />
                <span class="text-sm text-n-slate-11">
                  {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.SETTINGS.READ_MESSAGES') }}
                </span>
              </label>
              <label class="flex items-center gap-3 cursor-pointer">
                <input
                  v-model="syncFullHistory"
                  type="checkbox"
                  class="w-4 h-4 rounded border-n-weak text-woot-500 focus:ring-woot-500"
                />
                <span class="text-sm text-n-slate-11">
                  {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.SETTINGS.SYNC_HISTORY') }}
                </span>
              </label>
            </div>
          </div>
        </div>

        <!-- Error Message -->
        <div v-if="errorMessage" class="p-4 rounded-lg bg-r-50 border border-r-200">
          <p class="text-sm text-r-700">{{ errorMessage }}</p>
        </div>

        <!-- Actions -->
        <div class="w-full mt-4">
          <NextButton
            :is-loading="isCreatingInstance"
            :disabled="!isFormValid || isCreatingInstance"
            type="submit"
            solid
            blue
            :label="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.SUBMIT_BUTTON')"
          />
        </div>
      </form>

      <!-- Step 2: QR Code -->
      <div v-else-if="currentStep === 'qr_code'" class="space-y-6">
        <div class="p-6 rounded-2xl border border-n-weak bg-n-alpha-1">
          <h2 class="mb-4 text-base font-medium text-n-slate-12">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION.TITLE') }}
          </h2>
          <p class="mb-6 text-sm text-n-slate-11">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION.SCAN_INSTRUCTIONS') }}
          </p>

          <!-- QR Code Display -->
          <div class="flex flex-col items-center justify-center p-8 bg-white rounded-xl">
            <div v-if="isLoading" class="flex items-center justify-center w-64 h-64">
              <Spinner size="large" />
            </div>
            <div v-else-if="qrCodeData" class="w-64 h-64">
              <!-- If qrCodeData is base64 -->
              <img
                v-if="qrCodeData.startsWith('data:') || qrCodeData.startsWith('iVBOR')"
                :src="qrCodeData.startsWith('data:') ? qrCodeData : `data:image/png;base64,${qrCodeData}`"
                alt="QR Code"
                class="w-full h-full object-contain"
              />
              <!-- If qrCodeData is a QR code string, show as text (fallback) -->
              <div v-else class="w-full h-full flex items-center justify-center bg-n-alpha-1 rounded-lg">
                <p class="text-xs text-n-slate-10 text-center break-all p-4">{{ qrCodeData }}</p>
              </div>
            </div>
            <div v-else class="flex items-center justify-center w-64 h-64 bg-n-alpha-1 rounded-lg">
              <p class="text-sm text-n-slate-11">
                {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION.WAITING_QR') }}
              </p>
            </div>
          </div>

          <!-- Status -->
          <div class="mt-6 text-center">
            <div class="flex items-center justify-center gap-2">
              <span
                class="w-2 h-2 rounded-full"
                :class="{
                  'bg-y-500 animate-pulse': connectionStatus === 'waiting_qr',
                  'bg-g-500': connectionStatus === 'connected',
                  'bg-r-500': connectionStatus === 'error',
                }"
              />
              <span class="text-sm text-n-slate-11">
                {{ connectionStatus === 'waiting_qr' ? $t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION.STATUS.WAITING') : connectionStatus }}
              </span>
            </div>
          </div>

          <!-- Refresh Button -->
          <div class="mt-6 flex justify-center gap-3">
            <NextButton
              :disabled="isLoading"
              :is-loading="isLoading"
              :label="$t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION.REFRESH_QR')"
              @click="refreshQrCode"
            />
          </div>

          <!-- Info message -->
          <div class="mt-4 p-4 rounded-lg bg-b-50 border border-b-200">
            <p class="text-sm text-b-700 text-center">
              Após escanear o QR Code, a inbox será criada automaticamente. Clique no botão abaixo para ver suas inboxes.
            </p>
          </div>
        </div>

        <!-- Actions -->
        <div class="flex gap-3 justify-start mt-4">
          <NextButton
            :label="$t('GENERAL_SETTINGS.BACK')"
            @click="goBack"
          />
          <NextButton
            solid
            blue
            label="Ir para Inboxes"
            @click="goToInboxList"
          />
        </div>
      </div>

      <!-- Step 3: Connected -->
      <div v-else-if="currentStep === 'connected'" class="space-y-6">
        <div class="p-8 rounded-2xl border border-g-200 bg-g-50 text-center">
          <div class="flex items-center justify-center w-16 h-16 mx-auto mb-4 rounded-full bg-g-100">
            <span class="i-lucide-check text-g-600 text-2xl" />
          </div>
          <h2 class="mb-2 text-lg font-medium text-g-800">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION.STATUS.CONNECTED') }}
          </h2>
          <p class="text-sm text-g-600">
            {{ $t('INBOX_MGMT.ADD.FINISH.MESSAGE') }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
