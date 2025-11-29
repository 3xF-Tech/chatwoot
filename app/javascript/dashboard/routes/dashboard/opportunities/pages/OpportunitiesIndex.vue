<script setup>
import { ref, computed, onMounted, reactive, watch } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { debounce } from '@chatwoot/utils';

import OpportunitiesLayout from 'dashboard/components-next/Opportunities/OpportunitiesLayout.vue';
import OpportunityCard from 'dashboard/components-next/Opportunities/OpportunityCard.vue';
import OpportunityKanban from 'dashboard/components-next/Opportunities/OpportunityKanban.vue';
import CreateOpportunityDialog from 'dashboard/components-next/Opportunities/CreateOpportunityDialog.vue';
import CreatePipelineDialog from 'dashboard/components-next/Opportunities/CreatePipelineDialog.vue';
import EmptyPipelineState from 'dashboard/components-next/Opportunities/EmptyPipelineState.vue';
import OpportunityFilters from 'dashboard/components-next/Opportunities/OpportunityFilters.vue';

const DEFAULT_SORT_FIELD = 'created_at';
const DEBOUNCE_DELAY = 300;

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const { updateUISettings, uiSettings } = useUISettings();

// View mode: 'list' or 'kanban'
const viewMode = computed(() => route.query?.view || 'kanban');

// Search and filters
const searchQuery = computed(() => route.query?.search || '');
const searchValue = ref(searchQuery.value);
const pageNumber = computed(() => Number(route.query?.page) || 1);

// Filter state
const filters = reactive({
  pipelineId: route.query?.pipeline_id || null,
  stageId: route.query?.stage_id || null,
  status: route.query?.status || null,
  assigneeId: route.query?.assignee_id || null,
});

// Sort settings
const parseSortSettings = (sortString = '') => {
  const hasDescending = sortString.startsWith('-');
  const sortField = hasDescending ? sortString.slice(1) : sortString;
  return {
    sort: sortField || DEFAULT_SORT_FIELD,
    order: hasDescending ? '-' : '',
  };
};

const { opportunities_sort_by: opportunitySortBy = `-${DEFAULT_SORT_FIELD}` } =
  uiSettings.value ?? {};
const { sort: initialSort, order: initialOrder } =
  parseSortSettings(opportunitySortBy);

const sortState = reactive({
  activeSort: initialSort,
  activeOrdering: initialOrder,
});

const activeSort = computed(() => sortState.activeSort);
const activeOrdering = computed(() => sortState.activeOrdering);

// Store getters
const opportunities = useMapGetter('opportunities/getOpportunities');
const meta = useMapGetter('opportunities/getMeta');
const uiFlags = useMapGetter('opportunities/getUIFlags');
const pipelines = useMapGetter('pipelines/getPipelines');
const defaultPipeline = useMapGetter('pipelines/getDefaultPipeline');

const isFetchingList = computed(() => uiFlags.value.fetchingList);

// Active pipeline for kanban
const activePipelineId = computed(() => {
  if (filters.pipelineId) return Number(filters.pipelineId);
  if (defaultPipeline.value?.id) return defaultPipeline.value.id;
  if (pipelines.value.length > 0) return pipelines.value[0].id;
  return null;
});

const activePipeline = computed(() => {
  if (!activePipelineId.value) return null;
  return pipelines.value.find(p => p.id === activePipelineId.value);
});

const pipelineStages = useMapGetter('pipelines/getStagesByPipelineId');
const stages = computed(() => pipelineStages.value(activePipelineId.value));

// Helpers
const buildSortAttr = () =>
  `${sortState.activeOrdering}${sortState.activeSort}`;

const sortParam = computed(() => buildSortAttr());

const updateURLParams = params => {
  const query = { ...route.query, ...params };

  // Remove null/empty values
  Object.keys(query).forEach(key => {
    if (query[key] === null || query[key] === '' || query[key] === undefined) {
      delete query[key];
    }
  });

  router.replace({ query });
};

// Fetch data
const fetchOpportunities = async (page = null, search = null) => {
  const currentPage = page ?? pageNumber.value;
  const currentSearch = search ?? searchQuery.value;
  const currentSort = sortParam.value;

  const params = {
    page: currentPage,
    sort: currentSort,
    pipelineId: filters.pipelineId,
    stageId: filters.stageId,
    status: filters.status,
    assigneeId: filters.assigneeId,
  };

  if (currentSearch) {
    await store.dispatch('opportunities/search', {
      query: currentSearch,
      params,
    });
  } else {
    await store.dispatch('opportunities/get', params);
  }
};

const fetchPipelines = async () => {
  await store.dispatch('pipelines/get');
};

const fetchStages = async () => {
  if (activePipelineId.value) {
    await store.dispatch('pipelines/fetchStages', activePipelineId.value);
  }
};

// Event handlers
const onSearch = debounce(query => {
  searchValue.value = query;
  updateURLParams({ search: query, page: '1' });
  fetchOpportunities(1, query);
}, DEBOUNCE_DELAY);

const onPageChange = page => {
  updateURLParams({ page: page.toString() });
  fetchOpportunities(page);
};

const handleSort = async ({ sort, order }) => {
  Object.assign(sortState, { activeSort: sort, activeOrdering: order });

  await updateUISettings({
    opportunities_sort_by: buildSortAttr(),
  });

  updateURLParams({ sort: buildSortAttr(), page: '1' });
  fetchOpportunities(1);
};

