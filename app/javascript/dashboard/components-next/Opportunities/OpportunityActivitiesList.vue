<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  opportunityId: {
    type: [Number, String],
    required: true,
  },
  activities: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['updated']);
const store = useStore();
const { t } = useI18n();

const isAdding = ref(false);
const agents = useMapGetter('agents/getAgents');

const newActivity = ref({
  activity_type: 'task',
  title: '',
  description: '',
  scheduled_at: null,
  assignee_id: null,
});

const activityTypeOptions = [
  { value: 'task', label: t('OPPORTUNITIES.ACTIVITIES.TYPES.TASK') },
  { value: 'call', label: t('OPPORTUNITIES.ACTIVITIES.TYPES.CALL') },
  { value: 'meeting', label: t('OPPORTUNITIES.ACTIVITIES.TYPES.MEETING') },
  { value: 'email', label: t('OPPORTUNITIES.ACTIVITIES.TYPES.EMAIL') },
  { value: 'note', label: t('OPPORTUNITIES.ACTIVITIES.TYPES.NOTE') },
  { value: 'follow_up', label: t('OPPORTUNITIES.ACTIVITIES.TYPES.FOLLOW_UP') },
];

const agentOptions = computed(() =>
  agents.value.map(a => ({
    value: a.id,
    label: a.name,
  }))
);

const activityTypeIcons = {
  task: 'i-lucide-check-square',
  call: 'i-lucide-phone',
  meeting: 'i-lucide-users',
  email: 'i-lucide-mail',
  note: 'i-lucide-sticky-note',
  follow_up: 'i-lucide-repeat',
};

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

const isOverdue = activity => {
  if (activity.is_done || !activity.scheduled_at) return false;
  return new Date(activity.scheduled_at) < new Date();
};

const resetNewActivity = () => {
  newActivity.value = {
    activity_type: 'task',
    title: '',
    description: '',
    scheduled_at: null,
    assignee_id: null,
  };
  isAdding.value = false;
};

const handleAddActivity = async () => {
  if (!newActivity.value.title) return;

  try {
    await store.dispatch('opportunities/createActivity', {
      opportunityId: props.opportunityId,
      activityData: newActivity.value,
    });
    useAlert(t('OPPORTUNITIES.ACTIVITIES.SUCCESS.CREATE'));
    emit('updated');
    resetNewActivity();
  } catch (error) {
    useAlert(t('OPPORTUNITIES.ACTIVITIES.ERROR.CREATE'));
  }
};

const handleCompleteActivity = async activityId => {
  try {
    await store.dispatch('opportunities/completeActivity', {
      opportunityId: props.opportunityId,
      activityId,
    });
    useAlert(t('OPPORTUNITIES.ACTIVITIES.SUCCESS.COMPLETE'));
    emit('updated');
  } catch (error) {
    useAlert(t('OPPORTUNITIES.ACTIVITIES.ERROR.COMPLETE'));
  }
};

const handleDeleteActivity = async activityId => {
  try {
    await store.dispatch('opportunities/deleteActivity', {
      opportunityId: props.opportunityId,
      activityId,
    });
    useAlert(t('OPPORTUNITIES.ACTIVITIES.SUCCESS.DELETE'));
    emit('updated');
  } catch (error) {
    useAlert(t('OPPORTUNITIES.ACTIVITIES.ERROR.DELETE'));
  }
};
</script>

