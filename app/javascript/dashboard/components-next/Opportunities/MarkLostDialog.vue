<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['confirm']);
const { t } = useI18n();

const dialogRef = ref(null);
const lostReason = ref('');

const handleConfirm = () => {
  emit('confirm', lostReason.value);
  lostReason.value = '';
  dialogRef.value?.close();
};

const closeDialog = () => {
  lostReason.value = '';
  dialogRef.value?.close();
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog ref="dialogRef" width="md">
    <div class="flex flex-col gap-4 p-4">
      <h2 class="text-lg font-medium text-n-slate-12">
        {{ t('OPPORTUNITIES.MARK_LOST.TITLE') }}
      </h2>
      <p class="text-sm text-n-slate-11">
        {{ t('OPPORTUNITIES.MARK_LOST.DESC') }}
      </p>

      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('OPPORTUNITIES.MARK_LOST.REASON_LABEL') }}
        </label>
        <textarea
          v-model="lostReason"
          :placeholder="t('OPPORTUNITIES.MARK_LOST.REASON_PLACEHOLDER')"
          rows="4"
          class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 resize-none focus:outline-none focus:ring-2 focus:ring-n-brand"
        />
      </div>
    </div>

    <template #footer>
      <div class="flex items-center justify-end w-full gap-3">
        <Button
          :label="t('DIALOG.BUTTONS.CANCEL')"
          variant="link"
          class="h-10 hover:!no-underline hover:text-n-brand"
          @click="closeDialog"
        />
        <Button
          :label="t('OPPORTUNITIES.MARK_LOST.CONFIRM')"
          color="ruby"
          @click="handleConfirm"
        />
      </div>
    </template>
  </Dialog>
</template>
