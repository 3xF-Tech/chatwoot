<script setup>
import { useI18n } from 'vue-i18n';
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  event: {
    type: Object,
    default: null,
  },
  initialDate: {
    type: Date,
    default: null,
  },
});
const emit = defineEmits(['close', 'saved']);
const { t } = useI18n();
const store = useStore();

// Form state
const form = ref({
  title: '',
  description: '',
  start_time: '',
  end_time: '',
  all_day: false,
  location: '',
  video_conference_link: '',
  event_type: 'meeting',
  color: 'blue',
  reminder_minutes: 15,
});

const isEditing = computed(() => !!props.event);
const isSubmitting = computed(
  () =>
    store.getters['calendarEvents/getUIFlags'].isCreating ||
    store.getters['calendarEvents/getUIFlags'].isUpdating
);

const eventTypes = [
  { value: 'meeting', label: 'CALENDAR.EVENT_TYPES.MEETING' },
  { value: 'call', label: 'CALENDAR.EVENT_TYPES.CALL' },
  { value: 'task', label: 'CALENDAR.EVENT_TYPES.TASK' },
  { value: 'reminder', label: 'CALENDAR.EVENT_TYPES.REMINDER' },
  { value: 'follow_up', label: 'CALENDAR.EVENT_TYPES.FOLLOW_UP' },
];

const colors = [
  { value: 'blue', class: 'bg-n-blue-9' },
  { value: 'teal', class: 'bg-n-teal-9' },
  { value: 'amber', class: 'bg-n-amber-9' },
  { value: 'ruby', class: 'bg-n-ruby-9' },
  { value: 'slate', class: 'bg-n-slate-9' },
];

const reminderOptions = [
  { value: 0, label: 'CALENDAR.REMINDERS.NONE' },
  { value: 5, label: 'CALENDAR.REMINDERS.5_MIN' },
  { value: 15, label: 'CALENDAR.REMINDERS.15_MIN' },
  { value: 30, label: 'CALENDAR.REMINDERS.30_MIN' },
  { value: 60, label: 'CALENDAR.REMINDERS.1_HOUR' },
  { value: 1440, label: 'CALENDAR.REMINDERS.1_DAY' },
];

// Format date for datetime-local input
const formatDateForInput = date => {
  const d = new Date(date);
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  const hours = String(d.getHours()).padStart(2, '0');
  const minutes = String(d.getMinutes()).padStart(2, '0');
  return `${year}-${month}-${day}T${hours}:${minutes}`;
};

// Initialize form
const initializeForm = () => {
  if (props.event) {
    form.value = {
      title: props.event.title || '',
      description: props.event.description || '',
      start_time: formatDateForInput(props.event.start_time),
      end_time: formatDateForInput(props.event.end_time),
      all_day: props.event.all_day || false,
      location: props.event.location || '',
      video_conference_link: props.event.video_conference_link || '',
      event_type: props.event.event_type || 'meeting',
      color: props.event.color || 'blue',
      reminder_minutes: props.event.reminder_minutes || 15,
    };
  } else if (props.initialDate) {
    const startDate = new Date(props.initialDate);
    const endDate = new Date(startDate);
    endDate.setHours(startDate.getHours() + 1);

    form.value.start_time = formatDateForInput(startDate);
    form.value.end_time = formatDateForInput(endDate);
  } else {
    const now = new Date();
    now.setMinutes(0, 0, 0);
    const endDate = new Date(now);
    endDate.setHours(now.getHours() + 1);

    form.value.start_time = formatDateForInput(now);
    form.value.end_time = formatDateForInput(endDate);
  }
};

// Handle all day toggle
watch(
  () => form.value.all_day,
  isAllDay => {
    if (isAllDay) {
      const start = new Date(form.value.start_time);
      start.setHours(0, 0, 0, 0);
      const end = new Date(form.value.end_time);
      end.setHours(23, 59, 59, 999);
      form.value.start_time = formatDateForInput(start);
      form.value.end_time = formatDateForInput(end);
    }
  }
);

const handleSubmit = async () => {
  const eventData = {
    ...form.value,
    start_time: new Date(form.value.start_time).toISOString(),
    end_time: new Date(form.value.end_time).toISOString(),
  };

  try {
    if (isEditing.value) {
      await store.dispatch('calendarEvents/update', {
        id: props.event.id,
        ...eventData,
      });
    } else {
      await store.dispatch('calendarEvents/create', eventData);
    }
    emit('saved');
  } catch (error) {
    console.error('Failed to save event:', error);
  }
};

onMounted(() => {
  initializeForm();
});
</script>

