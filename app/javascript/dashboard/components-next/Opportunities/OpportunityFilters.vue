<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();

const props = defineProps({
  filters: {
    type: Object,
    default: () => ({}),
  },
  pipelines: {
    type: Array,
    default: () => [],
  },
  stages: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['update:filters']);

const agents = useMapGetter('agents/getAgents');

const statusOptions = [
  { value: null, label: t('OPPORTUNITIES.FILTERS.ALL_STATUSES') },
  { value: 'open', label: t('OPPORTUNITIES.STATUS.OPEN') },
  { value: 'won', label: t('OPPORTUNITIES.STATUS.WON') },
  { value: 'lost', label: t('OPPORTUNITIES.STATUS.LOST') },
  { value: 'cancelled', label: t('OPPORTUNITIES.STATUS.CANCELLED') },
];

const stageOptions = computed(() => [
  { value: null, label: t('OPPORTUNITIES.FILTERS.ALL_STAGES') },
  ...props.stages.map(s => ({ value: s.id, label: s.name })),
]);

const assigneeOptions = computed(() => [
  { value: null, label: t('OPPORTUNITIES.FILTERS.ALL_ASSIGNEES') },
  ...agents.value.map(a => ({ value: a.id, label: a.name })),
]);

const updateFilter = (key, value) => {
  emit('update:filters', {
    ...props.filters,
    [key]: value,
  });
};

const clearFilters = () => {
  emit('update:filters', {
    pipelineId: null,
    stageId: null,
    status: null,
    assigneeId: null,
  });
};

const hasActiveFilters = computed(() => {
  return (
    props.filters.status ||
    props.filters.stageId ||
    props.filters.assigneeId
  );
});
</script>

<template>
  <div class="flex items-center gap-2 flex-wrap">
    <!-- Status Filter -->
    <select
      :value="filters.status"
      class="px-2 py-1 text-xs bg-n-alpha-1 border border-n-weak rounded-md text-n-slate-12 focus:outline-none focus:ring-1 focus:ring-n-brand"
      @change="updateFilter('status', $event.target.value || null)"
    >
      <option v-for="opt in statusOptions" :key="opt.value" :value="opt.value">
        {{ opt.label }}
      </option>
    </select>

    <!-- Stage Filter -->
    <select
      :value="filters.stageId"
      class="px-2 py-1 text-xs bg-n-alpha-1 border border-n-weak rounded-md text-n-slate-12 focus:outline-none focus:ring-1 focus:ring-n-brand"
      @change="updateFilter('stageId', $event.target.value ? Number($event.target.value) : null)"
    >
      <option v-for="opt in stageOptions" :key="opt.value" :value="opt.value">
        {{ opt.label }}
      </option>
    </select>

    <!-- Assignee Filter -->
    <select
      :value="filters.assigneeId"
      class="px-2 py-1 text-xs bg-n-alpha-1 border border-n-weak rounded-md text-n-slate-12 focus:outline-none focus:ring-1 focus:ring-n-brand"
      @change="updateFilter('assigneeId', $event.target.value ? Number($event.target.value) : null)"
    >
      <option v-for="opt in assigneeOptions" :key="opt.value" :value="opt.value">
        {{ opt.label }}
      </option>
    </select>

    <!-- Clear Filters -->
    <Button
      v-if="hasActiveFilters"
      variant="ghost"
      color="slate"
      size="xs"
      icon="i-lucide-x"
      @click="clearFilters"
    >
      {{ t('FILTER.CLEAR_BUTTON_LABEL') }}
    </Button>
  </div>
</template>