const handleFilterChange = newFilters => {
  Object.assign(filters, newFilters);
  updateURLParams({
    pipeline_id: filters.pipelineId,
    stage_id: filters.stageId,
    status: filters.status,
    assignee_id: filters.assigneeId,
    page: '1',
  });
  fetchOpportunities(1);
};

const handleViewChange = mode => {
  updateURLParams({ view: mode });
};

const handlePipelineChange = pipelineId => {
  filters.pipelineId = pipelineId;
  filters.stageId = null;
  updateURLParams({
    pipeline_id: pipelineId,
    stage_id: null,
    page: '1',
  });
  fetchStages();
  fetchOpportunities(1);
};

// Kanban drag and drop
const handleStageDrop = async ({ opportunityId, stageId }) => {
  console.log('handleStageDrop called:', { opportunityId, stageId });
  try {
    await store.dispatch('opportunities/moveStage', { opportunityId, stageId });
    console.log('moveStage completed');
    // Refresh the list to update UI
    await fetchOpportunities();
  } catch (error) {
    console.error('moveStage error:', error);
  }
};

// Dialog
const createDialogRef = ref(null);
const createPipelineDialogRef = ref(null);

const hasPipelines = computed(() => pipelines.value.length > 0);

const openCreateDialog = () => {
  createDialogRef.value?.dialogRef.open();
};

const openCreatePipelineDialog = () => {
  createPipelineDialogRef.value?.dialogRef.open();
};

const handleOpportunityCreated = () => {
  fetchOpportunities(1);
};

const handlePipelineCreated = async () => {
  await fetchPipelines();
  await fetchStages();
  await fetchOpportunities();
};

const navigateToOpportunity = opportunityId => {
  router.push({
    name: 'opportunity_details',
    params: { opportunityId },
  });
};

// Watch for pipeline changes to fetch stages
watch(activePipelineId, newPipelineId => {
  if (newPipelineId) {
    fetchStages();
  }
});

onMounted(async () => {
  searchValue.value = searchQuery.value;
  await fetchPipelines();
  await fetchStages();
  await fetchOpportunities();
});
</script>

<template>
  <!-- Empty state when no pipelines exist -->
  <div v-if="!hasPipelines && !isFetchingList" class="flex flex-col h-full bg-n-background">
    <header class="sticky top-0 z-10 border-b border-n-weak bg-n-background">
      <div class="flex items-center justify-between w-full py-4 px-6 mx-auto max-w-[80rem]">
        <span class="text-xl font-medium text-n-slate-12">
          {{ t('OPPORTUNITIES.HEADER') }}
        </span>
      </div>
    </header>
    <EmptyPipelineState @create-pipeline="openCreatePipelineDialog" />
  </div>

  <!-- Normal layout when pipelines exist -->
  <OpportunitiesLayout
    v-else
    :search-value="searchValue"
    :header-title="t('OPPORTUNITIES.HEADER')"
    :current-page="pageNumber"
    :total-items="Number(meta.totalCount || 0)"
    :active-sort="activeSort"
    :active-ordering="activeOrdering"
    :is-fetching-list="isFetchingList"
    :view-mode="viewMode"
    :pipelines="pipelines"
    :active-pipeline-id="activePipelineId"
    @update:current-page="onPageChange"
    @update:sort="handleSort"
    @update:view-mode="handleViewChange"
    @update:pipeline="handlePipelineChange"
    @search="onSearch"
    @create="openCreateDialog"
  >
    <template #filters>
      <OpportunityFilters
        :filters="filters"
        :pipelines="pipelines"
        :stages="stages"
        @update:filters="handleFilterChange"
      />
    </template>

    <!-- Loading State -->
    <div v-if="isFetchingList" class="flex items-center justify-center p-8">
      <span class="text-n-slate-11 text-base">
        {{ t('OPPORTUNITIES.LOADING') }}
      </span>
    </div>

    <!-- Empty State -->
    <div
      v-else-if="opportunities.length === 0"
      class="flex flex-col items-center justify-center p-12 gap-4"
    >
      <span class="text-n-slate-11 text-lg font-medium">
        {{ t('OPPORTUNITIES.EMPTY_STATE.TITLE') }}
      </span>
      <span class="text-n-slate-10 text-sm">
        {{ t('OPPORTUNITIES.EMPTY_STATE.DESCRIPTION') }}
      </span>
      <button
        class="px-4 py-2 bg-woot-500 text-white rounded-lg hover:bg-woot-600 transition-colors"
        @click="openCreateDialog"
      >
        {{ t('OPPORTUNITIES.EMPTY_STATE.BTN_TXT') }}
      </button>
    </div>

    <!-- Kanban View -->
    <OpportunityKanban
      v-else-if="viewMode === 'kanban'"
      :opportunities="opportunities"
      :stages="stages"
      :pipeline="activePipeline"
      @drop="handleStageDrop"
      @show-opportunity="navigateToOpportunity"
    />

    <!-- List View -->
    <div v-else class="flex flex-col gap-4 p-4">
      <OpportunityCard
        v-for="opportunity in opportunities"
        :key="opportunity.id"
        :opportunity="opportunity"
        @show-opportunity="navigateToOpportunity"
      />
    </div>
  </OpportunitiesLayout>

  <CreateOpportunityDialog
    ref="createDialogRef"
    :pipelines="pipelines"
    :default-pipeline-id="activePipelineId"
    @created="handleOpportunityCreated"
  />

  <CreatePipelineDialog
    ref="createPipelineDialogRef"
    @created="handlePipelineCreated"
  />
</template>
