<script setup>
import { useI18n } from 'vue-i18n';
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import Button from 'dashboard/components-next/button/Button.vue';
import EventDialog from 'dashboard/routes/dashboard/calendar/components/EventDialog.vue';

const { t } = useI18n();
const store = useStore();

const props = defineProps({
  linkableType: {
    type: String,
    required: true,
    validator: value =>
      ['Opportunity', 'Contact', 'Company', 'Conversation'].includes(value),
  },
  linkableId: {
    type: [Number, String],
    required: true,
  },
  linkableName: {
    type: String,
    default: '',
  },
});

// State
const events = ref([]);
const isLoading = ref(false);
const showEventDialog = ref(false);
const selectedEvent = ref(null);

// Methods
const fetchEvents = async () => {
  isLoading.value = true;
  try {
    const response = await store.dispatch('calendarEvents/getByLink', {
      linkableType: props.linkableType,
      linkableId: props.linkableId,
    });
    events.value = response;
  } catch (error) {
    console.error('Failed to fetch events:', error);
  } finally {
    isLoading.value = false;
  }
};

const openCreateDialog = () => {
  selectedEvent.value = null;
  showEventDialog.value = true;
};

const openEditDialog = event => {
  selectedEvent.value = event;
  showEventDialog.value = true;
};

const handleEventSaved = async () => {
  showEventDialog.value = false;
  selectedEvent.value = null;
  await fetchEvents();
};

const handleDeleteEvent = async event => {
  if (confirm(t('CALENDAR.DELETE_CONFIRM'))) {
    await store.dispatch('calendarEvents/delete', event.id);
    await fetchEvents();
  }
};

const formatEventDateTime = event => {
  const start = new Date(event.start_time);
  if (event.all_day) {
    return start.toLocaleDateString('default', {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
    });
  }
  return start.toLocaleString('default', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });
};

const getEventTypeIcon = type => {
  const icons = {
    meeting: 'people',
    call: 'call',
    task: 'task-list-ltr',
    reminder: 'alert',
    follow_up: 'arrow-repeat',
  };
  return icons[type] || 'calendar';
};

// Lifecycle
onMounted(() => {
  fetchEvents();
});

// Watch for prop changes
watch(
  () => [props.linkableType, props.linkableId],
  () => {
    fetchEvents();
  }
);
</script>

<template>
  <div class="calendar-events-section">
    <div class="flex items-center justify-between mb-3">
      <h3 class="text-sm font-medium text-n-slate-12">
        {{ t('CALENDAR.LINKED_ITEMS') }}
      </h3>
      <Button
        variant="ghost"
        size="xs"
        icon="add"
        :label="t('CALENDAR.NEW_EVENT')"
        @click="openCreateDialog"
      />
    </div>

    <div v-if="isLoading" class="flex items-center justify-center py-4">
      <fluent-icon
        icon="spinner"
        size="16"
        class="animate-spin text-n-slate-10"
      />
    </div>

    <div v-else-if="events.length === 0" class="py-4 text-center">
      <p class="text-sm text-n-slate-10">No events scheduled</p>
    </div>

    <div v-else class="space-y-2">
      <div
        v-for="event in events"
        :key="event.id"
        class="flex items-start gap-3 p-2 rounded-lg hover:bg-n-alpha-2 group cursor-pointer"
        @click="openEditDialog(event)"
      >
        <div
          class="flex h-8 w-8 items-center justify-center rounded-lg"
          :class="{
            'bg-n-blue-3 text-n-blue-11': event.color === 'blue' || !event.color,
            'bg-n-teal-3 text-n-teal-11': event.color === 'teal',
            'bg-n-amber-3 text-n-amber-11': event.color === 'amber',
            'bg-n-ruby-3 text-n-ruby-11': event.color === 'ruby',
          }"
        >
          <fluent-icon :icon="getEventTypeIcon(event.event_type)" size="14" />
        </div>

        <div class="flex-1 min-w-0">
          <p class="font-medium text-sm text-n-slate-12 truncate">
            {{ event.title }}
          </p>
          <p class="text-xs text-n-slate-10">
            {{ formatEventDateTime(event) }}
          </p>
        </div>

        <button
          class="opacity-0 group-hover:opacity-100 p-1 rounded text-n-slate-10 hover:text-n-ruby-11 hover:bg-n-ruby-3"
          @click.stop="handleDeleteEvent(event)"
        >
          <fluent-icon icon="delete" size="14" />
        </button>
      </div>
    </div>

    <EventDialog
      v-if="showEventDialog"
      :event="selectedEvent"
      @close="showEventDialog = false"
      @saved="handleEventSaved"
    />
  </div>
</template>
