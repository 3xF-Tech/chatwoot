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

const emit = defineEmits(['created']);

const props = defineProps({
  pipelines: {
    type: Array,
    default: () => [],
  },
  defaultPipelineId: {
    type: Number,
    default: null,
  },
  preselectedContact: {
    type: Object,
    default: null,
  },
  preselectedCompany: {
    type: Object,
    default: null,
  },
});

const store = useStore();
const { t } = useI18n();

const dialogRef = ref(null);
const isSubmitting = ref(false);

const agents = useMapGetter('agents/getAgents');
const pipelineStages = useMapGetter('pipelines/getStagesByPipelineId');

const formState = ref({
  name: '',
  pipelineId: null,
  stageId: null,
  value: '',
  currency: 'BRL',
  expectedCloseDate: null,
  contactId: null,
  companyId: null,
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
  props.pipelines.map(p => ({
    value: p.id,
    label: p.name,
  }))
);

const stageOptions = computed(() => {
  if (!formState.value.pipelineId) return [];
  const stages = pipelineStages.value(formState.value.pipelineId);
  return stages
    .filter(s => s.stage_type === 'active')
    .map(s => ({
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

// When pipeline changes, reset stage and fetch stages
watch(
  () => formState.value.pipelineId,
  async newPipelineId => {
    formState.value.stageId = null;
    if (newPipelineId) {
      await store.dispatch('pipelines/fetchStages', newPipelineId);
      // Auto-select first active stage
      const stages = pipelineStages.value(newPipelineId);
      const firstActive = stages.find(s => s.stage_type === 'active');
      if (firstActive) {
        formState.value.stageId = firstActive.id;
      }
    }
  }
);

const resetForm = () => {
  formState.value = {
    name: '',
    pipelineId: props.defaultPipelineId,
    stageId: null,
    value: '',
    currency: 'BRL',
    expectedCloseDate: null,
    contactId: props.preselectedContact?.id || null,
    companyId: props.preselectedCompany?.id || null,
    assigneeId: null,
    priority: null,
    description: '',
  };
  v$.value.$reset();
};

const handleSubmit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  // Prevent double submission
  if (isSubmitting.value) return;

  isSubmitting.value = true;
  try {
    const opportunityData = {
      name: formState.value.name,
      pipeline_id: formState.value.pipelineId,
      pipeline_stage_id: formState.value.stageId,
      value: formState.value.value ? parseFloat(formState.value.value) : null,
      currency: formState.value.currency,
      expected_close_date: formState.value.expectedCloseDate,
      contact_id: formState.value.contactId,
      company_id: formState.value.companyId,
      owner_id: formState.value.assigneeId,
      description: formState.value.description,
    };

    await store.dispatch('opportunities/create', opportunityData);
    useAlert(t('OPPORTUNITIES.CREATE.SUCCESS_MESSAGE'));
    emit('created');
    resetForm();
    dialogRef.value?.close();
  } catch (error) {
    useAlert(error?.message || t('OPPORTUNITIES.CREATE.ERROR_MESSAGE'));
  } finally {
    isSubmitting.value = false;
  }
};

const closeDialog = () => {
  resetForm();
  dialogRef.value?.close();
};

onMounted(() => {
  if (props.defaultPipelineId) {
    formState.value.pipelineId = props.defaultPipelineId;
  }
  if (props.preselectedContact) {
    formState.value.contactId = props.preselectedContact.id;
  }
  if (props.preselectedCompany) {
    formState.value.companyId = props.preselectedCompany.id;
  }
});

defineExpose({ dialogRef });
</script>

<template>
  <Dialog ref="dialogRef" width="lg" @confirm="handleSubmit">
    <div class="flex flex-col gap-4 p-4">
      <h2 class="text-lg font-medium text-n-slate-12">
        {{ t('OPPORTUNITIES.CREATE.TITLE') }}
      </h2>
      <p class="text-sm text-n-slate-11">
        {{ t('OPPORTUNITIES.CREATE.DESC') }}
      </p>

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
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{ t('OPPORTUNITIES.FORM.PIPELINE.LABEL') }}
          </label>
          <select
            v-model="formState.pipelineId"
            class="w-full px-3 py-2 text-sm bg-n-alpha-1 border rounded-lg text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
            :class="v$.pipelineId.$error ? 'border-r-400' : 'border-n-weak'"
            @blur="v$.pipelineId.$touch"
          >
            <option :value="null" disabled>{{ t('OPPORTUNITIES.FORM.PIPELINE.PLACEHOLDER') }}</option>
            <option v-for="opt in pipelineOptions" :key="opt.value" :value="opt.value">
              {{ opt.label }}
            </option>
          </select>
          <span v-if="v$.pipelineId.$error" class="text-xs text-r-400 mt-1">
            {{ t('OPPORTUNITIES.FORM.PIPELINE.REQUIRED') }}
          </span>
        </div>

        <!-- Stage -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{ t('OPPORTUNITIES.FORM.STAGE.LABEL') }}
          </label>
          <select
            v-model="formState.stageId"
            :disabled="!formState.pipelineId"
            class="w-full px-3 py-2 text-sm bg-n-alpha-1 border rounded-lg text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand disabled:opacity-50"
            :class="v$.stageId.$error ? 'border-r-400' : 'border-n-weak'"
            @blur="v$.stageId.$touch"
          >
            <option :value="null" disabled>{{ t('OPPORTUNITIES.FORM.STAGE.PLACEHOLDER') }}</option>
            <option v-for="opt in stageOptions" :key="opt.value" :value="opt.value">
              {{ opt.label }}
            </option>
          </select>
          <span v-if="v$.stageId.$error" class="text-xs text-r-400 mt-1">
            {{ t('OPPORTUNITIES.FORM.STAGE.REQUIRED') }}
          </span>
        </div>

        <!-- Value -->
        <Input
          v-model="formState.value"
          type="number"
          :label="t('OPPORTUNITIES.FORM.VALUE.LABEL')"
          :placeholder="t('OPPORTUNITIES.FORM.VALUE.PLACEHOLDER')"
        />

        <!-- Currency -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{ t('OPPORTUNITIES.FORM.CURRENCY.LABEL') }}
          </label>
          <select
            v-model="formState.currency"
            class="w-full px-3 py-2 text-sm bg-n-alpha-1 border border-n-weak rounded-lg text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
          >
            <option v-for="opt in currencyOptions" :key="opt.value" :value="opt.value">
              {{ opt.label }}
            </option>
          </select>
        </div>

        <!-- Expected Close Date -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{ t('OPPORTUNITIES.FORM.EXPECTED_CLOSE_DATE.LABEL') }}
          </label>
          <input
            v-model="formState.expectedCloseDate"
            type="date"
            class="w-full px-3 py-2 text-sm bg-n-alpha-1 border border-n-weak rounded-lg text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
            :placeholder="t('OPPORTUNITIES.FORM.EXPECTED_CLOSE_DATE.PLACEHOLDER')"
          />
        </div>

        <!-- Assignee -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{ t('OPPORTUNITIES.FORM.ASSIGNEE.LABEL') }}
          </label>
          <select
            v-model="formState.assigneeId"
            class="w-full px-3 py-2 text-sm bg-n-alpha-1 border border-n-weak rounded-lg text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
          >
            <option :value="null">{{ t('OPPORTUNITIES.FORM.ASSIGNEE.PLACEHOLDER') }}</option>
            <option v-for="opt in agentOptions" :key="opt.value" :value="opt.value">
              {{ opt.label }}
            </option>
          </select>
        </div>

        <!-- Priority -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{ t('OPPORTUNITIES.FORM.PRIORITY.LABEL') }}
          </label>
          <select
            v-model="formState.priority"
            class="w-full px-3 py-2 text-sm bg-n-alpha-1 border border-n-weak rounded-lg text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
          >
            <option :value="null">{{ t('OPPORTUNITIES.FORM.PRIORITY.PLACEHOLDER') }}</option>
            <option v-for="opt in priorityOptions" :key="opt.value" :value="opt.value">
              {{ opt.label }}
            </option>
          </select>
        </div>

        <!-- Description -->
        <div class="md:col-span-2">
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{ t('OPPORTUNITIES.FORM.DESCRIPTION.LABEL') }}
          </label>
          <textarea
            v-model="formState.description"
            :placeholder="t('OPPORTUNITIES.FORM.DESCRIPTION.PLACEHOLDER')"
            rows="3"
            class="w-full px-3 py-2 text-sm bg-n-alpha-1 border border-n-weak rounded-lg text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand resize-none"
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
          :label="t('OPPORTUNITIES.CREATE.SUBMIT')"
          color="blue"
          :disabled="isFormInvalid"
          :is-loading="isSubmitting"
          @click="handleSubmit"
        />
      </div>
    </template>
  </Dialog>
</template>
