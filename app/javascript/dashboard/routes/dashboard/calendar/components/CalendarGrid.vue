<script setup>
import { useI18n } from 'vue-i18n';
import { computed } from 'vue';

const props = defineProps({
  currentDate: {
    type: Date,
    required: true,
  },
  viewMode: {
    type: String,
    default: 'month',
  },
  events: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['date-click', 'event-click']);

const { t } = useI18n();

const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

// Month view calendar data
const calendarDays = computed(() => {
  const year = props.currentDate.getFullYear();
  const month = props.currentDate.getMonth();

  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);

  const days = [];
  const startPadding = firstDay.getDay();

  // Previous month padding
  const prevMonth = new Date(year, month, 0);
  for (let i = startPadding - 1; i >= 0; i--) {
    days.push({
      date: new Date(year, month - 1, prevMonth.getDate() - i),
      isCurrentMonth: false,
    });
  }

  // Current month days
  for (let day = 1; day <= lastDay.getDate(); day++) {
    days.push({
      date: new Date(year, month, day),
      isCurrentMonth: true,
    });
  }

  // Next month padding
  const remainingDays = 42 - days.length;
  for (let day = 1; day <= remainingDays; day++) {
    days.push({
      date: new Date(year, month + 1, day),
      isCurrentMonth: false,
    });
  }

  return days;
});

// Week view days
const weekDaysList = computed(() => {
  const date = new Date(props.currentDate);
  date.setDate(date.getDate() - date.getDay());

  const days = [];
  for (let i = 0; i < 7; i++) {
    days.push(new Date(date));
    date.setDate(date.getDate() + 1);
  }
  return days;
});

// Get events for a specific date
const getEventsForDate = date => {
  const dateStr = date.toDateString();
  return props.events.filter(event => {
    const eventDate = new Date(event.start_time).toDateString();
    return eventDate === dateStr;
  });
};

// Check if date is today
const isToday = date => {
  return date.toDateString() === new Date().toDateString();
};

// Get event color class
const getEventColorClass = event => {
  const colors = {
    blue: 'bg-n-blue-9 text-white',
    teal: 'bg-n-teal-9 text-white',
    amber: 'bg-n-amber-9 text-white',
    ruby: 'bg-n-ruby-9 text-white',
    default: 'bg-n-brand text-white',
  };
  return colors[event.color] || colors.default;
};

// Format event time
const formatEventTime = event => {
  if (event.all_day) return '';
  const date = new Date(event.start_time);
  return date.toLocaleTimeString('default', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });
};

// Get hours for day/week view
const hours = computed(() => {
  const hrs = [];
  for (let i = 0; i < 24; i++) {
    hrs.push(i);
  }
  return hrs;
});

// Get events for a specific hour
const getEventsForHour = (date, hour) => {
  return props.events.filter(event => {
    const eventDate = new Date(event.start_time);
    return (
      eventDate.toDateString() === date.toDateString() &&
      eventDate.getHours() === hour
    );
  });
};
</script>

