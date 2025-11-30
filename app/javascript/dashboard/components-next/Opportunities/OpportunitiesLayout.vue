<script setup>
import { computed } from 'vue';
import OpportunitiesHeader from './OpportunitiesHeader.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';

const props = defineProps({
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, default: '' },
  currentPage: { type: Number, default: 1 },
  totalItems: { type: Number, default: 0 },
  activeSort: { type: String, default: 'created_at' },
  activeOrdering: { type: String, default: '-' },
  isFetchingList: { type: Boolean, default: false },
  viewMode: { type: String, default: 'kanban' },
  pipelines: { type: Array, default: () => [] },
  activePipelineId: { type: Number, default: null },
});

const emit = defineEmits([
  'update:currentPage',
  'update:sort',
  'update:viewMode',
  'update:pipeline',
  'search',
  'create',
]);

const updateCurrentPage = page => {
  emit('update:currentPage', page);
};

const showPagination = computed(() => {
  return props.viewMode === 'list' && props.totalItems > 0;
});
</script>

<template>
  <section
    class="flex w-full h-full gap-4 overflow-hidden justify-evenly bg-n-background"
  >
    <div class="flex flex-col w-full h-full transition-all duration-300">
      <OpportunitiesHeader
        :search-value="searchValue"
        :header-title="headerTitle"
        :active-sort="activeSort"
        :active-ordering="activeOrdering"
        :view-mode="viewMode"
        :pipelines="pipelines"
        :active-pipeline-id="activePipelineId"
        @search="emit('search', $event)"
        @update:sort="emit('update:sort', $event)"
        @update:view-mode="emit('update:viewMode', $event)"
        @update:pipeline="emit('update:pipeline', $event)"
        @create="emit('create')"
      />

      <!-- Filters Slot -->
      <div class="px-4 py-2 border-b border-n-weak bg-n-solid-1">
        <slot name="filters" />
      </div>

      <main class="flex-1 overflow-y-auto">
        <div
          class="w-full mx-auto"
          :class="[viewMode === 'kanban' ? '' : 'max-w-[80rem]']"
        >
          <slot name="default" />
        </div>
      </main>

      <footer v-if="showPagination" class="sticky bottom-0 z-0 px-4 pb-4">
        <PaginationFooter
          current-page-info="OPPORTUNITIES.LIST.PAGINATION"
          :current-page="currentPage"
          :total-items="totalItems"
          :items-per-page="25"
          @update:current-page="updateCurrentPage"
        />
      </footer>
    </div>
  </section>
</template>
