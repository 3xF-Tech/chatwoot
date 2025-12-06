<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';

import KPICard from '../components/KPICard.vue';
import UsageProgress from '../components/UsageProgress.vue';
import LineChart from '../components/LineChart.vue';

const { t } = useI18n();

// Get agents from store
const agentBots = useMapGetter('agentBots/getBots');

// Simulated data - In production, this would come from n8n/API
const loading = ref(false);
const metrics = ref({
  totalMessages: 1250,
  activeAgents: 3,
  avgResponseTime: 2.4,
  satisfactionRate: 94,
});

const usageData = ref({
  current: 750,
  limit: 1000,
});

// Trends (mock data - would come from API comparison)
const trends = computed(() => ({
  messages: { positive: true, value: 12 },
  agents: { positive: true, value: 0 },
  responseTime: { positive: true, value: 8 },
  satisfaction: { positive: true, value: 3 },
}));

// Chart data for messages over time
const messagesChartData = computed(() => ({
  labels: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'],
  datasets: [
    {
      label: t('AI_AGENTS.DASHBOARD.CHART_MESSAGES'),
      data: [120, 190, 150, 210, 180, 90, 110],
      borderColor: '#3b82f6',
      backgroundColor: 'rgba(59, 130, 246, 0.1)',
      fill: true,
      tension: 0.4,
    },
  ],
}));

// Chart data for performance
const performanceChartData = computed(() => ({
  labels: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'],
  datasets: [
    {
      label: t('AI_AGENTS.DASHBOARD.SATISFACTION'),
      data: [92, 95, 91, 96, 94, 93, 94],
      borderColor: '#10b981',
      backgroundColor: 'rgba(16, 185, 129, 0.1)',
      fill: true,
      tension: 0.4,
    },
    {
      label: t('AI_AGENTS.DASHBOARD.RESOLUTION_RATE'),
      data: [85, 88, 82, 90, 87, 84, 86],
      borderColor: '#8b5cf6',
      backgroundColor: 'rgba(139, 92, 246, 0.1)',
      fill: true,
      tension: 0.4,
    },
  ],
}));

// KPI cards configuration
const kpiCards = computed(() => [
  {
    title: t('AI_AGENTS.DASHBOARD.KPI.TOTAL_MESSAGES'),
    value: metrics.value.totalMessages.toLocaleString('pt-BR'),
    icon: 'i-lucide-message-square',
    trend: trends.value.messages,
  },
  {
    title: t('AI_AGENTS.DASHBOARD.KPI.ACTIVE_AGENTS'),
    value: agentBots.value?.length || metrics.value.activeAgents,
    icon: 'i-lucide-bot',
    trend: trends.value.agents,
  },
  {
    title: t('AI_AGENTS.DASHBOARD.KPI.AVG_RESPONSE_TIME'),
    value: `${metrics.value.avgResponseTime}s`,
    icon: 'i-lucide-clock',
    trend: trends.value.responseTime,
  },
  {
    title: t('AI_AGENTS.DASHBOARD.KPI.SATISFACTION'),
    value: `${metrics.value.satisfactionRate}%`,
    icon: 'i-lucide-smile',
    trend: trends.value.satisfaction,
  },
]);

onMounted(() => {
  // In production: fetch metrics from n8n/API
  // store.dispatch('aiAgentsMetrics/fetch');
});
</script>

<template>
  <div class="flex flex-col w-full gap-6">
    <!-- Header -->
    <div class="flex flex-col gap-2">
      <h1 class="text-2xl font-semibold text-n-slate-12">
        {{ t('AI_AGENTS.DASHBOARD.TITLE') }}
      </h1>
      <p class="text-sm text-n-slate-11">
        {{ t('AI_AGENTS.DASHBOARD.DESCRIPTION') }}
      </p>
    </div>

    <!-- KPI Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      <KPICard
        v-for="(kpi, index) in kpiCards"
        :key="index"
        :title="kpi.title"
        :value="kpi.value"
        :icon="kpi.icon"
        :trend="kpi.trend"
        :loading="loading"
      />
    </div>

    <!-- Usage Progress -->
    <UsageProgress
      :current="usageData.current"
      :limit="usageData.limit"
      :label="t('AI_AGENTS.DASHBOARD.USAGE_LABEL')"
    />

    <!-- Charts -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <div class="flex flex-col gap-3 p-5 rounded-xl border border-n-weak bg-n-solid-2">
        <h3 class="text-sm font-medium text-n-slate-11">
          {{ t('AI_AGENTS.DASHBOARD.CHART_MESSAGES') }}
        </h3>
        <div class="h-[250px]">
          <LineChart :data="messagesChartData" />
        </div>
      </div>
      <div class="flex flex-col gap-3 p-5 rounded-xl border border-n-weak bg-n-solid-2">
        <h3 class="text-sm font-medium text-n-slate-11">
          {{ t('AI_AGENTS.DASHBOARD.CHART_PERFORMANCE') }}
        </h3>
        <div class="h-[250px]">
          <LineChart :data="performanceChartData" />
        </div>
      </div>
    </div>
  </div>
</template>