<template>
  <div class="h-full">
    <!-- Month View -->
    <div v-if="viewMode === 'month'" class="h-full">
      <!-- Week day headers -->
      <div class="grid grid-cols-7 border-b border-n-weak bg-n-alpha-1">
        <div
          v-for="day in weekDays"
          :key="day"
          class="px-2 py-2 text-center text-xs font-medium uppercase text-n-slate-10"
        >
          {{ day }}
        </div>
      </div>

      <!-- Calendar grid -->
      <div class="grid grid-cols-7 grid-rows-6 h-[calc(100%-32px)]">
        <div
          v-for="(dayInfo, index) in calendarDays"
          :key="index"
          class="border-b border-r border-n-weak p-1 cursor-pointer hover:bg-n-alpha-2 transition-colors"
          :class="{ 'bg-n-alpha-1': !dayInfo.isCurrentMonth }"
          @click="emit('date-click', dayInfo.date)"
        >
          <div class="flex items-start justify-between">
            <span
              class="flex h-6 w-6 items-center justify-center rounded-full text-sm"
              :class="{
                'bg-n-brand text-white': isToday(dayInfo.date),
                'text-n-slate-12':
                  dayInfo.isCurrentMonth && !isToday(dayInfo.date),
                'text-n-slate-9': !dayInfo.isCurrentMonth,
              }"
            >
              {{ dayInfo.date.getDate() }}
            </span>
          </div>

          <div class="mt-1 space-y-0.5 overflow-hidden">
            <div
              v-for="event in getEventsForDate(dayInfo.date).slice(0, 3)"
              :key="event.id"
              class="truncate rounded px-1 py-0.5 text-xs cursor-pointer"
              :class="getEventColorClass(event)"
              @click.stop="emit('event-click', event)"
            >
              <span v-if="formatEventTime(event)" class="mr-1 opacity-80">
                {{ formatEventTime(event) }}
              </span>
              {{ event.title }}
            </div>
            <div
              v-if="getEventsForDate(dayInfo.date).length > 3"
              class="text-xs text-n-slate-10 px-1"
            >
              +{{ getEventsForDate(dayInfo.date).length - 3 }}
              {{ t('CALENDAR.MORE') }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Week View -->
    <div v-else-if="viewMode === 'week'" class="flex h-full flex-col">
      <!-- Header with day names -->
      <div class="grid grid-cols-8 border-b border-n-weak bg-n-alpha-1">
        <div class="w-16" />
        <div
          v-for="day in weekDaysList"
          :key="day.toISOString()"
          class="border-l border-n-weak py-2 text-center"
        >
          <div class="text-xs uppercase text-n-slate-10">
            {{ weekDays[day.getDay()] }}
          </div>
          <div
            class="mt-1 text-lg font-medium"
            :class="isToday(day) ? 'text-n-brand' : 'text-n-slate-12'"
          >
            {{ day.getDate() }}
          </div>
        </div>
      </div>

      <!-- Time grid -->
      <div class="flex-1 overflow-auto">
        <div class="grid grid-cols-8">
          <div
            v-for="hour in hours"
            :key="hour"
            class="col-span-8 grid grid-cols-8 border-b border-n-weak"
          >
            <div class="w-16 border-r border-n-weak px-2 py-2 text-right">
              <span class="text-xs text-n-slate-10">
                {{ hour.toString().padStart(2, '0') }}:00
              </span>
            </div>
            <div
              v-for="day in weekDaysList"
              :key="`${hour}-${day.toISOString()}`"
              class="min-h-[48px] border-l border-n-weak p-1 cursor-pointer hover:bg-n-alpha-2"
              @click="emit('date-click', new Date(day.setHours(hour)))"
            >
              <div
                v-for="event in getEventsForHour(day, hour)"
                :key="event.id"
                class="truncate rounded px-1 py-0.5 text-xs cursor-pointer"
                :class="getEventColorClass(event)"
                @click.stop="emit('event-click', event)"
              >
                {{ event.title }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Day View -->
    <div v-else class="flex h-full flex-col">
      <div class="flex-1 overflow-auto">
        <div class="grid grid-cols-1">
          <div
            v-for="hour in hours"
            :key="hour"
            class="flex border-b border-n-weak"
          >
            <div class="w-20 border-r border-n-weak px-2 py-3 text-right">
              <span class="text-sm text-n-slate-10">
                {{ hour.toString().padStart(2, '0') }}:00
              </span>
            </div>
            <div
              class="flex-1 min-h-[60px] p-2 cursor-pointer hover:bg-n-alpha-2"
              @click="
                emit(
                  'date-click',
                  new Date(new Date(currentDate).setHours(hour))
                )
              "
            >
              <div
                v-for="event in getEventsForHour(currentDate, hour)"
                :key="event.id"
                class="mb-1 rounded px-2 py-1 cursor-pointer"
                :class="getEventColorClass(event)"
                @click.stop="emit('event-click', event)"
              >
                <div class="font-medium">{{ event.title }}</div>
                <div v-if="event.location" class="text-xs opacity-80">
                  {{ event.location }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
