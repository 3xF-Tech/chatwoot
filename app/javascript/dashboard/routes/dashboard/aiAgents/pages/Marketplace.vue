<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Button from 'dashboard/components-next/button/Button.vue';
import PricingCard from '../components/PricingCard.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const { t } = useI18n();
const store = useStore();
const route = useRoute();

const subscriptions = useMapGetter('aiAgentSubscriptions/getSubscriptions');
const uiFlags = useMapGetter('aiAgentSubscriptions/getUIFlags');

const selectedPlan = ref(null);
const confirmDialogRef = ref(null);

// Pricing tiers data
const pricingTiers = [
  {
    id: 'atendimento',
    name: 'Atendimento',
    price: 598.54,
    description: 'Agente para atendimento ao cliente 24/7',
    features: [
      'Respostas automáticas inteligentes',
      'Integração com base de conhecimento',
      'Suporte a múltiplos idiomas',
      'Histórico de conversas',
    ],
    badge: null,
    buttonVariant: 'slate',
  },
  {
    id: 'agendamento',
    name: 'Agendamento',
    price: 878.69,
    description: 'Agente especializado em agendamentos',
    features: [
      'Tudo do plano Atendimento',
      'Integração com calendário',
      'Confirmação automática',
      'Lembretes por WhatsApp',
      'Reagendamento inteligente',
    ],
    badge: 'popular',
    buttonVariant: 'primary',
  },
  {
    id: 'sdr',
    name: 'SDR',
    price: 987.92,
    description: 'Agente de vendas e qualificação de leads',
    features: [
      'Tudo do plano Agendamento',
      'Qualificação de leads',
      'Follow-up automático',
      'Integração com CRM',
      'Relatórios de conversão',
      'Scripts personalizados',
    ],
    badge: 'complete',
    buttonVariant: 'slate',
  },
];

// Check if plan is already active
const isPlanActive = planId => {
  return subscriptions.value?.some(
    sub => sub.plan_id === planId && sub.active
  );
};

// Enhance tiers with subscription status
const enhancedTiers = computed(() =>
  pricingTiers.map(tier => ({
    ...tier,
    isActive: isPlanActive(tier.id),
  }))
);

const handleSelectPlan = tier => {
  if (tier.isActive) {
    useAlert(t('AI_AGENTS.MARKETPLACE.ALREADY_SUBSCRIBED'));
    return;
  }
  selectedPlan.value = tier;
  confirmDialogRef.value?.open();
};

const handleStartTrial = async () => {
  if (!selectedPlan.value) return;

  try {
    await store.dispatch('aiAgentSubscriptions/startTrial', selectedPlan.value.id);
    useAlert(t('AI_AGENTS.MARKETPLACE.TRIAL_STARTED'));
    confirmDialogRef.value?.close();
  } catch (error) {
    useAlert(error.response?.data?.error || t('AI_AGENTS.MARKETPLACE.ERROR'));
  }
};

const handleCheckout = async () => {
  if (!selectedPlan.value) return;

  try {
    const response = await store.dispatch(
      'aiAgentSubscriptions/checkout',
      selectedPlan.value.id
    );
    if (response.checkout_url) {
      window.location.href = response.checkout_url;
    } else {
      useAlert(t('AI_AGENTS.MARKETPLACE.CHECKOUT_ERROR'));
    }
  } catch (error) {
    useAlert(error.response?.data?.error || t('AI_AGENTS.MARKETPLACE.ERROR'));
  }
};

onMounted(async () => {
  await store.dispatch('aiAgentSubscriptions/fetchSubscriptions');

  // Handle checkout callback
  if (route.query.checkout === 'success') {
    useAlert(t('AI_AGENTS.MARKETPLACE.CHECKOUT_SUCCESS'));
  } else if (route.query.checkout === 'canceled') {
    useAlert(t('AI_AGENTS.MARKETPLACE.CHECKOUT_CANCELED'));
  }
});
</script>

<template>
  <div class="flex flex-col w-full gap-8">
    <!-- Header -->
    <div class="flex flex-col items-center text-center gap-4 py-8">
      <span
        class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-n-blue-3 text-n-blue-11 text-sm font-medium animate-pulse"
      >
        <span class="i-lucide-sparkles size-4" />
        {{ t('AI_AGENTS.MARKETPLACE.BADGE') }}
      </span>
      <h1 class="text-3xl md:text-4xl font-bold text-n-slate-12">
        {{ t('AI_AGENTS.MARKETPLACE.TITLE') }}
      </h1>
      <p class="text-lg text-n-slate-11 max-w-2xl">
        {{ t('AI_AGENTS.MARKETPLACE.DESCRIPTION') }}
      </p>
    </div>

    <!-- Trial Banner -->
    <div
      class="flex items-center justify-center gap-3 p-4 rounded-xl bg-gradient-to-r from-n-blue-3 to-n-teal-3 border border-n-blue-6 transition-transform duration-300 hover:scale-[1.02]"
    >
      <span class="i-lucide-gift size-5 text-n-blue-11" />
      <span class="text-n-slate-12 font-medium">
        {{ t('AI_AGENTS.MARKETPLACE.TRIAL_BANNER') }}
      </span>
    </div>

    <!-- Pricing Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <PricingCard
        v-for="tier in enhancedTiers"
        :key="tier.id"
        :tier="tier"
        :is-loading="uiFlags.isCreating"
        @select="handleSelectPlan"
      />
    </div>

    <!-- Bottom CTA -->
    <div
      class="flex flex-col items-center gap-4 py-8 text-center border-t border-n-weak mt-4"
    >
      <h3 class="text-lg font-medium text-n-slate-12">
        {{ t('AI_AGENTS.MARKETPLACE.CUSTOM_TITLE') }}
      </h3>
      <p class="text-sm text-n-slate-11">
        {{ t('AI_AGENTS.MARKETPLACE.CUSTOM_DESCRIPTION') }}
      </p>
      <Button
        icon="i-lucide-message-circle"
        :label="t('AI_AGENTS.MARKETPLACE.CONTACT_SALES')"
        slate
        faded
        class="transition-all duration-200 hover:scale-105"
      />
    </div>

    <!-- Plan Selection Dialog -->
    <Dialog
      ref="confirmDialogRef"
      :title="t('AI_AGENTS.MARKETPLACE.SELECT_PLAN_DIALOG.TITLE')"
      :description="t('AI_AGENTS.MARKETPLACE.SELECT_PLAN_DIALOG.DESCRIPTION', { plan: selectedPlan?.name })"
    >
      <template #content>
        <div class="flex flex-col gap-4 p-4">
          <div class="text-sm text-n-slate-11">
            {{ t('AI_AGENTS.MARKETPLACE.SELECT_PLAN_DIALOG.CHOOSE_OPTION') }}
          </div>
          <div class="flex flex-col gap-3">
            <Button
              icon="i-lucide-gift"
              :label="t('AI_AGENTS.MARKETPLACE.START_TRIAL')"
              class="w-full justify-center"
              :is-loading="uiFlags.isCreating"
              @click="handleStartTrial"
            />
            <Button
              icon="i-lucide-credit-card"
              :label="t('AI_AGENTS.MARKETPLACE.SUBSCRIBE_NOW')"
              class="w-full justify-center"
              slate
              :is-loading="uiFlags.isCreating"
              @click="handleCheckout"
            />
          </div>
        </div>
      </template>
    </Dialog>
  </div>
</template>