<template>
  <div
    class="fixed inset-0 z-50 flex items-center justify-center bg-n-alpha-black-6"
    @click.self="emit('close')"
  >
    <div
      class="w-full max-w-lg rounded-xl bg-n-solid-2 shadow-xl dark:border dark:border-n-weak"
    >
      <div class="flex items-center justify-between border-b border-n-weak p-4">
        <h2 class="text-lg font-semibold text-n-slate-12">
          {{
            isEditing
              ? t('CALENDAR.EVENT_DIALOG.EDIT_TITLE')
              : t('CALENDAR.EVENT_DIALOG.CREATE_TITLE')
          }}
        </h2>
        <button
          class="rounded p-1 text-n-slate-11 hover:bg-n-alpha-2"
          @click="emit('close')"
        >
          <fluent-icon icon="dismiss" size="16" />
        </button>
      </div>

      <form class="p-4 space-y-4" @submit.prevent="handleSubmit">
        <!-- Title -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1">
            {{ t('CALENDAR.EVENT_DIALOG.TITLE') }} *
          </label>
          <input
            v-model="form.title"
            type="text"
            required
            class="w-full rounded-lg border border-n-weak bg-n-alpha-1 px-3 py-2 text-sm text-n-slate-12 focus:border-n-brand focus:outline-none focus:ring-1 focus:ring-n-brand"
            :placeholder="t('CALENDAR.EVENT_DIALOG.TITLE_PLACEHOLDER')"
          />
        </div>

        <!-- Event Type -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1">
            {{ t('CALENDAR.EVENT_DIALOG.TYPE') }}
          </label>
          <select
            v-model="form.event_type"
            class="w-full rounded-lg border border-n-weak bg-n-alpha-1 px-3 py-2 text-sm text-n-slate-12 focus:border-n-brand focus:outline-none focus:ring-1 focus:ring-n-brand"
          >
            <option
              v-for="type in eventTypes"
              :key="type.value"
              :value="type.value"
            >
              {{ t(type.label) }}
            </option>
          </select>
        </div>

        <!-- All Day Toggle -->
        <div class="flex items-center gap-2">
          <input
            id="all_day"
            v-model="form.all_day"
            type="checkbox"
            class="h-4 w-4 rounded border-n-weak text-n-brand focus:ring-n-brand"
          />
          <label for="all_day" class="text-sm text-n-slate-12">
            {{ t('CALENDAR.EVENT_DIALOG.ALL_DAY') }}
          </label>
        </div>

        <!-- Date/Time -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-n-slate-11 mb-1">
              {{ t('CALENDAR.EVENT_DIALOG.START') }}
            </label>
            <input
              v-model="form.start_time"
              :type="form.all_day ? 'date' : 'datetime-local'"
              required
              class="w-full rounded-lg border border-n-weak bg-n-alpha-1 px-3 py-2 text-sm text-n-slate-12 focus:border-n-brand focus:outline-none focus:ring-1 focus:ring-n-brand"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-n-slate-11 mb-1">
              {{ t('CALENDAR.EVENT_DIALOG.END') }}
            </label>
            <input
              v-model="form.end_time"
              :type="form.all_day ? 'date' : 'datetime-local'"
              required
              class="w-full rounded-lg border border-n-weak bg-n-alpha-1 px-3 py-2 text-sm text-n-slate-12 focus:border-n-brand focus:outline-none focus:ring-1 focus:ring-n-brand"
            />
          </div>
        </div>

        <!-- Location -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1">
            {{ t('CALENDAR.EVENT_DIALOG.LOCATION') }}
          </label>
          <input
            v-model="form.location"
            type="text"
            class="w-full rounded-lg border border-n-weak bg-n-alpha-1 px-3 py-2 text-sm text-n-slate-12 focus:border-n-brand focus:outline-none focus:ring-1 focus:ring-n-brand"
            :placeholder="t('CALENDAR.EVENT_DIALOG.LOCATION_PLACEHOLDER')"
          />
        </div>

        <!-- Video Conference Link -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1">
            {{ t('CALENDAR.EVENT_DIALOG.VIDEO_LINK') }}
          </label>
          <input
            v-model="form.video_conference_link"
            type="url"
            class="w-full rounded-lg border border-n-weak bg-n-alpha-1 px-3 py-2 text-sm text-n-slate-12 focus:border-n-brand focus:outline-none focus:ring-1 focus:ring-n-brand"
            :placeholder="t('CALENDAR.EVENT_DIALOG.VIDEO_LINK_PLACEHOLDER')"
          />
        </div>

        <!-- Description -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1">
            {{ t('CALENDAR.EVENT_DIALOG.DESCRIPTION') }}
          </label>
          <textarea
            v-model="form.description"
            rows="3"
            class="w-full rounded-lg border border-n-weak bg-n-alpha-1 px-3 py-2 text-sm text-n-slate-12 focus:border-n-brand focus:outline-none focus:ring-1 focus:ring-n-brand"
            :placeholder="t('CALENDAR.EVENT_DIALOG.DESCRIPTION_PLACEHOLDER')"
          />
        </div>

        <!-- Color -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1">
            {{ t('CALENDAR.EVENT_DIALOG.COLOR') }}
          </label>
          <div class="flex gap-2">
            <button
              v-for="color in colors"
              :key="color.value"
              type="button"
              class="h-6 w-6 rounded-full transition-transform"
              :class="[
                color.class,
                form.color === color.value
                  ? 'ring-2 ring-n-brand ring-offset-2 scale-110'
                  : '',
              ]"
              @click="form.color = color.value"
            />
          </div>
        </div>

        <!-- Reminder -->
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-1">
            {{ t('CALENDAR.EVENT_DIALOG.REMINDER') }}
          </label>
          <select
            v-model="form.reminder_minutes"
            class="w-full rounded-lg border border-n-weak bg-n-alpha-1 px-3 py-2 text-sm text-n-slate-12 focus:border-n-brand focus:outline-none focus:ring-1 focus:ring-n-brand"
          >
            <option
              v-for="option in reminderOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ t(option.label) }}
            </option>
          </select>
        </div>

        <!-- Actions -->
        <div class="flex justify-end gap-2 pt-4">
          <Button
            variant="ghost"
            :label="t('CALENDAR.EVENT_DIALOG.CANCEL')"
            @click="emit('close')"
          />
          <Button
            variant="solid"
            color="blue"
            type="submit"
            :is-loading="isSubmitting"
            :label="
              isEditing
                ? t('CALENDAR.EVENT_DIALOG.UPDATE')
                : t('CALENDAR.EVENT_DIALOG.CREATE')
            "
          />
        </div>
      </form>
    </div>
  </div>
</template>
