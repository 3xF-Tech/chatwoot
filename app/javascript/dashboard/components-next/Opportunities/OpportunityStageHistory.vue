<script setup>
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Avatar from 'next/avatar/Avatar.vue';

defineProps({
  stageChanges: {
    type: Array,
    default: () => [],
  },
});

const { t } = useI18n();

const formattedDate = dateValue => {
  if (!dateValue) return '-';
  return new Date(dateValue).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const formatCurrency = (value, currency = 'BRL') => {
  if (!value) return '-';
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency,
  }).format(value);
};
</script>

<template>
  <div class="space-y-4">
    <h3 class="text-lg font-medium text-n-slate-12">
      {{ t('OPPORTUNITIES.DETAILS.HISTORY') }}
    </h3>

    <!-- Empty State -->
    <div
      v-if="stageChanges.length === 0"
      class="flex flex-col items-center justify-center py-12 text-n-slate-11"
    >
      <Icon icon="i-lucide-history" class="size-12 mb-4 opacity-50" />
      <span>{{ t('OPPORTUNITIES.HISTORY.EMPTY') }}</span>
    </div>

    <!-- Timeline -->
    <div v-else class="relative">
      <!-- Timeline Line -->
      <div
        class="absolute left-4 top-0 bottom-0 w-0.5 bg-n-weak"
        aria-hidden="true"
      />

      <!-- Timeline Items -->
      <div class="space-y-4">
        <div
          v-for="change in stageChanges"
          :key="change.id"
          class="relative flex gap-4 pl-10"
        >
          <!-- Timeline Dot -->
          <div
            class="absolute left-2.5 top-1 size-3 rounded-full bg-woot-500 ring-4 ring-n-background"
          />

          <!-- Content -->
          <div class="flex-1 p-4 rounded-xl border border-n-weak bg-n-solid-2">
            <div class="flex items-start justify-between gap-4">
              <div class="flex-1">
                <!-- Stage Change -->
                <div class="flex items-center gap-2 text-sm">
                  <span class="text-n-slate-11">
                    {{ change.from_stage?.name || 'Início' }}
                  </span>
                  <Icon icon="i-lucide-arrow-right" class="size-4 text-n-slate-11" />
                  <span class="font-medium text-n-slate-12">
                    {{ change.to_stage?.name }}
                  </span>
                </div>

                <!-- Value Change -->
                <div
                  v-if="change.from_value !== change.to_value"
                  class="flex items-center gap-2 mt-2 text-sm"
                >
                  <span class="text-n-slate-11">Valor:</span>
                  <span class="text-n-slate-11">
                    {{ formatCurrency(change.from_value) }}
                  </span>
                  <Icon icon="i-lucide-arrow-right" class="size-3 text-n-slate-11" />
                  <span class="font-medium text-n-slate-12">
                    {{ formatCurrency(change.to_value) }}
                  </span>
                </div>

                <!-- Changed By -->
                <div
                  v-if="change.changed_by"
                  class="flex items-center gap-2 mt-2"
                >
                  <Avatar
                    :src="change.changed_by.avatar_url"
                    :name="change.changed_by.name"
                    :size="20"
                  />
                  <span class="text-sm text-n-slate-11">
                    {{ change.changed_by.name }}
                  </span>
                </div>
              </div>

              <!-- Date -->
              <span class="text-sm text-n-slate-11 flex-shrink-0">
                {{ formattedDate(change.created_at) }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
