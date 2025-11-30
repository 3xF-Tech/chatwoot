<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import { required } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  opportunity: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['updated']);

const store = useStore();
const { t } = useI18n();

const dialogRef = ref(null);
const isSubmitting = ref(false);

const agents = useMapGetter('agents/getAgents');
const pipelines = useMapGetter('pipelines/getPipelines');
const pipelineStages = useMapGetter('pipelines/getStagesByPipelineId');

const formState = ref({
  name: '',
  pipelineId: null,
  stageId: null,
  value: '',
  currency: 'BRL',
  expectedCloseDate: null,
  assigneeId: null,
  priority: null,
  description: '',
});

const rules = {
  name: { required },
  pipelineId: { required },
  stageId: { required },
};

const v$ = useVuelidate(rules, formState);

const isFormInvalid = computed(() => v$.value.$invalid);

const pipelineOptions = computed(() =>
  pipelines.value.map(p => ({
    value: p.id,
    label: p.name,
  }))
);

const stageOptions = computed(() => {
  if (!formState.value.pipelineId) return [];
  const stages = pipelineStages.value(formState.value.pipelineId);
  return stages.map(s => ({
    value: s.id,
    label: s.name,
  }));
});

const agentOptions = computed(() =>
  agents.value.map(a => ({
    value: a.id,
    label: a.name,
  }))
);

const priorityOptions = [
  { value: 'low', label: t('OPPORTUNITIES.FORM.PRIORITY.LOW') },
  { value: 'medium', label: t('OPPORTUNITIES.FORM.PRIORITY.MEDIUM') },
  { value: 'high', label: t('OPPORTUNITIES.FORM.PRIORITY.HIGH') },
  { value: 'urgent', label: t('OPPORTUNITIES.FORM.PRIORITY.URGENT') },
];

const currencyOptions = [
  { value: 'BRL', label: 'BRL - Real' },
  { value: 'USD', label: 'USD - Dólar' },
  { value: 'EUR', label: 'EUR - Euro' },
];

const initForm = () => {
  formState.value = {
    name: props.opportunity.name || '',
    pipelineId: props.opportunity.pipeline_id,
    stageId: props.opportunity.pipeline_stage_id,
    value: props.opportunity.value?.toString() || '',
    currency: props.opportunity.currency || 'BRL',
    expectedCloseDate: props.opportunity.expected_close_date,
    assigneeId: props.opportunity.assignee_id,
    priority: props.opportunity.priority,
    description: props.opportunity.description || '',
  };
};

watch(
  () => formState.value.pipelineId,
  async (newPipelineId, oldPipelineId) => {
    if (newPipelineId && newPipelineId !== oldPipelineId) {
      await store.dispatch('pipelines/fetchStages', newPipelineId);
    }
  }
);

const handleSubmit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  isSubmitting.value = true;
  try {
    const opportunityData = {
      id: props.opportunity.id,
      name: formState.value.name,
      pipeline_id: formState.value.pipelineId,
      pipeline_stage_id: formState.value.stageId,
      value: formState.value.value ? parseFloat(formState.value.value) : null,
      currency: formState.value.currency,
      expected_close_date: formState.value.expectedCloseDate,
      assignee_id: formState.value.assigneeId,
      priority: formState.value.priority,
      description: formState.value.description,
    };

    await store.dispatch('opportunities/update', opportunityData);
    useAlert(t('OPPORTUNITIES.EDIT.SUCCESS_MESSAGE'));
    emit('updated');
    dialogRef.value?.close();
  } catch (error) {
    useAlert(error?.message || t('OPPORTUNITIES.EDIT.ERROR_MESSAGE'));
  } finally {
    isSubmitting.value = false;
  }
};

const closeDialog = () => {
  initForm();
  dialogRef.value?.close();
};

onMounted(() => {
  initForm();
  if (props.opportunity.pipeline_id) {
    store.dispatch('pipelines/fetchStages', props.opportunity.pipeline_id);
  }
});

defineExpose({ dialogRef });
</script>

