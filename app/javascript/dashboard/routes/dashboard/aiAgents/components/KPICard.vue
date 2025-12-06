<script setup>
defineProps({
  title: {
    type: String,
    required: true,
  },
  value: {
    type: [String, Number],
    required: true,
  },
  icon: {
    type: String,
    default: 'i-lucide-activity',
  },
  trend: {
    type: Object,
    default: null,
  },
  loading: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <div
    class="flex flex-col gap-3 p-5 rounded-xl border border-n-weak bg-n-solid-2 hover:border-n-slate-7 transition-all duration-200"
  >
    <!-- Header -->
    <div class="flex items-center justify-between">
      <span class="text-sm font-medium text-n-slate-11">{{ title }}</span>
      <span
        :class="icon"
        class="size-5 text-n-slate-10"
      />
    </div>

    <!-- Value -->
    <div class="flex items-end gap-2">
      <template v-if="loading">
        <div class="h-8 w-20 bg-n-slate-3 animate-pulse rounded" />
      </template>
      <template v-else>
        <span class="text-3xl font-bold text-n-slate-12">{{ value }}</span>
        <!-- Trend indicator -->
        <div
          v-if="trend"
          class="flex items-center gap-1 text-sm font-medium mb-1"
          :class="trend.positive ? 'text-n-teal-11' : 'text-n-ruby-11'"
        >
          <span
            :class="trend.positive ? 'i-lucide-trending-up' : 'i-lucide-trending-down'"
            class="size-4"
          />
          <span>{{ trend.value }}%</span>
        </div>
      </template>
    </div>

    <!-- Subtitle -->
    <p v-if="$slots.subtitle" class="text-xs text-n-slate-10">
      <slot name="subtitle" />
    </p>
  </div>
</template>
