<script setup>
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();

const emit = defineEmits(['create-pipeline']);
</script>

<template>
  <div class="flex flex-col items-center justify-center min-h-[60vh] p-8 gap-6">
    <div class="flex items-center justify-center size-20 rounded-full bg-woot-50 dark:bg-woot-900/20">
      <Icon icon="i-lucide-git-branch" class="size-10 text-woot-500" />
    </div>

    <div class="flex flex-col items-center gap-2 text-center max-w-md">
      <h2 class="text-xl font-semibold text-n-slate-12">
        {{ t('OPPORTUNITIES.EMPTY_PIPELINE.TITLE') }}
      </h2>
      <p class="text-n-slate-11">
        {{ t('OPPORTUNITIES.EMPTY_PIPELINE.DESCRIPTION') }}
      </p>
    </div>

    <Button
      :label="t('OPPORTUNITIES.EMPTY_PIPELINE.BTN_TXT')"
      icon="i-lucide-plus"
      size="md"
      @click="emit('create-pipeline')"
    />
  </div>
</template>
