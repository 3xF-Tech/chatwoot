<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

const props = defineProps({
  activeSort: { type: String, default: 'created_at' },
  activeOrdering: { type: String, default: '-' },
});

const emit = defineEmits(['update:sort']);

const sortOptions = [
  { key: 'created_at', label: 'OPPORTUNITIES.SORT_BY.CREATED_AT' },
  { key: 'expected_close_date', label: 'OPPORTUNITIES.SORT_BY.EXPECTED_CLOSE_DATE' },
  { key: 'value', label: 'OPPORTUNITIES.SORT_BY.VALUE' },
  { key: 'name', label: 'OPPORTUNITIES.SORT_BY.NAME' },
  { key: 'updated_at', label: 'OPPORTUNITIES.SORT_BY.UPDATED_AT' },
];

const currentValue = computed(() => `${props.activeOrdering}${props.activeSort}`);

const handleSortChange = event => {
  const value = event.target.value;
  const order = value.startsWith('-') ? '-' : '';
  const sort = value.replace('-', '');
  emit('update:sort', { sort, order });
};

const sortOptionsWithOrder = computed(() => {
  const options = [];
  sortOptions.forEach(opt => {
    options.push({ value: `-${opt.key}`, label: `${t(opt.label)} ↓` });
    options.push({ value: opt.key, label: `${t(opt.label)} ↑` });
  });
  return options;
});
</script>

<template>
  <div class="flex items-center gap-1">
    <span class="text-xs text-n-slate-11">{{ t('OPPORTUNITIES.SORT_BY.TITLE') }}:</span>
    <select
      :value="currentValue"
      class="px-2 py-1 text-xs bg-n-alpha-1 border border-n-weak rounded-md text-n-slate-12 focus:outline-none focus:ring-1 focus:ring-n-brand"
      @change="handleSortChange"
    >
      <option v-for="opt in sortOptionsWithOrder" :key="opt.value" :value="opt.value">
        {{ opt.label }}
      </option>
    </select>
  </div>
</template>