<template>
  <Dialog ref="dialogRef" width="lg" @confirm="handleSubmit">
    <div class="flex flex-col gap-4 p-4">
      <h2 class="text-lg font-medium text-n-slate-12">
        {{ t('OPPORTUNITIES.EDIT.TITLE') }}
      </h2>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <!-- Name -->
        <div class="md:col-span-2">
          <Input
            v-model="formState.name"
            :label="t('OPPORTUNITIES.FORM.NAME.LABEL')"
            :placeholder="t('OPPORTUNITIES.FORM.NAME.PLACEHOLDER')"
            :has-error="v$.name.$error"
            :error-message="t('OPPORTUNITIES.FORM.NAME.REQUIRED')"
            @blur="v$.name.$touch"
          />
        </div>

        <!-- Pipeline -->
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('OPPORTUNITIES.FORM.PIPELINE.LABEL') }}
          </label>
          <select
            v-model="formState.pipelineId"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
            :class="{ 'border-n-ruby-9': v$.pipelineId.$error }"
          >
            <option value="">
              {{ t('OPPORTUNITIES.FORM.PIPELINE.PLACEHOLDER') }}
            </option>
            <option
              v-for="opt in pipelineOptions"
              :key="opt.value"
              :value="opt.value"
            >
              {{ opt.label }}
            </option>
          </select>
        </div>

        <!-- Stage -->
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('OPPORTUNITIES.FORM.STAGE.LABEL') }}
          </label>
          <select
            v-model="formState.stageId"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand disabled:opacity-50"
            :class="{ 'border-n-ruby-9': v$.stageId.$error }"
            :disabled="!formState.pipelineId"
          >
            <option value="">
              {{ t('OPPORTUNITIES.FORM.STAGE.PLACEHOLDER') }}
            </option>
            <option
              v-for="opt in stageOptions"
              :key="opt.value"
              :value="opt.value"
            >
              {{ opt.label }}
            </option>
          </select>
        </div>

        <!-- Value -->
        <Input
          v-model="formState.value"
          type="number"
          :label="t('OPPORTUNITIES.FORM.VALUE.LABEL')"
          :placeholder="t('OPPORTUNITIES.FORM.VALUE.PLACEHOLDER')"
        />

        <!-- Currency -->
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('OPPORTUNITIES.FORM.CURRENCY.LABEL') }}
          </label>
          <select
            v-model="formState.currency"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
          >
            <option
              v-for="opt in currencyOptions"
              :key="opt.value"
              :value="opt.value"
            >
              {{ opt.label }}
            </option>
          </select>
        </div>

        <!-- Expected Close Date -->
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('OPPORTUNITIES.FORM.EXPECTED_CLOSE_DATE.LABEL') }}
          </label>
          <input
            v-model="formState.expectedCloseDate"
            type="date"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
          />
        </div>

        <!-- Assignee -->
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('OPPORTUNITIES.FORM.ASSIGNEE.LABEL') }}
          </label>
          <select
            v-model="formState.assigneeId"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
          >
            <option value="">
              {{ t('OPPORTUNITIES.FORM.ASSIGNEE.PLACEHOLDER') }}
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

        <!-- Priority -->
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('OPPORTUNITIES.FORM.PRIORITY.LABEL') }}
          </label>
          <select
            v-model="formState.priority"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
          >
            <option value="">
              {{ t('OPPORTUNITIES.FORM.PRIORITY.PLACEHOLDER') }}
            </option>
            <option
              v-for="opt in priorityOptions"
              :key="opt.value"
              :value="opt.value"
            >
              {{ opt.label }}
            </option>
          </select>
        </div>

        <!-- Description -->
        <div class="md:col-span-2 flex flex-col gap-1">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('OPPORTUNITIES.FORM.DESCRIPTION.LABEL') }}
          </label>
          <textarea
            v-model="formState.description"
            :placeholder="t('OPPORTUNITIES.FORM.DESCRIPTION.PLACEHOLDER')"
            rows="3"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 resize-none focus:outline-none focus:ring-2 focus:ring-n-brand"
          />
        </div>
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
          :label="t('OPPORTUNITIES.EDIT.SUBMIT')"
          color="blue"
          :disabled="isFormInvalid"
          :is-loading="isSubmitting"
          @click="handleSubmit"
        />
      </div>
    </template>
  </Dialog>
</template>
