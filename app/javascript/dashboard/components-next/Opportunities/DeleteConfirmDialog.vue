<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
});
const emit = defineEmits(['confirm']);
const { t } = useI18n();

const dialogRef = ref(null);

const handleConfirm = () => {
  emit('confirm');
  dialogRef.value?.close();
};

const closeDialog = () => {
  dialogRef.value?.close();
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog ref="dialogRef" width="md">
    <div class="flex flex-col gap-4 p-4">
      <h2 class="text-lg font-medium text-n-slate-12">
        {{ title }}
      </h2>
      <p class="text-sm text-n-slate-11">
        {{ description }}
      </p>
    </div>

    <template #footer>
      <div class="flex items-center justify-end w-full gap-3">
        <Button
          :label="t('OPPORTUNITIES.DELETE.CANCEL')"
          variant="link"
          class="h-10 hover:!no-underline hover:text-n-brand"
          @click="closeDialog"
        />
        <Button
          :label="t('OPPORTUNITIES.DELETE.CONFIRM')"
          color="ruby"
          @click="handleConfirm"
        />
      </div>
    </template>
  </Dialog>
</template>
