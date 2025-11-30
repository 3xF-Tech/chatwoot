<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import draggable from 'vuedraggable';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import OpportunityKanbanCard from './OpportunityKanbanCard.vue';

const props = defineProps({
  opportunities: {
    type: Array,
    default: () => [],
  },
  stages: {
    type: Array,
    default: () => [],
  },
  pipeline: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['drop', 'showOpportunity']);

const { t } = useI18n();

// Create reactive lists for each stage to enable drag/drop
const stageOpportunities = ref({});

// Initialize and update stage opportunities when props change
const updateStageOpportunities = () => {
  const newStageOpps = {};
  props.stages.forEach(stage => {
    newStageOpps[stage.id] = props.opportunities.filter(
      opp => opp.pipeline_stage_id === stage.id
    );
  });
  stageOpportunities.value = newStageOpps;
};

// Watch for changes in opportunities or stages
watch(
  () => [props.opportunities, props.stages],
  () => {
    updateStageOpportunities();
  },
  { immediate: true, deep: true }
);

const getOpportunitiesForStage = stageId => {
  return stageOpportunities.value[stageId] || [];
};

const getStageTotal = stageId => {
  return getOpportunitiesForStage(stageId).reduce(
    (sum, opp) => sum + (parseFloat(opp.value) || 0),
    0
  );
};

const formatCurrency = (value, currency = 'BRL') => {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency,
    notation: 'compact',
    maximumFractionDigits: 1,
  }).format(value);
};

const handleDragEnd = (evt, stageId) => {
  console.log('Drag event:', evt, 'Stage ID:', stageId);
  if (evt.added) {
    console.log('Emitting drop:', {
      opportunityId: evt.added.element.id,
      stageId,
    });
    emit('drop', {
      opportunityId: evt.added.element.id,
      stageId,
    });
  }
};

const handleCardClick = opportunityId => {
  emit('showOpportunity', opportunityId);
};
</script>

<template>
  <div class="flex h-full overflow-x-auto p-4 gap-4">
    <div
      v-for="stage in stages"
      :key="stage.id"
      class="flex flex-col flex-shrink-0 w-80 bg-n-solid-1 rounded-xl border border-n-weak"
    >
      <!-- Stage Header -->
      <div class="flex items-center justify-between p-4 border-b border-n-weak">
        <div class="flex items-center gap-2">
          <span
            class="px-2 py-1 text-xs font-medium rounded-md"
            :class="[
              stage.stage_type === 'won'
                ? 'bg-g-50 text-g-800 dark:bg-g-900 dark:text-g-200'
                : stage.stage_type === 'lost'
                  ? 'bg-r-50 text-r-800 dark:bg-r-900 dark:text-r-200'
                  : 'bg-b-50 text-b-800 dark:bg-b-900 dark:text-b-200',
            ]"
          >
            {{ stage.name }}
          </span>
          <span class="text-sm text-n-slate-11">
            ({{ getOpportunitiesForStage(stage.id).length }})
          </span>
        </div>
        <div class="flex items-center gap-2 text-sm">
          <span class="font-medium text-n-slate-12">
            {{ formatCurrency(getStageTotal(stage.id)) }}
          </span>
        </div>
      </div>

      <!-- Stage Cards -->
      <draggable
        :list="stageOpportunities[stage.id]"
        :group="{ name: 'opportunities', pull: true, put: true }"
        item-key="id"
        class="flex-1 p-2 overflow-y-auto min-h-[200px] space-y-2"
        ghost-class="opacity-50"
        @change="handleDragEnd($event, stage.id)"
      >
        <template #item="{ element: opportunity }">
          <OpportunityKanbanCard
            :opportunity="opportunity"
            @click="handleCardClick(opportunity.id)"
          />
        </template>

        <template #header>
          <div
            v-if="getOpportunitiesForStage(stage.id).length === 0"
            class="flex flex-col items-center justify-center py-8 text-n-slate-11"
          >
            <Icon icon="i-lucide-inbox" class="size-8 mb-2 opacity-50" />
            <span class="text-sm">{{
              t('OPPORTUNITIES.KANBAN.EMPTY_STAGE')
            }}</span>
          </div>
        </template>
      </draggable>

      <!-- Stage Footer with probability -->
      <div
        v-if="stage.probability !== null && stage.probability !== undefined"
        class="flex items-center justify-between px-4 py-2 border-t border-n-weak text-xs text-n-slate-11"
      >
        <span>{{ t('OPPORTUNITIES.DETAILS.PROBABILITY') }}</span>
        <span>{{ stage.probability }}%</span>
      </div>
    </div>
  </div>
</template>
