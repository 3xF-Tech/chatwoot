<script setup>
import { ref } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  opportunityId: {
    type: [Number, String],
    required: true,
  },
  conversations: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['updated']);
const store = useStore();
const router = useRouter();
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

const statusClasses = {
  open: 'bg-n-blue-3 text-n-blue-11',
  resolved: 'bg-n-teal-3 text-n-teal-11',
  pending: 'bg-n-amber-3 text-n-amber-11',
  snoozed: 'bg-n-slate-3 text-n-slate-11',
};

const navigateToConversation = conversation => {
  router.push({
    name: 'inbox_conversation',
    params: {
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.display_id,
    },
  });
};

const handleUnlink = async conversationId => {
  try {
    await store.dispatch('opportunities/unlinkConversation', {
      opportunityId: props.opportunityId,
      conversationId,
    });
    useAlert(t('OPPORTUNITIES.CONVERSATIONS.SUCCESS.UNLINK'));
    emit('updated');
  } catch (error) {
    useAlert(t('OPPORTUNITIES.CONVERSATIONS.ERROR.UNLINK'));
  }
};
</script>

<template>
  <div class="space-y-4">
    <div class="flex items-center justify-between">
      <h3 class="text-lg font-medium text-n-slate-12">
        {{ t('OPPORTUNITIES.CONVERSATIONS.TITLE') }}
      </h3>
    </div>

    <!-- Empty State -->
    <div
      v-if="conversations.length === 0"
      class="flex flex-col items-center justify-center py-12 text-n-slate-11"
    >
      <Icon icon="i-lucide-messages-square" class="size-12 mb-4 opacity-50" />
      <span>{{ t('OPPORTUNITIES.CONVERSATIONS.EMPTY') }}</span>
    </div>

    <!-- Conversations List -->
    <div v-else class="space-y-3">
      <div
        v-for="conversation in conversations"
        :key="conversation.id"
        class="p-4 rounded-xl border border-n-weak bg-n-solid-2 hover:bg-n-solid-3 cursor-pointer transition-colors"
        @click="navigateToConversation(conversation)"
      >
        <div class="flex items-start justify-between gap-4">
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-1">
              <span class="text-sm text-n-slate-11">
                #{{ conversation.display_id }}
              </span>
              <span
                class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium"
                :class="statusClasses[conversation.status] || 'bg-n-slate-3 text-n-slate-11'"
              >
                {{ conversation.status }}
              </span>
            </div>
            <p class="text-n-slate-12 line-clamp-2">
              {{ conversation.last_non_activity_message?.content || conversation.additional_attributes?.mail_subject || '-' }}
            </p>
            <div class="flex items-center gap-4 mt-2 text-sm text-n-slate-11">
              <span v-if="conversation.meta?.sender?.name" class="flex items-center gap-1">
                <Icon icon="i-lucide-user" class="size-3" />
                {{ conversation.meta.sender.name }}
              </span>
              <span class="flex items-center gap-1">
                <Icon icon="i-lucide-inbox" class="size-3" />
                {{ conversation.inbox?.name }}
              </span>
              <span class="flex items-center gap-1">
                <Icon icon="i-lucide-clock" class="size-3" />
                {{ formattedDate(conversation.last_activity_at) }}
              </span>
            </div>
          </div>

          <div class="flex items-center gap-2">
            <Button
              :label="t('OPPORTUNITIES.CONVERSATIONS.UNLINK')"
              variant="ghost"
              color="ruby"
              size="xs"
              @click.stop="handleUnlink(conversation.id)"
            />
            <Icon icon="i-lucide-chevron-right" class="size-5 text-n-slate-11" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
