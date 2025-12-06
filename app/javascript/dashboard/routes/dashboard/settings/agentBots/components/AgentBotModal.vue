<script setup>
import { ref, computed, reactive, watch, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { required, helpers } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useToggle } from '@vueuse/core';

// Custom URL validator that accepts localhost and IP addresses
const isValidWebhookUrl = value => {
  if (!value) return true;
  try {
    const urlObj = new URL(value);
    return ['http:', 'https:'].includes(urlObj.protocol);
  } catch {
    return false;
  }
};

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import AccessToken from 'dashboard/routes/dashboard/settings/profile/AccessToken.vue';

const props = defineProps({
  type: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
  selectedBot: {
    type: Object,
    default: () => ({}),
  },
});

const MODAL_TYPES = {
  CREATE: 'create',
  EDIT: 'edit',
};

const RESPONSE_MODE_OPTIONS = [
  { id: 'auto_respond', name: 'AUTO_RESPOND' },
  { id: 'assist_agent', name: 'ASSIST_AGENT' },
  { id: 'manual_trigger', name: 'MANUAL_TRIGGER' },
];

const store = useStore();
const { t } = useI18n();
const dialogRef = ref(null);
const uiFlags = useMapGetter('agentBots/getUIFlags');
const inboxes = useMapGetter('inboxes/getInboxes');

const formState = reactive({
  botName: '',
  botDescription: '',
  botUrl: '',
  botAvatar: null,
  botAvatarUrl: '',
  contextPrompt: '',
  enableSignature: false,
  isActive: true,
  responseMode: 'auto_respond',
  selectedInboxes: [],
});

const [showAccessToken, toggleAccessToken] = useToggle();
const accessToken = ref('');

const v$ = useVuelidate(
  {
    botName: {
      required: helpers.withMessage(
        () => t('AGENT_BOTS.FORM.ERRORS.NAME'),
        required
      ),
    },
    botUrl: {
      required: helpers.withMessage(
        () => t('AGENT_BOTS.FORM.ERRORS.URL'),
        required
      ),
      isValidWebhookUrl: helpers.withMessage(
        () => t('AGENT_BOTS.FORM.ERRORS.VALID_URL'),
        isValidWebhookUrl
      ),
    },
  },
  formState
);

const isLoading = computed(() =>
  props.type === MODAL_TYPES.CREATE
    ? uiFlags.value.isCreating
    : uiFlags.value.isUpdating
);

const dialogTitle = computed(() => {
  if (showAccessToken.value) {
    return t('AGENT_BOTS.ACCESS_TOKEN.TITLE');
  }

  return props.type === MODAL_TYPES.CREATE
    ? t('AGENT_BOTS.ADD.TITLE')
    : t('AGENT_BOTS.EDIT.TITLE');
});

const dialogDescription = computed(() => {
  if (showAccessToken.value) {
    return t('AGENT_BOTS.ACCESS_TOKEN.DESCRIPTION');
  }
  return '';
});

const confirmButtonLabel = computed(() =>
  props.type === MODAL_TYPES.CREATE
    ? t('AGENT_BOTS.FORM.CREATE')
    : t('AGENT_BOTS.FORM.UPDATE')
);

const botNameError = computed(() =>
  v$.value.botName.$error ? v$.value.botName.$errors[0]?.$message : ''
);

const botUrlError = computed(() =>
  v$.value.botUrl.$error ? v$.value.botUrl.$errors[0]?.$message : ''
);

const showAccessTokenInput = computed(
  () =>
    showAccessToken.value ||
    props.type === MODAL_TYPES.EDIT ||
    accessToken.value
);

const resetForm = () => {
  Object.assign(formState, {
    botName: '',
    botDescription: '',
    botUrl: '',
    botAvatar: null,
    botAvatarUrl: '',
    contextPrompt: '',
    enableSignature: false,
    isActive: true,
    responseMode: 'auto_respond',
    selectedInboxes: [],
  });
  v$.value.$reset();
};

const handleImageUpload = ({ file, url: avatarUrl }) => {
  formState.botAvatar = file;
  formState.botAvatarUrl = avatarUrl;
};

const handleAvatarDelete = async () => {
  if (props.selectedBot?.id) {
    try {
      await store.dispatch(
        'agentBots/deleteAgentBotAvatar',
        props.selectedBot.id
      );
      formState.botAvatar = null;
      formState.botAvatarUrl = '';
      useAlert(t('AGENT_BOTS.AVATAR.SUCCESS_DELETE'));
    } catch (error) {
      useAlert(t('AGENT_BOTS.AVATAR.ERROR_DELETE'));
    }
  } else {
    formState.botAvatar = null;
    formState.botAvatarUrl = '';
  }
};

