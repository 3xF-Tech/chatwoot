<script setup>
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  agent: {
    type: Object,
    required: true,
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['edit', 'delete']);

const { t } = useI18n();

const handleEdit = () => {
  emit('edit', props.agent);
};

const handleDelete = () => {
  emit('delete', props.agent);
};
</script>

<template>
  <div
    class="flex flex-col gap-4 p-5 rounded-xl border border-n-weak bg-n-solid-2 hover:border-n-slate-7 hover:shadow-md transition-all duration-200"
  >
    <!-- Agent Header -->
    <div class="flex items-start gap-3">
      <Avatar
        :name="agent.name"
        :src="agent.thumbnail"
        :size="48"
        rounded-full
        class="transition-transform duration-200 hover:scale-110"
      />
      <div class="flex-1 min-w-0">
        <div class="flex items-center gap-2">
          <span class="font-medium text-n-slate-12 truncate">
            {{ agent.name }}
          </span>
          <span
            v-if="agent.system_bot"
            class="text-xs text-n-slate-12 bg-n-blue-5 rounded-md py-0.5 px-1.5 flex-shrink-0"
          >
            {{ t('AGENT_BOTS.GLOBAL_BOT_BADGE') }}
          </span>
        </div>
        <span class="text-sm text-n-slate-11 line-clamp-2">
          {{ agent.description }}
        </span>
      </div>
    </div>

    <!-- Agent Status -->
    <div class="flex items-center gap-2 text-sm">
      <span
        class="inline-flex items-center gap-1.5 px-2 py-1 rounded-md transition-colors duration-200"
        :class="
          agent.is_active !== false
            ? 'bg-n-teal-3 text-n-teal-11'
            : 'bg-n-slate-3 text-n-slate-11'
        "
      >
        <span
          class="size-2 rounded-full"
          :class="agent.is_active !== false ? 'bg-n-teal-9' : 'bg-n-slate-9'"
        />
        {{
          agent.is_active !== false
            ? t('AI_AGENTS.MY_AGENTS.STATUS.ACTIVE')
            : t('AI_AGENTS.MY_AGENTS.STATUS.INACTIVE')
        }}
      </span>
    </div>

    <!-- Agent Actions -->
    <div class="flex gap-2 pt-2 border-t border-n-weak">
      <Button
        v-if="!agent.system_bot"
        icon="i-lucide-pen"
        :label="t('AI_AGENTS.MY_AGENTS.ACTIONS.EDIT')"
        slate
        sm
        faded
        class="flex-1 transition-all duration-200 hover:bg-n-slate-4"
        :is-loading="loading"
        @click="handleEdit"
      />
      <Button
        v-if="!agent.system_bot"
        icon="i-lucide-trash-2"
        sm
        ruby
        faded
        class="transition-all duration-200 hover:bg-n-ruby-4"
        :is-loading="loading"
        @click="handleDelete"
      />
    </div>
  </div>
</template>
