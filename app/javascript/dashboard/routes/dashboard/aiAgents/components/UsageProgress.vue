<script setup>
import { computed } from 'vue';

const props = defineProps({
  current: {
    type: Number,
    required: true,
  },
  limit: {
    type: Number,
    required: true,
  },
  label: {
    type: String,
    default: '',
  },
});

const percentage = computed(() => {
  if (props.limit === 0) return 0;
  return Math.min(Math.round((props.current / props.limit) * 100), 100);
});

const progressColor = computed(() => {
  if (percentage.value >= 90) return 'bg-n-ruby-9';
  if (percentage.value >= 75) return 'bg-n-amber-9';
  return 'bg-n-teal-9';
});

const formatNumber = value => {
  return new Intl.NumberFormat('pt-BR').format(value);
};
</script>

<template>
  <div class="flex flex-col gap-3 p-5 rounded-xl border border-n-weak bg-n-solid-2">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <span class="text-sm font-medium text-n-slate-11">{{ label }}</span>
      <span class="text-sm font-medium text-n-slate-12">
        {{ percentage }}%
      </span>
    </div>

    <!-- Progress Bar -->
    <div class="relative w-full h-3 bg-n-slate-3 rounded-full overflow-hidden">
      <div
        class="absolute left-0 top-0 h-full rounded-full transition-all duration-500"
        :class="progressColor"
        :style="{ width: `${percentage}%` }"
      />
    </div>

    <!-- Values -->
    <div class="flex items-center justify-between text-xs text-n-slate-10">
      <span>{{ formatNumber(current) }} usadas</span>
      <span>{{ formatNumber(limit) }} limite</span>
    </div>
  </div>
</template>
