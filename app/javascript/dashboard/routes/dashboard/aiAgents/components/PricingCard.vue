<script setup>
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  tier: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['select']);

const { t } = useI18n();

const formatCurrency = value => {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(value);
};

const handleSelect = () => {
  emit('select', props.tier);
};
</script>

<template>
  <div
    class="flex flex-col p-6 rounded-2xl border-2 transition-all duration-300 hover:shadow-lg hover:-translate-y-1"
    :class="[
      tier.badge === 'popular'
        ? 'border-n-blue-8 bg-n-solid-2 shadow-lg scale-105'
        : 'border-n-weak bg-n-solid-2 hover:border-n-slate-7',
    ]"
  >
    <!-- Badge -->
    <div class="h-6 mb-4">
      <span
        v-if="tier.badge === 'popular'"
        class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-n-blue-9 text-white"
      >
        {{ t('AI_AGENTS.MARKETPLACE.BADGES.POPULAR') }}
      </span>
      <span
        v-else-if="tier.badge === 'complete'"
        class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-n-teal-9 text-white"
      >
        {{ t('AI_AGENTS.MARKETPLACE.BADGES.COMPLETE') }}
      </span>
    </div>

    <!-- Plan Name -->
    <h3 class="text-xl font-semibold text-n-slate-12">
      {{ tier.name }}
    </h3>
    <p class="text-sm text-n-slate-11 mt-1">
      {{ tier.description }}
    </p>

    <!-- Price -->
    <div class="flex items-baseline gap-1 mt-6">
      <span class="text-4xl font-bold text-n-slate-12">
        {{ formatCurrency(tier.price) }}
      </span>
      <span class="text-n-slate-11">/{{ t('AI_AGENTS.MARKETPLACE.MONTH') }}</span>
    </div>

    <!-- Limit Info -->
    <p class="text-xs text-n-slate-10 mt-2">
      {{ t('AI_AGENTS.MARKETPLACE.MESSAGES_LIMIT') }}
    </p>

    <!-- CTA Button -->
    <Button
      :label="t('AI_AGENTS.MARKETPLACE.SELECT_PLAN')"
      class="mt-6 w-full justify-center transition-transform duration-200 hover:scale-105"
      :class="tier.badge === 'popular' ? '' : 'slate'"
      @click="handleSelect"
    />

    <!-- Features -->
    <ul class="flex flex-col gap-3 mt-6 pt-6 border-t border-n-weak">
      <li
        v-for="feature in tier.features"
        :key="feature"
        class="flex items-start gap-2 text-sm text-n-slate-11"
      >
        <span class="i-lucide-check size-4 text-n-teal-10 flex-shrink-0 mt-0.5" />
        {{ feature }}
      </li>
    </ul>
  </div>
</template>
