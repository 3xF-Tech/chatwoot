<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import Avatar from 'next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'shared/components/Spinner.vue';
import EditOpportunityDialog from 'dashboard/components-next/Opportunities/EditOpportunityDialog.vue';
import OpportunityItemsList from 'dashboard/components-next/Opportunities/OpportunityItemsList.vue';
import OpportunityActivitiesList from 'dashboard/components-next/Opportunities/OpportunityActivitiesList.vue';
import OpportunityConversationsList from 'dashboard/components-next/Opportunities/OpportunityConversationsList.vue';
import OpportunityStageHistory from 'dashboard/components-next/Opportunities/OpportunityStageHistory.vue';
import MarkLostDialog from 'dashboard/components-next/Opportunities/MarkLostDialog.vue';
import DeleteConfirmDialog from 'dashboard/components-next/Opportunities/DeleteConfirmDialog.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const isLoading = ref(true);
const activeTab = ref('overview');
const editDialogRef = ref(null);
const markLostDialogRef = ref(null);
const deleteDialogRef = ref(null);

const opportunityId = computed(() => route.params.opportunityId);

const opportunity = computed(() => {
  return store.getters['opportunities/getCurrentOpportunity'] || {};
});

const items = computed(() => {
  return store.getters['opportunities/getItems'](opportunityId.value);
});

const activities = computed(() => {
  return store.getters['opportunities/getActivities'](opportunityId.value);
});

const conversations = computed(() => {
  return store.getters['opportunities/getConversations'](opportunityId.value);
});

const stageChanges = computed(() => {
  return store.getters['opportunities/getStageChanges'](opportunityId.value);
});

const statusBadgeClass = computed(() => {
  const statusClasses = {
    open: 'bg-n-blue-3 text-n-blue-11',
    won: 'bg-n-teal-3 text-n-teal-11',
    lost: 'bg-n-ruby-3 text-n-ruby-11',
    cancelled: 'bg-n-slate-3 text-n-slate-11',
  };
  return statusClasses[opportunity.value.status] || 'bg-n-slate-3 text-n-slate-11';
});

const tabs = computed(() => [
  { key: 'overview', label: t('OPPORTUNITIES.DETAILS.OVERVIEW'), icon: 'i-lucide-info' },
  { key: 'items', label: t('OPPORTUNITIES.DETAILS.ITEMS'), icon: 'i-lucide-list', count: items.value.length },
  { key: 'activities', label: t('OPPORTUNITIES.DETAILS.ACTIVITIES'), icon: 'i-lucide-calendar', count: activities.value.length },
  { key: 'conversations', label: t('OPPORTUNITIES.DETAILS.CONVERSATIONS'), icon: 'i-lucide-messages-square', count: conversations.value.length },
  { key: 'history', label: t('OPPORTUNITIES.DETAILS.HISTORY'), icon: 'i-lucide-history' },
]);

const formatCurrency = (value, currency = 'BRL') => {
  if (!value) return '-';
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency,
  }).format(value);
};

const formattedDate = dateValue => {
  if (!dateValue) return t('OPPORTUNITIES.DETAILS.NOT_AVAILABLE');
  return new Date(dateValue).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
};

const fetchOpportunity = async () => {
  isLoading.value = true;
  try {
    await store.dispatch('opportunities/show', opportunityId.value);
    await Promise.all([
      store.dispatch('opportunities/fetchItems', opportunityId.value),
      store.dispatch('opportunities/fetchActivities', opportunityId.value),
      store.dispatch('opportunities/fetchConversations', opportunityId.value),
      store.dispatch('opportunities/fetchStageChanges', opportunityId.value),
    ]);
  } catch (error) {
    useAlert(t('OPPORTUNITIES.EDIT.ERROR_MESSAGE'));
  } finally {
    isLoading.value = false;
  }
};

const goBack = () => {
  router.push({ name: 'opportunities_index' });
};

const openEditDialog = () => {
  editDialogRef.value?.dialogRef?.open();
};

const handleOpportunityUpdated = () => {
  fetchOpportunity();
};

