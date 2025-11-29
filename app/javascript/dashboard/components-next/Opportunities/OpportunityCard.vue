<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const { t } = useI18n();

const props = defineProps({
  opportunity: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['showOpportunity']);

const formatCurrency = (value, currency = 'BRL') => {
  if (!value) return '-';
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency,
  }).format(value);
};

const formattedDate = dateValue => {
  if (!dateValue) return '-';
  return new Date(dateValue).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
};

const handleClick = () => {
  emit('showOpportunity', props.opportunity.id);
};
</script>

<template>
  <article
    class="flex items-center gap-4 p-4 rounded-xl border border-n-weak bg-n-solid-2 cursor-pointer hover:bg-n-solid-3 transition-colors"
    @click="handleClick"
  >
    <!-- Left Section: Avatar and Main Info -->
    <div class="flex items-center gap-4 flex-1 min-w-0">
      <div
        class="flex items-center justify-center size-12 rounded-lg bg-woot-50 dark:bg-woot-900/20"
      >
        <Icon icon="i-lucide-briefcase" class="size-6 text-woot-500" />
      </div>

      <div class="flex flex-col min-w-0">
        <div class="flex items-center gap-2">
          <span class="text-sm text-n-slate-11">#{{ opportunity.display_id }}</span>
          <span
            :class="[
              'px-2 py-0.5 text-xs font-medium rounded-md',
              opportunity.status === 'won' ? 'bg-g-50 text-g-800 dark:bg-g-900 dark:text-g-200' :
              opportunity.status === 'lost' ? 'bg-r-50 text-r-800 dark:bg-r-900 dark:text-r-200' :
              opportunity.status === 'open' ? 'bg-b-50 text-b-800 dark:bg-b-900 dark:text-b-200' :
              'bg-n-alpha-2 text-n-slate-11'
            ]"
          >
            {{ t(`OPPORTUNITIES.STATUS.${opportunity.status?.toUpperCase()}`) }}
          </span>
        </div>
        <h3 class="font-medium text-n-slate-12 truncate">
          {{ opportunity.name }}
        </h3>
        <div class="flex items-center gap-2 text-sm text-n-slate-11">
          <span v-if="opportunity.pipeline_stage?.name">
            {{ opportunity.pipeline_stage.name }}
          </span>
          <span v-if="opportunity.contact?.name || opportunity.company?.name">•</span>
          <span v-if="opportunity.contact?.name">
            {{ opportunity.contact.name }}
          </span>
          <span v-else-if="opportunity.company?.name">
            {{ opportunity.company.name }}
          </span>
        </div>
      </div>
    </div>

    <!-- Center Section: Value -->
    <div class="flex flex-col items-end min-w-[120px]">
      <span class="text-lg font-semibold text-n-slate-12">
        {{ formatCurrency(opportunity.value, opportunity.currency) }}
      </span>
      <span v-if="opportunity.pipeline_stage?.probability" class="text-sm text-n-slate-11">
        {{ opportunity.pipeline_stage.probability }}% prob.
      </span>
    </div>

    <!-- Right Section: Expected Close & Assignee -->
    <div class="flex items-center gap-4">
      <div class="flex flex-col items-end min-w-[100px]">
        <span class="text-sm text-n-slate-11">
          {{ t('OPPORTUNITIES.FORM.EXPECTED_CLOSE_DATE.LABEL') }}
        </span>
        <span class="text-sm text-n-slate-12">
          {{ formattedDate(opportunity.expected_close_date) }}
        </span>
      </div>

      <Avatar
        v-if="opportunity.assignee"
        :src="opportunity.assignee.avatar_url"
        :name="opportunity.assignee.name"
        :size="32"
        class="flex-shrink-0"
      />

      <Icon icon="i-lucide-chevron-right" class="size-5 text-n-slate-11" />
    </div>
  </article>
</template>
