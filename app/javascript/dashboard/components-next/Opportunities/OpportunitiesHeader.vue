<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import OpportunitySortMenu from './OpportunitySortMenu.vue';

const props = defineProps({
  showSearch: { type: Boolean, default: true },
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, required: true },
  activeSort: { type: String, default: 'created_at' },
  activeOrdering: { type: String, default: '-' },
  viewMode: { type: String, default: 'kanban' },
  pipelines: { type: Array, default: () => [] },
  activePipelineId: { type: Number, default: null },
});

const emit = defineEmits([
  'search',
  'update:sort',
  'update:viewMode',
  'update:pipeline',
  'create',
]);

const { t } = useI18n();

const viewModes = [
  { key: 'kanban', icon: 'i-lucide-layout-grid' },
  { key: 'list', icon: 'i-lucide-list' },
];

function onPipelineChange(event) {
  const value = parseInt(event.target.value, 10);
  emit('update:pipeline', value);
}
</script>

<template>
  <header class="sticky top-0 z-10 border-b border-n-weak bg-n-background">
    <div
      class="flex items-start sm:items-center justify-between w-full py-4 px-6 gap-4 mx-auto max-w-[80rem]"
    >
      <div class="flex items-center gap-4">
        <span class="text-xl font-medium truncate text-n-slate-12">
          {{ headerTitle }}
        </span>

        <!-- Pipeline Selector -->
        <div v-if="pipelines.length > 0" class="relative">
          <select
            :value="activePipelineId"
            class="appearance-none bg-n-alpha-2 dark:bg-n-solid-1 border border-n-weak rounded-lg px-3 py-1.5 pr-8 text-sm text-n-slate-12 cursor-pointer hover:bg-n-alpha-3 focus:outline-none focus:ring-2 focus:ring-n-brand"
            @change="onPipelineChange"
          >
            <option
              v-for="pipeline in pipelines"
              :key="pipeline.id"
              :value="pipeline.id"
            >
              {{ pipeline.name }}
            </option>
          </select>
          <Icon
            icon="i-lucide-chevron-down"
            class="absolute right-2 top-1/2 -translate-y-1/2 size-4 text-n-slate-11 pointer-events-none"
          />
        </div>
      </div>

      <div class="flex items-center flex-col sm:flex-row flex-shrink-0 gap-4">
        <!-- Search -->
        <div v-if="showSearch" class="flex items-center gap-2 w-full sm:w-auto">
          <Input
            :model-value="searchValue"
            type="search"
            :placeholder="t('OPPORTUNITIES.SEARCH_PLACEHOLDER')"
            :custom-input-class="[
              'h-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 !py-1 rtl:!pr-8',
            ]"
            class="w-full sm:w-64"
            @input="emit('search', $event.target.value)"
          >
            <template #prefix>
              <Icon
                icon="i-lucide-search"
                class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2 rtl:right-2"
              />
            </template>
          </Input>
        </div>

        <div class="flex items-center flex-shrink-0 gap-2">
          <!-- View Mode Toggle -->
          <div class="flex items-center gap-1 p-1 rounded-lg bg-n-alpha-2">
            <button
              v-for="mode in viewModes"
              :key="mode.key"
              class="p-1.5 rounded-md transition-colors"
              :class="[
                viewMode === mode.key
                  ? 'bg-n-solid-3 text-n-slate-12'
                  : 'text-n-slate-11 hover:text-n-slate-12',
              ]"
              @click="emit('update:viewMode', mode.key)"
            >
              <Icon :icon="mode.icon" class="size-4" />
            </button>
          </div>

          <!-- Sort Menu (only for list view) -->
          <OpportunitySortMenu
            v-if="viewMode === 'list'"
            :active-sort="activeSort"
            :active-ordering="activeOrdering"
            @update:sort="emit('update:sort', $event)"
          />

          <div class="w-px h-4 bg-n-strong" />

          <!-- Create Button -->
          <Button
            :label="t('OPPORTUNITIES.HEADER_BTN_TXT')"
            icon="i-lucide-plus"
            size="sm"
            @click="emit('create')"
          />
        </div>
      </div>
    </div>
  </header>
</template>
