<script setup>
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import CalendarHeader from './components/CalendarHeader.vue';
import CalendarGrid from './components/CalendarGrid.vue';
import EventDialog from './components/EventDialog.vue';
import EventQuickView from './components/EventQuickView.vue';

const { t } = useI18n();
const route = useRoute();
const store = useStore();

// State
const currentDate = ref(new Date());
const viewMode = ref('month'); // month, week, day
const showEventDialog = ref(false);
const showQuickView = ref(false);
const selectedEvent = ref(null);
const selectedDate = ref(null);

// Computed
const events = computed(() => store.getters['calendarEvents/getEvents']);
const isLoading = computed(
  () => store.getters['calendarEvents/getUIFlags'].isFetching
);

// Get date range based on view mode
const dateRange = computed(() => {
  const date = currentDate.value;

  if (viewMode.value === 'month') {
    const start = new Date(date.getFullYear(), date.getMonth(), 1);
    const end = new Date(
      date.getFullYear(),
      date.getMonth() + 1,
      0,
      23,
      59,
      59
    );
    return { start, end };
  }

  if (viewMode.value === 'week') {
    const start = new Date(date);
    start.setDate(date.getDate() - date.getDay());
    start.setHours(0, 0, 0, 0);
    const end = new Date(start);
    end.setDate(start.getDate() + 6);
    end.setHours(23, 59, 59, 999);
    return { start, end };
  }

  // day view
  const start = new Date(date);
  start.setHours(0, 0, 0, 0);
  const end = new Date(date);
  end.setHours(23, 59, 59, 999);
  return { start, end };
});

// Methods
const fetchEvents = async () => {
  const { start, end } = dateRange.value;
  await store.dispatch('calendarEvents/get', {
    startTime: start.toISOString(),
    endTime: end.toISOString(),
  });
};

const handlePrevious = () => {
  const date = new Date(currentDate.value);
  if (viewMode.value === 'month') {
    date.setMonth(date.getMonth() - 1);
  } else if (viewMode.value === 'week') {
    date.setDate(date.getDate() - 7);
  } else {
    date.setDate(date.getDate() - 1);
  }
  currentDate.value = date;
};

const handleNext = () => {
  const date = new Date(currentDate.value);
  if (viewMode.value === 'month') {
    date.setMonth(date.getMonth() + 1);
  } else if (viewMode.value === 'week') {
    date.setDate(date.getDate() + 7);
  } else {
    date.setDate(date.getDate() + 1);
  }
  currentDate.value = date;
};

const handleToday = () => {
  currentDate.value = new Date();
};

const handleDateClick = date => {
  selectedDate.value = date;
  selectedEvent.value = null;
  showEventDialog.value = true;
};

const handleEventClick = event => {
  selectedEvent.value = event;
  showQuickView.value = true;
};

const handleEditEvent = event => {
  selectedEvent.value = event;
  showQuickView.value = false;
  showEventDialog.value = true;
};

const handleDeleteEvent = async event => {
  if (confirm(t('CALENDAR.DELETE_CONFIRM'))) {
    await store.dispatch('calendarEvents/delete', event.id);
  }
};

const handleEventSaved = () => {
  showEventDialog.value = false;
  selectedEvent.value = null;
  selectedDate.value = null;
  fetchEvents();
};

const handleCloseDialog = () => {
  showEventDialog.value = false;
  selectedEvent.value = null;
  selectedDate.value = null;
};

const handleCloseQuickView = () => {
  showQuickView.value = false;
  selectedEvent.value = null;
};

// Watchers
watch(dateRange, () => {
  fetchEvents();
});

// Lifecycle
onMounted(() => {
  fetchEvents();
});
</script>

<template>
  <div class="flex flex-col h-full">
    <CalendarHeader
      :current-date="currentDate"
      :view-mode="viewMode"
      :is-loading="isLoading"
      @previous="handlePrevious"
      @next="handleNext"
      @today="handleToday"
      @view-change="viewMode = $event"
      @new-event="showEventDialog = true"
    />

    <div class="flex-1 overflow-auto p-4">
      <CalendarGrid
        :current-date="currentDate"
        :view-mode="viewMode"
        :events="events"
        :is-loading="isLoading"
        @date-click="handleDateClick"
        @event-click="handleEventClick"
      />
    </div>

    <EventDialog
      v-if="showEventDialog"
      :event="selectedEvent"
      :initial-date="selectedDate"
      @close="handleCloseDialog"
      @saved="handleEventSaved"
    />

    <EventQuickView
      v-if="showQuickView && selectedEvent"
      :event="selectedEvent"
      @close="handleCloseQuickView"
      @edit="handleEditEvent"
      @delete="handleDeleteEvent"
    />
  </div>
</template>
