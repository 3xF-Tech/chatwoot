<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';

import Button from 'dashboard/components-next/button/Button.vue';
import AgentBotModal from '../../settings/agentBots/components/AgentBotModal.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import AgentCard from '../components/AgentCard.vue';

const MODAL_TYPES = {
  CREATE: 'create',
  EDIT: 'edit',
};

const store = useStore();
const router = useRouter();
const { t } = useI18n();
const { accountScopedRoute } = useAccount();

const agentBots = useMapGetter('agentBots/getBots');
const uiFlags = useMapGetter('agentBots/getUIFlags');

const selectedBot = ref({});
const loading = ref({});
const modalType = ref(MODAL_TYPES.CREATE);
const agentBotModalRef = ref(null);
const agentBotDeleteDialogRef = ref(null);

const selectedBotName = computed(() => selectedBot.value?.name || '');

// Redirect to Marketplace instead of opening modal
const goToMarketplace = () => {
  router.push(accountScopedRoute('ai_agents_marketplace'));
};

const openEditModal = bot => {
  modalType.value = MODAL_TYPES.EDIT;
  selectedBot.value = bot;
  agentBotModalRef.value.dialogRef.open();
};

const openDeletePopup = bot => {
  selectedBot.value = bot;
  agentBotDeleteDialogRef.value.open();
};

const deleteAgentBot = async id => {
  try {
    await store.dispatch('agentBots/delete', id);
    useAlert(t('AGENT_BOTS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('AGENT_BOTS.DELETE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[id] = false;
    selectedBot.value = {};
  }
};

const confirmDeletion = () => {
  loading.value[selectedBot.value.id] = true;
  deleteAgentBot(selectedBot.value.id);
  agentBotDeleteDialogRef.value.close();
};

onMounted(() => {
  store.dispatch('agentBots/get');
});
</script>

<template>
  <div class="flex flex-col w-full gap-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div class="flex flex-col gap-1">
        <h1 class="text-2xl font-semibold text-n-slate-12">
          {{ t('AI_AGENTS.MY_AGENTS.TITLE') }}
        </h1>
        <p class="text-sm text-n-slate-11">
          {{ t('AI_AGENTS.MY_AGENTS.DESCRIPTION') }}
        </p>
      </div>
      <Button
        icon="i-lucide-circle-plus"
        :label="t('AI_AGENTS.MY_AGENTS.CREATE_AGENT')"
        class="transition-all duration-200 hover:scale-105"
        @click="goToMarketplace"
      />
    </div>

    <!-- Loading State -->
    <div
      v-if="uiFlags.isFetching"
      class="flex items-center justify-center min-h-[300px]"
    >
      <Spinner />
    </div>

    <!-- Empty State -->
    <div
      v-else-if="!agentBots.length"
      class="flex flex-col items-center justify-center gap-4 min-h-[300px] p-8 rounded-xl border border-n-weak bg-n-solid-2 transition-all duration-300 hover:border-n-slate-7"
    >
      <div class="i-lucide-bot size-12 text-n-slate-10 animate-bounce" />
      <div class="text-center">
        <h3 class="text-lg font-medium text-n-slate-12">
          {{ t('AI_AGENTS.MY_AGENTS.EMPTY_STATE.TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11 mt-1">
          {{ t('AI_AGENTS.MY_AGENTS.EMPTY_STATE.DESCRIPTION') }}
        </p>
      </div>
      <Button
        icon="i-lucide-shopping-cart"
        :label="t('AI_AGENTS.MY_AGENTS.EMPTY_STATE.CTA')"
        class="transition-all duration-200 hover:scale-105"
        @click="goToMarketplace"
      />
    </div>

    <!-- Agents Grid -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <AgentCard
        v-for="bot in agentBots"
        :key="bot.id"
        :agent="bot"
        :loading="loading[bot.id]"
        @edit="openEditModal"
        @delete="openDeletePopup"
      />
    </div>

    <!-- Edit Modal (reusing existing component) -->
    <AgentBotModal
      ref="agentBotModalRef"
      :type="modalType"
      :selected-bot="selectedBot"
    />

    <!-- Delete Dialog -->
    <Dialog
      ref="agentBotDeleteDialogRef"
      type="alert"
      :title="t('AGENT_BOTS.DELETE.CONFIRM.TITLE')"
      :description="
        t('AGENT_BOTS.DELETE.CONFIRM.MESSAGE', { name: selectedBotName })
      "
      :is-loading="uiFlags.isDeleting"
      :confirm-button-label="t('AGENT_BOTS.DELETE.CONFIRM.YES')"
      :cancel-button-label="t('AGENT_BOTS.DELETE.CONFIRM.NO')"
      @confirm="confirmDeletion"
    />
  </div>
</template>