<template>
  <div class="space-y-4">
    <div class="flex items-center justify-between">
      <h3 class="text-lg font-medium text-n-slate-12">
        {{ t('OPPORTUNITIES.ACTIVITIES.TITLE') }}
      </h3>
      <Button
        v-if="!isAdding"
        :label="t('OPPORTUNITIES.ACTIVITIES.ADD')"
        icon="i-lucide-plus"
        size="sm"
        @click="isAdding = true"
      />
    </div>

    <!-- Add Activity Form -->
    <div
      v-if="isAdding"
      class="p-4 rounded-xl border border-n-weak bg-n-solid-2 space-y-4"
    >
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('OPPORTUNITIES.ACTIVITIES.FORM.TYPE.LABEL') }}
          </label>
          <select
            v-model="newActivity.activity_type"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
          >
            <option
              v-for="opt in activityTypeOptions"
              :key="opt.value"
              :value="opt.value"
            >
              {{ opt.label }}
            </option>
          </select>
        </div>
        <Input
          v-model="newActivity.title"
          :label="t('OPPORTUNITIES.ACTIVITIES.FORM.TITLE.LABEL')"
          :placeholder="t('OPPORTUNITIES.ACTIVITIES.FORM.TITLE.PLACEHOLDER')"
        />
        <Input
          v-model="newActivity.scheduled_at"
          type="datetime-local"
          :label="t('OPPORTUNITIES.ACTIVITIES.FORM.SCHEDULED_AT.LABEL')"
        />
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('OPPORTUNITIES.ACTIVITIES.FORM.ASSIGNEE.LABEL') }}
          </label>
          <select
            v-model="newActivity.assignee_id"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
          >
            <option value="">
              {{ t('OPPORTUNITIES.ACTIVITIES.FORM.ASSIGNEE.PLACEHOLDER') }}
            </option>
            <option
              v-for="opt in agentOptions"
              :key="opt.value"
              :value="opt.value"
            >
              {{ opt.label }}
            </option>
          </select>
        </div>
        <div class="md:col-span-2 flex flex-col gap-1">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('OPPORTUNITIES.ACTIVITIES.FORM.DESCRIPTION.LABEL') }}
          </label>
          <textarea
            v-model="newActivity.description"
            :placeholder="
              t('OPPORTUNITIES.ACTIVITIES.FORM.DESCRIPTION.PLACEHOLDER')
            "
            rows="2"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 resize-none focus:outline-none focus:ring-2 focus:ring-n-brand"
          />
        </div>
      </div>
      <div class="flex items-center justify-end gap-2">
        <Button
          :label="t('DIALOG.BUTTONS.CANCEL')"
          variant="ghost"
          color="slate"
          size="sm"
          @click="resetNewActivity"
        />
        <Button
          :label="t('OPPORTUNITIES.ACTIVITIES.ADD')"
          size="sm"
          @click="handleAddActivity"
        />
      </div>
    </div>

    <!-- Activities List -->
    <div
      v-if="activities.length === 0 && !isAdding"
      class="flex flex-col items-center justify-center py-12 text-n-slate-11"
    >
      <Icon icon="i-lucide-calendar" class="size-12 mb-4 opacity-50" />
      <span>{{ t('OPPORTUNITIES.ACTIVITIES.EMPTY') }}</span>
    </div>

    <div v-else class="space-y-3">
      <div
        v-for="activity in activities"
        :key="activity.id"
        class="p-4 rounded-xl border bg-n-solid-2 transition-colors"
        :class="[
          activity.is_done ? 'border-n-weak opacity-60' : 'border-n-weak',
          isOverdue(activity)
            ? 'border-ruby-200 bg-ruby-50 dark:bg-ruby-900/10'
            : '',
        ]"
      >
        <div class="flex items-start gap-4">
          <!-- Complete Checkbox -->
          <button
            class="flex-shrink-0 size-5 rounded-full border-2 transition-colors mt-0.5"
            :class="[
              activity.is_done
                ? 'border-green-500 bg-green-500'
                : 'border-n-strong hover:border-green-500',
            ]"
            @click="!activity.is_done && handleCompleteActivity(activity.id)"
          >
            <Icon
              v-if="activity.is_done"
              icon="i-lucide-check"
              class="size-full text-white"
            />
          </button>

          <!-- Activity Content -->
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-1">
              <Icon
                :icon="
                  activityTypeIcons[activity.activity_type] || 'i-lucide-circle'
                "
                class="size-4 text-n-slate-11"
              />
              <span
                class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-n-slate-3 text-n-slate-11"
              >
                {{
                  t(
                    `OPPORTUNITIES.ACTIVITIES.TYPES.${activity.activity_type?.toUpperCase()}`
                  )
                }}
              </span>
              <span
                v-if="isOverdue(activity)"
                class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-n-ruby-3 text-n-ruby-11"
              >
                {{ t('OPPORTUNITIES.ACTIVITIES.OVERDUE') }}
              </span>
            </div>
            <h4
              class="font-medium"
              :class="[
                activity.is_done
                  ? 'line-through text-n-slate-11'
                  : 'text-n-slate-12',
              ]"
            >
              {{ activity.title }}
            </h4>
            <p v-if="activity.description" class="text-sm text-n-slate-11 mt-1">
              {{ activity.description }}
            </p>
            <div class="flex items-center gap-4 mt-2 text-sm text-n-slate-11">
              <span
                v-if="activity.scheduled_at"
                class="flex items-center gap-1"
              >
                <Icon icon="i-lucide-calendar" class="size-3" />
                {{ formattedDate(activity.scheduled_at) }}
              </span>
              <span v-if="activity.assignee" class="flex items-center gap-1">
                <Icon icon="i-lucide-user" class="size-3" />
                {{ activity.assignee.name }}
              </span>
            </div>
          </div>

          <!-- Actions -->
          <Button
            icon="i-lucide-trash-2"
            variant="ghost"
            color="ruby"
            size="xs"
            @click="handleDeleteActivity(activity.id)"
          />
        </div>
      </div>
    </div>
  </div>
</template>
