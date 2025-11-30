<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  opportunity: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const formatCurrency = (value, currency = 'BRL') => {
  if (!value) return '-';
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency,
  }).format(value);
};

const formattedDate = dateValue => {
  if (!dateValue) return null;
  return new Date(dateValue).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
  });
};

const isOverdue = computed(() => {
  if (!props.opportunity.expected_close_date) return false;
  return new Date(props.opportunity.expected_close_date) < new Date();
});
</script>

<template>
  <div
    class="p-3 rounded-lg border border-n-weak bg-n-background cursor-pointer hover:border-n-strong hover:shadow-sm transition-all"
  >
    <!-- Header: ID and assignee -->
    <div class="flex items-center justify-between mb-2">
      <span class="text-xs text-n-slate-11">#{{ opportunity.display_id }}</span>
      <Avatar
        v-if="opportunity.assignee"
        :src="opportunity.assignee.avatar_url"
        :name="opportunity.assignee.name"
        :size="20"
      />
    </div>

    <!-- Name -->
    <h4 class="font-medium text-sm text-n-slate-12 mb-2 line-clamp-2">
      {{ opportunity.name }}
    </h4>

    <!-- Value -->
    <div class="flex items-center justify-between mb-2">
      <span class="text-lg font-semibold text-n-slate-12">
        {{ formatCurrency(opportunity.value, opportunity.currency) }}
      </span>
    </div>

    <!-- Contact/Company -->
    <div
      v-if="opportunity.contact?.name || opportunity.company?.name"
      class="flex items-center gap-1 text-xs text-n-slate-11 mb-2"
    >
      <Icon
        :icon="opportunity.contact ? 'i-lucide-user' : 'i-lucide-building-2'"
        class="size-3"
      />
      <span class="truncate">
        {{ opportunity.contact?.name || opportunity.company?.name }}
      </span>
    </div>

    <!-- Footer: Expected close date -->
    <div
      v-if="opportunity.expected_close_date"
      class="flex items-center gap-1 text-xs"
      :class="isOverdue ? 'text-ruby-600' : 'text-n-slate-11'"
    >
      <Icon icon="i-lucide-calendar" class="size-3" />
      <span>{{ formattedDate(opportunity.expected_close_date) }}</span>
      <Icon
        v-if="isOverdue"
        icon="i-lucide-alert-triangle"
        class="size-3 ml-1"
      />
    </div>
  </div>
</template>
