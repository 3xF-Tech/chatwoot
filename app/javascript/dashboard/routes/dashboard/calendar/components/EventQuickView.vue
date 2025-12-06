<script setup>
import { useI18n } from 'vue-i18n';
import { computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  event: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['close', 'edit', 'delete']);

const { t } = useI18n();

const formattedTime = computed(() => {
  if (props.event.all_day) {
    return t('CALENDAR.ALL_DAY');
  }

  const start = new Date(props.event.start_time);
  const end = new Date(props.event.end_time);

  const startStr = start.toLocaleTimeString('default', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });
  const endStr = end.toLocaleTimeString('default', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });

  return `${startStr} - ${endStr}`;
});

const formattedDate = computed(() => {
  const start = new Date(props.event.start_time);
  return start.toLocaleDateString('default', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
});

const eventTypeLabel = computed(() => {
  const types = {
    meeting: 'CALENDAR.EVENT_TYPES.MEETING',
    call: 'CALENDAR.EVENT_TYPES.CALL',
    task: 'CALENDAR.EVENT_TYPES.TASK',
    reminder: 'CALENDAR.EVENT_TYPES.REMINDER',
    follow_up: 'CALENDAR.EVENT_TYPES.FOLLOW_UP',
  };
  return t(types[props.event.event_type] || types.meeting);
});

const colorClass = computed(() => {
  const colors = {
    blue: 'bg-n-blue-9',
    teal: 'bg-n-teal-9',
    amber: 'bg-n-amber-9',
    ruby: 'bg-n-ruby-9',
    slate: 'bg-n-slate-9',
  };
  return colors[props.event.color] || colors.blue;
});
</script>

<template>
  <div
    class="fixed inset-0 z-50 flex items-center justify-center bg-n-alpha-black-6"
    @click.self="emit('close')"
  >
    <div
      class="w-full max-w-md rounded-xl bg-n-solid-2 shadow-xl dark:border dark:border-n-weak"
    >
      <!-- Header with color bar -->
      <div :class="colorClass" class="h-2 rounded-t-xl" />

      <div class="p-4">
        <div class="flex items-start justify-between">
          <div class="flex-1">
            <div class="flex items-center gap-2 mb-1">
              <span
                class="inline-flex items-center rounded-full bg-n-alpha-2 px-2 py-0.5 text-xs text-n-slate-11"
              >
                {{ eventTypeLabel }}
              </span>
            </div>
            <h2 class="text-xl font-semibold text-n-slate-12">
              {{ event.title }}
            </h2>
          </div>
          <button
            class="rounded p-1 text-n-slate-11 hover:bg-n-alpha-2"
            @click="emit('close')"
          >
            <fluent-icon icon="dismiss" size="16" />
          </button>
        </div>

        <div class="mt-4 space-y-3">
          <!-- Date and Time -->
          <div class="flex items-center gap-3">
            <fluent-icon icon="calendar" size="16" class="text-n-slate-10" />
            <div>
              <div class="text-sm text-n-slate-12">{{ formattedDate }}</div>
              <div class="text-sm text-n-slate-10">{{ formattedTime }}</div>
            </div>
          </div>

          <!-- Location -->
          <div v-if="event.location" class="flex items-center gap-3">
            <fluent-icon icon="location" size="16" class="text-n-slate-10" />
            <span class="text-sm text-n-slate-12">{{ event.location }}</span>
          </div>

          <!-- Video Conference Link -->
          <div
            v-if="event.video_conference_link"
            class="flex items-center gap-3"
          >
            <fluent-icon icon="video" size="16" class="text-n-slate-10" />
            <a
              :href="event.video_conference_link"
              target="_blank"
              class="text-sm text-n-brand hover:underline"
            >
              {{ t('CALENDAR.JOIN_VIDEO_CALL') }}
            </a>
          </div>

          <!-- Description -->
          <div v-if="event.description" class="mt-4">
            <h3 class="text-xs font-medium uppercase text-n-slate-10 mb-1">
              {{ t('CALENDAR.EVENT_DIALOG.DESCRIPTION') }}
            </h3>
            <p class="text-sm text-n-slate-12 whitespace-pre-wrap">
              {{ event.description }}
            </p>
          </div>

          <!-- Linked items -->
          <div v-if="event.links && event.links.length" class="mt-4">
            <h3 class="text-xs font-medium uppercase text-n-slate-10 mb-2">
              {{ t('CALENDAR.LINKED_ITEMS') }}
            </h3>
            <div class="space-y-1">
              <div
                v-for="link in event.links"
                :key="link.id"
                class="flex items-center gap-2 rounded bg-n-alpha-2 px-2 py-1.5 text-sm"
              >
                <fluent-icon
                  :icon="
                    link.linkable_type === 'Opportunity'
                      ? 'money'
                      : link.linkable_type === 'Contact'
                        ? 'person'
                        : link.linkable_type === 'Company'
                          ? 'building'
                          : 'chat'
                  "
                  size="14"
                  class="text-n-slate-10"
                />
                <span class="text-n-slate-12">
                  {{ link.linkable?.name || link.linkable?.display_id }}
                </span>
              </div>
            </div>
          </div>

          <!-- Attendees -->
          <div v-if="event.attendees && event.attendees.length" class="mt-4">
            <h3 class="text-xs font-medium uppercase text-n-slate-10 mb-2">
              {{ t('CALENDAR.ATTENDEES') }}
            </h3>
            <div class="space-y-1">
              <div
                v-for="attendee in event.attendees"
                :key="attendee.id"
                class="flex items-center gap-2 text-sm"
              >
                <div
                  class="flex h-6 w-6 items-center justify-center rounded-full bg-n-alpha-2 text-xs font-medium text-n-slate-11"
                >
                  {{
                    (
                      attendee.contact?.name ||
                      attendee.user?.name ||
                      attendee.email ||
                      '?'
                    )
                      .charAt(0)
                      .toUpperCase()
                  }}
                </div>
                <span class="text-n-slate-12">
                  {{
                    attendee.contact?.name ||
                    attendee.user?.name ||
                    attendee.email
                  }}
                </span>
                <span
                  class="text-xs text-n-slate-10"
                  :class="{
                    'text-n-teal-11': attendee.response_status === 'accepted',
                    'text-n-ruby-11': attendee.response_status === 'declined',
                    'text-n-amber-11': attendee.response_status === 'tentative',
                  }"
                >
                  {{
                    attendee.response_status === 'accepted'
                      ? '✓'
                      : attendee.response_status === 'declined'
                        ? '✗'
                        : attendee.response_status === 'tentative'
                          ? '?'
                          : ''
                  }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Actions -->
        <div class="flex justify-end gap-2 mt-6 pt-4 border-t border-n-weak">
          <Button
            variant="ghost"
            color="ruby"
            size="sm"
            icon="delete"
            :label="t('CALENDAR.DELETE')"
            @click="emit('delete', event)"
          />
          <Button
            variant="solid"
            size="sm"
            icon="edit"
            :label="t('CALENDAR.EDIT')"
            @click="emit('edit', event)"
          />
        </div>
      </div>
    </div>
  </div>
</template>