const handleSubmit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;
  if (showAccessToken.value) return;

  const botData = {
    name: formState.botName,
    description: formState.botDescription,
    outgoing_url: formState.botUrl,
    bot_type: 'webhook',
    avatar: formState.botAvatar,
    context_prompt: formState.contextPrompt,
    enable_signature: formState.enableSignature,
    is_active: formState.isActive,
    response_mode: formState.responseMode,
    inbox_ids: formState.selectedInboxes.map(inbox => inbox.id),
  };

  const isCreate = props.type === MODAL_TYPES.CREATE;

  try {
    const actionPayload = isCreate
      ? botData
      : { id: props.selectedBot.id, data: botData };

    const response = await store.dispatch(
      `agentBots/${isCreate ? 'create' : 'update'}`,
      actionPayload
    );

    const alertKey = isCreate
      ? t('AGENT_BOTS.ADD.API.SUCCESS_MESSAGE')
      : t('AGENT_BOTS.EDIT.API.SUCCESS_MESSAGE');
    useAlert(alertKey);

    // Show access token after creation
    if (isCreate) {
      const { access_token: responseAccessToken, id } = response || {};

      if (id && responseAccessToken) {
        accessToken.value = responseAccessToken;
        toggleAccessToken(true);
      } else {
        accessToken.value = '';
        dialogRef.value.close();
      }
    } else {
      dialogRef.value.close();
    }

    resetForm();
  } catch (error) {
    const errorKey = isCreate
      ? t('AGENT_BOTS.ADD.API.ERROR_MESSAGE')
      : t('AGENT_BOTS.EDIT.API.ERROR_MESSAGE');
    useAlert(errorKey);
  }
};

const initializeForm = () => {
  if (props.selectedBot && Object.keys(props.selectedBot).length) {
    const {
      name,
      description,
      outgoing_url: botUrl,
      thumbnail,
      bot_config: botConfig,
      access_token: botAccessToken,
      context_prompt: contextPrompt,
      enable_signature: enableSignature,
      is_active: isActive,
      response_mode: responseMode,
      inboxes: connectedInboxes,
    } = props.selectedBot;
    formState.botName = name || '';
    formState.botDescription = description || '';
    formState.botUrl = botUrl || botConfig?.webhook_url || '';
    formState.botAvatarUrl = thumbnail || '';
    formState.contextPrompt = contextPrompt || '';
    formState.enableSignature = enableSignature ?? false;
    formState.isActive = isActive ?? true;
    formState.responseMode = responseMode || 'auto_respond';
    formState.selectedInboxes = connectedInboxes || [];

    if (botAccessToken && props.type === MODAL_TYPES.EDIT) {
      accessToken.value = botAccessToken;
    }
  } else {
    resetForm();
  }
};

onMounted(() => {
  store.dispatch('inboxes/get');
});

const onCopyToken = async value => {
  await copyTextToClipboard(value);
  useAlert(t('AGENT_BOTS.ACCESS_TOKEN.COPY_SUCCESSFUL'));
};

const onResetToken = async () => {
  const response = await store.dispatch(
    'agentBots/resetAccessToken',
    props.selectedBot.id
  );
  if (response) {
    accessToken.value = response.access_token;
    useAlert(t('AGENT_BOTS.ACCESS_TOKEN.RESET_SUCCESS'));
  } else {
    useAlert(t('AGENT_BOTS.ACCESS_TOKEN.RESET_ERROR'));
  }
};

const closeModal = () => {
  if (!showAccessToken.value) v$.value?.$reset();
  accessToken.value = '';
  toggleAccessToken(false);
};

const onClickClose = () => {
  closeModal();
  dialogRef.value.close();
};

