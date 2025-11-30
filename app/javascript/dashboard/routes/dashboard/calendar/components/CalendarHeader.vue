<script setup>
import { useI18n } from 'vue-i18n';
import { computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  currentDate: {
    type: Date,
    required: true,
  },
  viewMode: {
    type: String,
    default: 'month',
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'previous',
  'next',
  'today',
  'view-change',
  'new-event',
]);

const { t } = useI18n();

const formattedDate = computed(() => {
  const date = props.currentDate;
  const options = { year: 'numeric', month: 'long' };

  if (props.viewMode === 'week') {
    const start = new Date(date);
    start.setDate(date.getDate() - date.getDay());
    const end = new Date(start);
    end.setDate(start.getDate() + 6);

    const startStr = start.toLocaleDateString('default', {
      month: 'short',
      day: 'numeric',
    });
    const endStr = end.toLocaleDateString('default', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
    return `${startStr} - ${endStr}`;
  }

  if (props.viewMode === 'day') {
    return date.toLocaleDateString('default', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  }

  return date.toLocaleDateString('default', options);
});

const viewOptions = [
  { value: 'month', label: 'CALENDAR.VIEW.MONTH' },
  { value: 'week', label: 'CALENDAR.VIEW.WEEK' },
  { value: 'day', label: 'CALENDAR.VIEW.DAY' },
];
</script>

<template>
  <header
    class="flex items-center justify-between border-b border-n-weak bg-n-alpha-1 px-4 py-3"
  >
    <div class="flex items-center gap-4">
      <div class="flex items-center gap-1">
        <button
          class="rounded-lg p-2 text-n-slate-11 hover:bg-n-alpha-2"
          @click="emit('previous')"
        >
          <fluent-icon icon="chevron-left" size="16" />
        </button>
        <button
          class="rounded-lg p-2 text-n-slate-11 hover:bg-n-alpha-2"
          @click="emit('next')"
        >
          <fluent-icon icon="chevron-right" size="16" />
        </button>
      </div>

      <Button
        variant="faint"
        size="sm"
        :label="t('CALENDAR.TODAY')"
        @click="emit('today')"
      />

      <h2 class="text-lg font-semibold text-n-slate-12">
        {{ formattedDate }}
      </h2>

      <div v-if="isLoading" class="ml-2">
        <fluent-icon
          icon="spinner"
          size="16"
          class="animate-spin text-n-slate-10"
        />
      </div>
    </div>

    <div class="flex items-center gap-3">
      <div class="flex rounded-lg border border-n-weak">
        <button
          v-for="option in viewOptions"
          :key="option.value"
          class="px-3 py-1.5 text-sm transition-colors first:rounded-l-lg last:rounded-r-lg"
          :class="
            viewMode === option.value
              ? 'bg-n-brand text-white'
              : 'text-n-slate-11 hover:bg-n-alpha-2'
          "
          @click="emit('view-change', option.value)"
        >
          {{ t(option.label) }}
        </button>
      </div>

      <Button
        variant="solid"
        size="sm"
        color="blue"
        icon="add"
        :label="t('CALENDAR.NEW_EVENT')"
        @click="emit('new-event')"
      />
    </div>
  </header>
</template>