const handleMarkWon = async () => {
  try {
    await store.dispatch('opportunities/markWon', opportunityId.value);
    useAlert(t('OPPORTUNITIES.MARK_WON.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('OPPORTUNITIES.MARK_WON.ERROR_MESSAGE'));
  }
};

const openMarkLostDialog = () => {
  markLostDialogRef.value?.dialogRef?.open();
};

const handleMarkLost = async lostReason => {
  try {
    await store.dispatch('opportunities/markLost', {
      opportunityId: opportunityId.value,
      lostReason,
    });
    useAlert(t('OPPORTUNITIES.MARK_LOST.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('OPPORTUNITIES.MARK_LOST.ERROR_MESSAGE'));
  }
};

const openDeleteDialog = () => {
  deleteDialogRef.value?.dialogRef?.open();
};

const handleDelete = async () => {
  try {
    await store.dispatch('opportunities/delete', opportunityId.value);
    useAlert(t('OPPORTUNITIES.DELETE.SUCCESS_MESSAGE'));
    goBack();
  } catch (error) {
    useAlert(t('OPPORTUNITIES.DELETE.ERROR_MESSAGE'));
  }
};

const navigateToContact = () => {
  if (opportunity.value.contact_id) {
    router.push({
      name: 'contact_profile_dashboard',
      params: { contactId: opportunity.value.contact_id },
    });
  }
};

const navigateToCompany = () => {
  if (opportunity.value.company_id) {
    router.push({
      name: 'company_details',
      params: { companyId: opportunity.value.company_id },
    });
  }
};

onMounted(() => {
  fetchOpportunity();
});

watch(opportunityId, () => {
  fetchOpportunity();
});
</script>

<template>
  <div class="flex flex-col w-full h-full bg-n-background">
    <!-- Loading State -->
    <div
      v-if="isLoading"
      class="flex items-center justify-center w-full h-full"
    >
      <Spinner size="large" />
    </div>

    <!-- Content -->
    <div v-else class="flex flex-col w-full h-full overflow-auto">
      <!-- Header -->
      <header class="sticky top-0 z-10 bg-n-background border-b border-n-weak">
        <div
          class="flex items-center justify-between w-full py-4 px-6 mx-auto max-w-[80rem]"
        >
          <div class="flex items-center gap-4">
            <Button
              icon="i-lucide-arrow-left"
              variant="ghost"
              color="slate"
              size="sm"
              @click="goBack"
            />
            <div class="flex flex-col gap-1">
              <div class="flex items-center gap-3">
                <h1 class="text-xl font-semibold text-n-slate-12">
                  {{ opportunity.name }}
                </h1>
                <span
                  class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium"
                  :class="statusBadgeClass"
                >
                  {{ t(`OPPORTUNITIES.STATUS.${opportunity.status?.toUpperCase()}`) }}
                </span>
              </div>
              <div class="flex items-center gap-2 text-sm text-n-slate-11">
                <span>#{{ opportunity.display_id }}</span>
                <span>•</span>
                <span>{{ opportunity.pipeline_stage?.name }}</span>
                <span>•</span>
                <span class="font-medium text-n-slate-12">
                  {{ formatCurrency(opportunity.value, opportunity.currency) }}
                </span>
              </div>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <template v-if="opportunity.status === 'open'">
              <Button
                :label="t('OPPORTUNITIES.MARK_WON.CONFIRM')"
                icon="i-lucide-trophy"
                variant="ghost"
                color="teal"
                size="sm"
                @click="handleMarkWon"
              />
              <Button
                :label="t('OPPORTUNITIES.MARK_LOST.CONFIRM')"
                icon="i-lucide-x-circle"
                variant="ghost"
                color="ruby"
                size="sm"
                @click="openMarkLostDialog"
              />
            </template>
            <Button
              icon="i-lucide-pencil"
              variant="ghost"
              color="slate"
              size="sm"
              @click="openEditDialog"
            />
            <Button
              icon="i-lucide-trash-2"
              variant="ghost"
              color="ruby"
              size="sm"
              @click="openDeleteDialog"
            />
          </div>
        </div>
      </header>

      <!-- Tabs -->
      <div class="border-b border-n-weak bg-n-background">
        <div class="mx-auto max-w-[80rem] px-6">
          <nav class="flex gap-1">
            <button
              v-for="tab in tabs"
              :key="tab.key"
              type="button"
              class="px-4 py-3 text-sm font-medium transition-colors border-b-2"
              :class="[
                activeTab === tab.key
                  ? 'border-n-brand text-n-slate-12'
                  : 'border-transparent text-n-slate-11 hover:text-n-slate-12 hover:border-n-slate-6'
              ]"
              @click="activeTab = tab.key"
            >
              {{ tab.label }}
              <span
                v-if="tab.count"
                class="ml-1.5 px-1.5 py-0.5 text-xs rounded-full bg-n-slate-3 text-n-slate-11"
              >
                {{ tab.count }}
              </span>
            </button>
          </nav>
        </div>
      </div>

      <!-- Main Content -->
      <main class="flex-1 py-6 px-6">
        <div class="mx-auto max-w-[80rem]">
          <!-- Overview Tab -->
          <div v-if="activeTab === 'overview'" class="space-y-6">
            <!-- Basic Info -->
            <section class="p-6 rounded-xl border border-n-weak bg-n-solid-2">
              <h2 class="text-lg font-medium text-n-slate-12 mb-4">
                {{ t('OPPORTUNITIES.DETAILS.OVERVIEW') }}
              </h2>
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <div class="flex flex-col gap-1">
                  <span class="text-sm text-n-slate-11">
                    {{ t('OPPORTUNITIES.FORM.VALUE.LABEL') }}
                  </span>
                  <span class="text-lg font-semibold text-n-slate-12">
                    {{ formatCurrency(opportunity.value, opportunity.currency) }}
                  </span>
                </div>
                <div class="flex flex-col gap-1">
                  <span class="text-sm text-n-slate-11">
                    {{ t('OPPORTUNITIES.DETAILS.PROBABILITY') }}
                  </span>
                  <span class="text-n-slate-12">
                    {{ opportunity.pipeline_stage?.probability || 0 }}%
                  </span>
                </div>
                <div class="flex flex-col gap-1">
                  <span class="text-sm text-n-slate-11">
                    {{ t('OPPORTUNITIES.DETAILS.WEIGHTED_VALUE') }}
                  </span>
                  <span class="text-n-slate-12">
                    {{ formatCurrency(
                      (opportunity.value || 0) * ((opportunity.pipeline_stage?.probability || 0) / 100),
                      opportunity.currency
                    ) }}
                  </span>
                </div>
                <div class="flex flex-col gap-1">
                  <span class="text-sm text-n-slate-11">
                    {{ t('OPPORTUNITIES.FORM.EXPECTED_CLOSE_DATE.LABEL') }}
                  </span>
                  <span class="text-n-slate-12">
                    {{ formattedDate(opportunity.expected_close_date) }}
                  </span>
                </div>
                <div class="flex flex-col gap-1">
                  <span class="text-sm text-n-slate-11">
                    {{ t('OPPORTUNITIES.DETAILS.DAYS_IN_STAGE') }}
                  </span>
                  <span class="text-n-slate-12">
                    {{ opportunity.days_in_stage || 0 }}
                  </span>
                </div>
                <div class="flex flex-col gap-1">
                  <span class="text-sm text-n-slate-11">
                    {{ t('OPPORTUNITIES.FORM.PRIORITY.LABEL') }}
                  </span>
                  <span class="text-n-slate-12 capitalize">
                    {{ t(`OPPORTUNITIES.FORM.PRIORITY.${opportunity.priority?.toUpperCase()}`) || '-' }}
                  </span>
                </div>
              </div>
            </section>

            <!-- Contact & Company -->
            <section class="p-6 rounded-xl border border-n-weak bg-n-solid-2">
              <h2 class="text-lg font-medium text-n-slate-12 mb-4">
                {{ t('OPPORTUNITIES.FORM.CONTACT.LABEL') }} / {{ t('OPPORTUNITIES.FORM.COMPANY.LABEL') }}
              </h2>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div
                  v-if="opportunity.contact"
                  class="flex items-center gap-3 p-4 rounded-lg border border-n-weak cursor-pointer hover:bg-n-solid-3 transition-colors"
                  @click="navigateToContact"
                >
                  <Avatar
                    :src="opportunity.contact.avatar_url"
                    :name="opportunity.contact.name"
                    :size="40"
                  />
                  <div class="flex flex-col">
                    <span class="text-n-slate-12 font-medium">
                      {{ opportunity.contact.name }}
                    </span>
                    <span class="text-sm text-n-slate-11">
                      {{ opportunity.contact.email }}
                    </span>
                  </div>
                  <Icon icon="i-lucide-chevron-right" class="ml-auto text-n-slate-11" />
                </div>
                <div
                  v-if="opportunity.company"
                  class="flex items-center gap-3 p-4 rounded-lg border border-n-weak cursor-pointer hover:bg-n-solid-3 transition-colors"
                  @click="navigateToCompany"
                >
                  <Avatar
                    :src="opportunity.company.avatar_url"
                    :name="opportunity.company.name"
                    :size="40"
                  />
                  <div class="flex flex-col">
                    <span class="text-n-slate-12 font-medium">
                      {{ opportunity.company.name }}
                    </span>
                    <span class="text-sm text-n-slate-11">
                      {{ opportunity.company.domain }}
                    </span>
                  </div>
                  <Icon icon="i-lucide-chevron-right" class="ml-auto text-n-slate-11" />
                </div>
                <div
                  v-if="!opportunity.contact && !opportunity.company"
                  class="col-span-2 text-center py-8 text-n-slate-11"
                >
                  {{ t('OPPORTUNITIES.DETAILS.NO_CONTACT_OR_COMPANY') }}
                </div>
              </div>
            </section>

            <!-- Description -->
            <section
              v-if="opportunity.description"
              class="p-6 rounded-xl border border-n-weak bg-n-solid-2"
            >
              <h2 class="text-lg font-medium text-n-slate-12 mb-4">
                {{ t('OPPORTUNITIES.FORM.DESCRIPTION.LABEL') }}
              </h2>
              <p class="text-n-slate-12 whitespace-pre-wrap">
                {{ opportunity.description }}
              </p>
            </section>

            <!-- Metadata -->
            <section class="p-6 rounded-xl border border-n-weak bg-n-solid-2">
              <div class="flex items-center gap-6 text-sm text-n-slate-11">
                <div class="flex items-center gap-2">
                  <Icon icon="i-lucide-calendar-plus" class="size-4" />
                  <span>{{ t('OPPORTUNITIES.DETAILS.CREATED_AT') }}: {{ formattedDate(opportunity.created_at) }}</span>
                </div>
                <div class="flex items-center gap-2">
                  <Icon icon="i-lucide-calendar-check" class="size-4" />
                  <span>{{ t('OPPORTUNITIES.DETAILS.UPDATED_AT') }}: {{ formattedDate(opportunity.updated_at) }}</span>
                </div>
                <div v-if="opportunity.closed_at" class="flex items-center gap-2">
                  <Icon icon="i-lucide-calendar-x" class="size-4" />
                  <span>{{ t('OPPORTUNITIES.DETAILS.CLOSED_AT') }}: {{ formattedDate(opportunity.closed_at) }}</span>
                </div>
              </div>
            </section>
          </div>

          <!-- Items Tab -->
          <OpportunityItemsList
            v-else-if="activeTab === 'items'"
            :opportunity-id="opportunityId"
            :items="items"
            :currency="opportunity.currency"
            @updated="fetchOpportunity"
          />

          <!-- Activities Tab -->
          <OpportunityActivitiesList
            v-else-if="activeTab === 'activities'"
            :opportunity-id="opportunityId"
            :activities="activities"
            @updated="fetchOpportunity"
          />

          <!-- Conversations Tab -->
          <OpportunityConversationsList
            v-else-if="activeTab === 'conversations'"
            :opportunity-id="opportunityId"
            :conversations="conversations"
            @updated="fetchOpportunity"
          />

          <!-- History Tab -->
          <OpportunityStageHistory
            v-else-if="activeTab === 'history'"
            :stage-changes="stageChanges"
          />
        </div>
      </main>
    </div>

    <!-- Dialogs -->
    <EditOpportunityDialog
      ref="editDialogRef"
      :opportunity="opportunity"
      @updated="handleOpportunityUpdated"
    />

    <MarkLostDialog
      ref="markLostDialogRef"
      @confirm="handleMarkLost"
    />

    <DeleteConfirmDialog
      ref="deleteDialogRef"
      :title="t('OPPORTUNITIES.DELETE.TITLE')"
      :description="t('OPPORTUNITIES.DELETE.DESC')"
      @confirm="handleDelete"
    />
  </div>
</template>