watch(() => props.selectedBot, initializeForm, { immediate: true, deep: true });

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="dialogTitle"
    :description="dialogDescription"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="closeModal"
  >
    <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
      <div
        v-if="!showAccessToken || type === MODAL_TYPES.EDIT"
        class="flex flex-col gap-4"
      >
        <div class="mb-2 flex flex-col items-start">
          <span class="mb-2 text-sm font-medium text-n-slate-12">
            {{ $t('AGENT_BOTS.FORM.AVATAR.LABEL') }}
          </span>
          <Avatar
            :src="formState.botAvatarUrl"
            :name="formState.botName"
            :size="68"
            allow-upload
            icon-name="i-lucide-bot-message-square"
            @upload="handleImageUpload"
            @delete="handleAvatarDelete"
          />
        </div>

        <Input
          id="bot-name"
          v-model="formState.botName"
          :label="$t('AGENT_BOTS.FORM.NAME.LABEL')"
          :placeholder="$t('AGENT_BOTS.FORM.NAME.PLACEHOLDER')"
          :message="botNameError"
          :message-type="botNameError ? 'error' : 'info'"
          @blur="v$.botName.$touch()"
        />

        <TextArea
          id="bot-description"
          v-model="formState.botDescription"
          :label="$t('AGENT_BOTS.FORM.DESCRIPTION.LABEL')"
          :placeholder="$t('AGENT_BOTS.FORM.DESCRIPTION.PLACEHOLDER')"
        />

        <Input
          id="bot-url"
          v-model="formState.botUrl"
          :label="$t('AGENT_BOTS.FORM.WEBHOOK_URL.LABEL')"
          :placeholder="$t('AGENT_BOTS.FORM.WEBHOOK_URL.PLACEHOLDER')"
          :message="botUrlError"
          :message-type="botUrlError ? 'error' : 'info'"
          @blur="v$.botUrl.$touch()"
        />

        <TextArea
          id="context-prompt"
          v-model="formState.contextPrompt"
          :label="$t('AGENT_BOTS.FORM.CONTEXT_PROMPT.LABEL')"
          :placeholder="$t('AGENT_BOTS.FORM.CONTEXT_PROMPT.PLACEHOLDER')"
          :rows="4"
        />

        <div class="flex flex-col gap-2">
          <label class="text-sm font-medium text-n-slate-12">
            {{ $t('AGENT_BOTS.FORM.RESPONSE_MODE.LABEL') }}
          </label>
          <div class="flex flex-col gap-2">
            <label
              v-for="option in RESPONSE_MODE_OPTIONS"
              :key="option.id"
              class="flex items-start gap-3 p-3 border rounded-lg cursor-pointer border-n-weak hover:bg-n-alpha-1"
              :class="{
                'bg-n-alpha-2 border-n-brand': formState.responseMode === option.id,
              }"
            >
              <input
                v-model="formState.responseMode"
                type="radio"
                :value="option.id"
                class="mt-0.5"
              />
              <div class="flex flex-col gap-0.5">
                <span class="text-sm font-medium text-n-slate-12">
                  {{ $t(`AGENT_BOTS.FORM.RESPONSE_MODE.OPTIONS.${option.name}`) }}
                </span>
                <span class="text-xs text-n-slate-11">
                  {{ $t(`AGENT_BOTS.FORM.RESPONSE_MODE.DESCRIPTIONS.${option.name}`) }}
                </span>
              </div>
            </label>
          </div>
        </div>

        <div class="flex flex-col gap-2">
          <label class="text-sm font-medium text-n-slate-12">
            {{ $t('AGENT_BOTS.FORM.INBOXES.LABEL') }}
          </label>
          <p class="text-xs text-n-slate-11">
            {{ $t('AGENT_BOTS.FORM.INBOXES.DESCRIPTION') }}
          </p>
          <multiselect
            v-model="formState.selectedInboxes"
            :options="inboxes"
            track-by="id"
            label="name"
            :multiple="true"
            :close-on-select="false"
            :clear-on-select="false"
            :hide-selected="true"
            :placeholder="$t('AGENT_BOTS.FORM.INBOXES.PLACEHOLDER')"
            :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
            :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
          />
        </div>

        <div class="flex items-center justify-between p-3 border rounded-lg border-n-weak">
          <div class="flex flex-col gap-0.5">
            <span class="text-sm font-medium text-n-slate-12">
              {{ $t('AGENT_BOTS.FORM.ENABLE_SIGNATURE.LABEL') }}
            </span>
            <span class="text-xs text-n-slate-11">
              {{ $t('AGENT_BOTS.FORM.ENABLE_SIGNATURE.DESCRIPTION') }}
            </span>
          </div>
          <Switch v-model="formState.enableSignature" />
        </div>

        <div class="flex items-center justify-between p-3 border rounded-lg border-n-weak">
          <div class="flex flex-col gap-0.5">
            <span class="text-sm font-medium text-n-slate-12">
              {{ $t('AGENT_BOTS.FORM.IS_ACTIVE.LABEL') }}
            </span>
            <span class="text-xs text-n-slate-11">
              {{ $t('AGENT_BOTS.FORM.IS_ACTIVE.DESCRIPTION') }}
            </span>
          </div>
          <Switch v-model="formState.isActive" />
        </div>
      </div>

      <div v-if="showAccessTokenInput" class="flex flex-col gap-1">
        <label
          v-if="type === MODAL_TYPES.EDIT"
          class="mb-0.5 text-sm font-medium text-n-slate-12"
        >
          {{ $t('AGENT_BOTS.ACCESS_TOKEN.TITLE') }}
        </label>
        <AccessToken
          v-if="type === MODAL_TYPES.EDIT"
          :value="accessToken"
          @on-copy="onCopyToken"
          @on-reset="onResetToken"
        />
        <AccessToken
          v-else
          :value="accessToken"
          :show-reset-button="false"
          @on-copy="onCopyToken"
        />
      </div>

      <div class="flex items-center justify-end w-full gap-2 px-0 py-2">
        <NextButton
          faded
          slate
          type="reset"
          :label="$t('AGENT_BOTS.FORM.CANCEL')"
          @click="onClickClose()"
        />
        <NextButton
          v-if="!showAccessToken"
          type="submit"
          data-testid="label-submit"
          :label="confirmButtonLabel"
          :is-loading="isLoading"
          :disabled="v$.$invalid"
        />
      </div>
    </form>
  </Dialog>
</template>
