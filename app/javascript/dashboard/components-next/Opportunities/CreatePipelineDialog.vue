<script setup>
import { ref, reactive, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const emit = defineEmits(['created']);

const store = useStore();
const { t } = useI18n();

const dialogRef = ref(null);
const isSubmitting = ref(false);

const formState = reactive({
  name: '',
  description: '',
});

const defaultStages = ref([
  { name: 'Prospecção', position: 0, probability: 10, stageType: 'active' },
  { name: 'Qualificação', position: 1, probability: 20, stageType: 'active' },
  { name: 'Proposta', position: 2, probability: 50, stageType: 'active' },
  { name: 'Negociação', position: 3, probability: 75, stageType: 'active' },
  { name: 'Fechamento', position: 4, probability: 90, stageType: 'active' },
  { name: 'Ganho', position: 5, probability: 100, stageType: 'won' },
  { name: 'Perdido', position: 6, probability: 0, stageType: 'lost' },
]);

const rules = {
  name: { required },
};

const v$ = useVuelidate(rules, formState);

const isFormInvalid = computed(() => v$.value.$invalid);

const resetForm = () => {
  formState.name = '';
  formState.description = '';
  v$.value.$reset();
};

const addStage = () => {
  const position = defaultStages.value.filter(s => s.stageType === 'active').length;
  defaultStages.value.splice(position, 0, {
    name: '',
    position,
    probability: 50,
    stageType: 'active',
  });
  recalculatePositions();
};

const removeStage = index => {
  const stage = defaultStages.value[index];
  // Don't allow removing won/lost stages
  if (stage.stageType !== 'active') return;
  defaultStages.value.splice(index, 1);
  recalculatePositions();
};

const recalculatePositions = () => {
  defaultStages.value.forEach((stage, index) => {
    stage.position = index;
  });
};

const handleSubmit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  // Prevent double submission
  if (isSubmitting.value) return;

  isSubmitting.value = true;
  try {
    // Create pipeline - check for existing default first
    const existingPipelines = store.getters['pipelines/getPipelines'];
    const hasDefault = existingPipelines.some(p => p.is_default);

    const pipelineResponse = await store.dispatch('pipelines/create', {
      name: formState.name,
      description: formState.description,
      is_default: !hasDefault, // Only set as default if no default exists
    });

    // Handle different response formats
    const pipeline = pipelineResponse?.payload || pipelineResponse;

    if (!pipeline?.id) {
      throw new Error('Failed to create pipeline');
    }

    // Create stages for the pipeline
    for (const stage of defaultStages.value) {
      await store.dispatch('pipelines/createStage', {
        pipelineId: pipeline.id,
        stageData: {
          name: stage.name,
          position: stage.position,
          probability: stage.probability,
          stage_type: stage.stageType,
        },
      });
    }

    useAlert(t('OPPORTUNITIES.PIPELINE.CREATE_SUCCESS'));
    emit('created', pipeline);
    resetForm();
    dialogRef.value?.close();
  } catch (error) {
    useAlert(error?.message || t('OPPORTUNITIES.PIPELINE.CREATE_ERROR'));
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
        {{ t('OPPORTUNITIES.PIPELINE.CREATE_TITLE') }}
      </h2>
      <p class="text-sm text-n-slate-11">
        {{ t('OPPORTUNITIES.PIPELINE.CREATE_DESC') }}
      </p>

      <div class="flex flex-col gap-4">
        <!-- Pipeline Name -->
        <Input
          v-model="formState.name"
          :label="t('OPPORTUNITIES.PIPELINE.NAME_LABEL')"
          :placeholder="t('OPPORTUNITIES.PIPELINE.NAME_PLACEHOLDER')"
          :has-error="v$.name.$error"
          :error-message="t('OPPORTUNITIES.PIPELINE.NAME_REQUIRED')"
          @blur="v$.name.$touch"
        />

        <!-- Pipeline Description -->
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{ t('OPPORTUNITIES.PIPELINE.DESCRIPTION_LABEL') }}
          </label>
          <textarea
            v-model="formState.description"
            :placeholder="t('OPPORTUNITIES.PIPELINE.DESCRIPTION_PLACEHOLDER')"
            rows="2"
            class="w-full px-3 py-2 text-sm bg-n-alpha-1 border border-n-weak rounded-lg text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand resize-none"
          />
        </div>

        <!-- Stages Section -->
        <div class="mt-2">
          <div class="flex items-center justify-between mb-3">
            <label class="text-sm font-medium text-n-slate-12">
              {{ t('OPPORTUNITIES.PIPELINE.STAGES_LABEL') }}
            </label>
            <button
              type="button"
              class="flex items-center gap-1 text-sm text-woot-500 hover:text-woot-600"
              @click="addStage"
            >
              <Icon icon="i-lucide-plus" class="size-4" />
              {{ t('OPPORTUNITIES.PIPELINE.ADD_STAGE') }}
            </button>
          </div>

          <div class="flex flex-col gap-2">
            <div
              v-for="(stage, index) in defaultStages"
              :key="index"
              class="flex items-center gap-2 p-2 rounded-lg bg-n-alpha-1"
            >
              <div class="flex items-center justify-center size-6 rounded bg-n-alpha-2">
                <span class="text-xs font-medium text-n-slate-11">{{ index + 1 }}</span>
              </div>

              <input
                v-model="stage.name"
                type="text"
                :placeholder="t('OPPORTUNITIES.PIPELINE.STAGE_NAME_PLACEHOLDER')"
                class="flex-1 px-2 py-1 text-sm bg-transparent border-0 text-n-slate-12 focus:outline-none"
              />

              <div class="flex items-center gap-1">
                <input
                  v-model.number="stage.probability"
                  type="number"
                  min="0"
                  max="100"
                  class="w-14 px-2 py-1 text-sm text-center bg-n-alpha-2 border-0 rounded text-n-slate-12 focus:outline-none"
                />
                <span class="text-xs text-n-slate-11">%</span>
              </div>

              <span
                :class="[
                  'px-2 py-0.5 text-xs rounded',
                  stage.stageType === 'won' ? 'bg-g-100 text-g-700 dark:bg-g-900 dark:text-g-300' :
                  stage.stageType === 'lost' ? 'bg-r-100 text-r-700 dark:bg-r-900 dark:text-r-300' :
                  'bg-b-100 text-b-700 dark:bg-b-900 dark:text-b-300'
                ]"
              >
                {{ stage.stageType === 'won' ? t('OPPORTUNITIES.STATUS.WON') :
                   stage.stageType === 'lost' ? t('OPPORTUNITIES.STATUS.LOST') :
                   t('OPPORTUNITIES.PIPELINE.ACTIVE') }}
              </span>

              <button
                v-if="stage.stageType === 'active'"
                type="button"
                class="p-1 text-n-slate-11 hover:text-r-500"
                @click="removeStage(index)"
              >
                <Icon icon="i-lucide-trash-2" class="size-4" />
              </button>
              <div v-else class="size-6" />
            </div>
          </div>
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
          :label="t('OPPORTUNITIES.PIPELINE.CREATE_SUBMIT')"
          color="blue"
          :disabled="isFormInvalid"
          :is-loading="isSubmitting"
          @click="handleSubmit"
        />
      </div>
    </template>
  </Dialog>
</template>
