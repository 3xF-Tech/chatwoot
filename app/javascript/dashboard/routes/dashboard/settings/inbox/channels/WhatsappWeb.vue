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

// LocalStorage key for persisting state
const STORAGE_KEY = 'whatsapp_web_inbox_creation';

// Form state
const inboxName = ref('');
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
const createdInboxId = ref(null); // Store the inbox ID after creation

// Steps
const STEPS = {
  FORM: 'form',
  QR_CODE: 'qr_code',
  CONNECTED: 'connected',
};
const currentStep = ref(STEPS.FORM);

// Phone number validation - accepts with or without +, 10-15 digits
const isValidPhoneNumber = computed(() => {
  const cleaned = phoneNumber.value.replace(/[\s\-\(\)]/g, '');
  return /^\+?\d{10,15}$/.test(cleaned);
});

const isFormValid = computed(() => {
  return inboxName.value.trim() !== '' && 
         phoneNumber.value.trim() !== '' &&
         isValidPhoneNumber.value;
});

// Instance name will be derived from phone number (cleaned)
const sanitizedInstanceName = computed(() => {
  // Remove all non-digit characters and use as instance name
  return phoneNumber.value.replace(/\D/g, '');
});

// Persist state to localStorage
const saveState = () => {
  const state = {
    inboxId: createdInboxId.value,
    inboxName: inboxName.value,
    phoneNumber: phoneNumber.value,
    step: currentStep.value,
    timestamp: Date.now(),
  };
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
};

// Clear persisted state
const clearState = () => {
  localStorage.removeItem(STORAGE_KEY);
};

// Restore state from localStorage
const restoreState = async () => {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (!saved) return false;

    const state = JSON.parse(saved);
    
    // Check if state is not too old (max 30 minutes)
    const maxAge = 30 * 60 * 1000; // 30 minutes
    if (Date.now() - state.timestamp > maxAge) {
      clearState();
      return false;
    }

    // Check if we have an inbox ID and were in QR code step
    if (state.inboxId && state.step === STEPS.QR_CODE) {
      // Verify the inbox still exists and get its status
      try {
        const response = await evolutionApi.getConnectionStatus(state.inboxId);
        
        if (response.data.state === 'open' || response.data.connected) {
          // Already connected - go to connected step
          createdInboxId.value = state.inboxId;
          inboxName.value = state.inboxName || '';
          phoneNumber.value = state.phoneNumber || '';
          currentStep.value = STEPS.CONNECTED;
          connectionStatus.value = 'connected';
          clearState();
          return true;
        }
        
        // Not connected - restore and show QR code
        createdInboxId.value = state.inboxId;
        inboxName.value = state.inboxName || '';
        phoneNumber.value = state.phoneNumber || '';
        currentStep.value = STEPS.QR_CODE;
        connectionStatus.value = 'waiting_qr';
        
        // Fetch QR code and start polling
        await refreshQrCode();
        startStatusPolling();
        
        return true;
      } catch {
        // Inbox might have been deleted or error occurred
        clearState();
        return false;
      }
    }

    return false;
  } catch {
    clearState();
    return false;
  }
};

const createInstance = async () => {
  if (!isFormValid.value) return;

  isCreatingInstance.value = true;
  connectionStatus.value = 'creating';
  errorMessage.value = '';

  try {
    // Clean phone number - remove spaces, dashes, parentheses
    const cleanedPhone = phoneNumber.value.replace(/[\s\-\(\)]/g, '');
    
    const response = await evolutionApi.createInstance({
      instance_name: sanitizedInstanceName.value,
      inbox_name: inboxName.value,
      phone_number: cleanedPhone,
      reject_call: rejectCalls.value,
      groups_ignore: ignoreGroups.value,
      always_online: alwaysOnline.value,
      read_messages: readMessages.value,
      sync_full_history: syncFullHistory.value,
    });

    if (response.data.success) {
      createdInboxId.value = response.data.inbox_id;
      qrCodeData.value = response.data.qrcode;
      currentStep.value = STEPS.QR_CODE;
      connectionStatus.value = 'waiting_qr';
      
      // Save state to localStorage for recovery on page refresh
      saveState();
      
      // Start polling for connection status
      startStatusPolling();
      
      // If no QR code returned, fetch it
      if (!qrCodeData.value && createdInboxId.value) {
        await refreshQrCode();
      }
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
  if (!createdInboxId.value) return;

  isLoading.value = true;
  errorMessage.value = '';

  try {
    const response = await evolutionApi.getQrCode(createdInboxId.value);
    
    if (response.data.base64) {
      qrCodeData.value = response.data.base64;
    } else if (response.data.state === 'open') {
      connectionStatus.value = 'connected';
      currentStep.value = STEPS.CONNECTED;
      stopStatusPolling();
      clearState(); // Clear saved state on successful connection
      useAlert(t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION.STATUS.CONNECTED'));
    } else {
      errorMessage.value = t('INBOX_MGMT.ADD.WHATSAPP_WEB.API.ERROR_QR');
    }
  } catch (error) {
    console.error('Error refreshing QR code:', error);
    errorMessage.value = error.response?.data?.error || t('INBOX_MGMT.ADD.WHATSAPP_WEB.API.ERROR_QR');
    useAlert(errorMessage.value);
  } finally {
    isLoading.value = false;
  }
};

const goToInboxList = () => {
  router.push({
    name: 'settings_inbox_list',
    params: { accountId: accountId.value },
  });
};

const goToInboxSettings = () => {
  if (createdInboxId.value) {
    router.push({
      name: 'settings_inbox_show',
      params: { accountId: accountId.value, inboxId: createdInboxId.value },
    });
  }
};

const startStatusPolling = () => {
  stopStatusPolling();
  statusCheckInterval.value = setInterval(async () => {
    if (!createdInboxId.value) return;
    
    try {
      const response = await evolutionApi.getConnectionStatus(createdInboxId.value);
      if (response.data.state === 'open' || response.data.connected) {
        connectionStatus.value = 'connected';
        currentStep.value = STEPS.CONNECTED;
        stopStatusPolling();
        clearState(); // Clear saved state on successful connection
        useAlert(t('INBOX_MGMT.ADD.WHATSAPP_WEB.CONNECTION.STATUS.CONNECTED'));
      }
    } catch (error) {
      console.error('Error checking status:', error);
    }
  }, 5000);
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
    clearState(); // Clear saved state when going back
    currentStep.value = STEPS.FORM;
    qrCodeData.value = null;
    createdInboxId.value = null;
  } else {
    router.back();
  }
};

onMounted(async () => {
  // Try to restore state from previous session (e.g., page refresh during QR code step)
  isLoading.value = true;
  try {
    await restoreState();
  } finally {
    isLoading.value = false;
  }
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

          <!-- Phone Number -->
          <div class="flex-shrink-0 flex-grow-0 mb-6">
            <label :class="{ error: phoneNumber && !isValidPhoneNumber }">
              {{ $t('INBOX_MGMT.ADD.WHATSAPP_WEB.PHONE_NUMBER.LABEL') }}
              <input
                v-model="phoneNumber"
                type="tel"
                placeholder="5511999999999"
              />
              <span v-if="phoneNumber && !isValidPhoneNumber" class="message">
                Digite um número válido (10-15 dígitos)
              </span>
              <p class="mt-1 text-xs text-n-slate-10">
                Número do WhatsApp que será conectado (com código do país, ex: 5511999999999)
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
