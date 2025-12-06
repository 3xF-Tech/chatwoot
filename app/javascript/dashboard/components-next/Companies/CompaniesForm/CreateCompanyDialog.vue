<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const emit = defineEmits(['created']);

const store = useStore();
const { t } = useI18n();

const dialogRef = ref(null);
const isSubmitting = ref(false);

const formState = ref({
  name: '',
  domain: '',
  description: '',
});

const rules = {
  name: { required },
};

const v$ = useVuelidate(rules, formState);

const isFormInvalid = computed(() => v$.value.$invalid);

const resetForm = () => {
  formState.value = {
    name: '',
    domain: '',
    description: '',
  };
  v$.value.$reset();
};

const handleSubmit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  isSubmitting.value = true;
  try {
    await store.dispatch('companies/create', {
      name: formState.value.name,
      domain: formState.value.domain || undefined,
      description: formState.value.description || undefined,
    });
    useAlert(t('COMPANIES.CREATE.SUCCESS_MESSAGE'));
    emit('created');
    resetForm();
    dialogRef.value?.close();
  } catch (error) {
    useAlert(error?.message || t('COMPANIES.CREATE.ERROR_MESSAGE'));
  } finally {
    isSubmitting.value = false;
  }
};

const closeDialog = () => {
  resetForm();
  dialogRef.value?.close();
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog ref="dialogRef" width="lg" @confirm="handleSubmit">
    <div class="flex flex-col gap-4 p-4">
      <h2 class="text-lg font-medium text-n-slate-12">
        {{ t('COMPANIES.CREATE.TITLE') }}
      </h2>

      <div class="flex flex-col gap-3">
        <Input
          v-model="formState.name"
          :label="t('COMPANIES.FORM.NAME.LABEL')"
          :placeholder="t('COMPANIES.FORM.NAME.PLACEHOLDER')"
          :has-error="v$.name.$error"
          :error-message="t('COMPANIES.FORM.NAME.ERROR')"
          @blur="v$.name.$touch"
        />

        <Input
          v-model="formState.domain"
          :label="t('COMPANIES.FORM.DOMAIN.LABEL')"
          :placeholder="t('COMPANIES.FORM.DOMAIN.PLACEHOLDER')"
          :help-text="t('COMPANIES.FORM.DOMAIN.HELP_TEXT')"
        />

        <TextArea
          v-model="formState.description"
          :label="t('COMPANIES.FORM.DESCRIPTION.LABEL')"
          :placeholder="t('COMPANIES.FORM.DESCRIPTION.PLACEHOLDER')"
          :rows="3"
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
          :label="t('COMPANIES.CREATE.SUBMIT')"
          color="blue"
          :disabled="isFormInvalid"
          :is-loading="isSubmitting"
          @click="handleSubmit"
        />
      </div>
    </template>
  </Dialog>
</template>
