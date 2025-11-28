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
import EditCompanyDialog from 'dashboard/components-next/Companies/CompaniesForm/EditCompanyDialog.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const isLoading = ref(true);
const showEditDialog = ref(false);
const showDeleteConfirm = ref(false);
const editCompanyDialogRef = ref(null);

const companyId = computed(() => route.params.companyId);

const company = computed(() => {
  return store.getters['companies/getRecord'](companyId.value) || {};
});

const contacts = computed(() => {
  return store.getters['contacts/getContactsByCompany']?.(companyId.value) || [];
});

const formattedDate = dateValue => {
  if (!dateValue) return t('COMPANY_DETAILS.NOT_AVAILABLE');
  return new Date(dateValue).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
};

const fetchCompany = async () => {
  isLoading.value = true;
  try {
    await store.dispatch('companies/show', companyId.value);
  } catch (error) {
    useAlert(t('COMPANIES.EDIT.ERROR_MESSAGE'));
  } finally {
    isLoading.value = false;
  }
};

const goBack = () => {
  router.push({ name: 'companies_dashboard_index' });
};

const openEditDialog = () => {
  editCompanyDialogRef.value?.dialogRef?.open();
};

const handleCompanyUpdated = () => {
  fetchCompany();
};

const confirmDelete = () => {
  showDeleteConfirm.value = true;
};

const deleteCompany = async () => {
  try {
    await store.dispatch('companies/delete', companyId.value);
    useAlert(t('COMPANIES.DELETE.SUCCESS_MESSAGE'));
    goBack();
  } catch (error) {
    useAlert(t('COMPANIES.DELETE.ERROR_MESSAGE'));
  } finally {
    showDeleteConfirm.value = false;
  }
};

const navigateToContact = contactId => {
  router.push({
    name: 'contact_profile_dashboard',
    params: { contactId },
  });
};

onMounted(() => {
  fetchCompany();
});

watch(companyId, () => {
  fetchCompany();
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
          class="flex items-center justify-between w-full py-4 px-6 mx-auto max-w-[60rem]"
        >
          <div class="flex items-center gap-4">
            <Button
              icon="i-lucide-arrow-left"
              variant="ghost"
              color="slate"
              size="sm"
              @click="goBack"
            />
            <div class="flex items-center gap-3">
              <Avatar
                :src="company.avatarUrl"
                :name="company.name"
                :size="48"
                rounded-full
              />
              <div class="flex flex-col">
                <h1 class="text-xl font-semibold text-n-slate-12">
                  {{ company.name || t('COMPANIES.UNNAMED') }}
                </h1>
                <span
                  v-if="company.domain"
                  class="text-sm text-n-slate-11"
                >
                  {{ company.domain }}
                </span>
              </div>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <Button
              :label="t('COMPANY_DETAILS.ACTIONS.EDIT')"
              icon="i-lucide-pencil"
              variant="ghost"
              color="slate"
              size="sm"
              @click="openEditDialog"
            />
            <Button
              :label="t('COMPANY_DETAILS.ACTIONS.DELETE')"
              icon="i-lucide-trash-2"
              variant="ghost"
              color="ruby"
              size="sm"
              @click="confirmDelete"
            />
          </div>
        </div>
      </header>

      <!-- Main Content -->
      <main class="flex-1 py-6 px-6">
        <div class="mx-auto max-w-[60rem] space-y-6">
          <!-- Basic Info Section -->
          <section
            class="p-6 rounded-xl border border-n-weak bg-n-solid-2"
          >
            <h2 class="text-lg font-medium text-n-slate-12 mb-4">
              {{ t('COMPANY_DETAILS.OVERVIEW.BASIC_INFO') }}
            </h2>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="flex flex-col gap-1">
                <span class="text-sm text-n-slate-11">
                  {{ t('COMPANY_DETAILS.OVERVIEW.NAME') }}
                </span>
                <span class="text-n-slate-12">
                  {{ company.name || t('COMPANY_DETAILS.NOT_AVAILABLE') }}
                </span>
              </div>
              <div class="flex flex-col gap-1">
                <span class="text-sm text-n-slate-11">
                  {{ t('COMPANY_DETAILS.OVERVIEW.DOMAIN') }}
                </span>
                <a
                  v-if="company.domain"
                  :href="`https://${company.domain}`"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-n-brand hover:underline flex items-center gap-1"
                >
                  {{ company.domain }}
                  <Icon icon="i-lucide-external-link" class="size-3" />
                </a>
                <span v-else class="text-n-slate-11">
                  {{ t('COMPANY_DETAILS.NOT_AVAILABLE') }}
                </span>
              </div>
              <div class="flex flex-col gap-1 md:col-span-2">
                <span class="text-sm text-n-slate-11">
                  {{ t('COMPANY_DETAILS.OVERVIEW.DESCRIPTION') }}
                </span>
                <span class="text-n-slate-12">
                  {{
                    company.description || t('COMPANY_DETAILS.NOT_AVAILABLE')
                  }}
                </span>
              </div>
              <div class="flex flex-col gap-1">
                <span class="text-sm text-n-slate-11">
                  {{ t('COMPANY_DETAILS.OVERVIEW.CREATED_AT') }}
                </span>
                <span class="text-n-slate-12">
                  {{ formattedDate(company.createdAt) }}
                </span>
              </div>
              <div class="flex flex-col gap-1">
                <span class="text-sm text-n-slate-11">
                  {{ t('COMPANY_DETAILS.OVERVIEW.UPDATED_AT') }}
                </span>
                <span class="text-n-slate-12">
                  {{ formattedDate(company.updatedAt) }}
                </span>
              </div>
            </div>
          </section>

          <!-- Business Info Section -->
          <section
            class="p-6 rounded-xl border border-n-weak bg-n-solid-2"
          >
            <h2 class="text-lg font-medium text-n-slate-12 mb-4">
              {{ t('COMPANY_DETAILS.OVERVIEW.BUSINESS_INFO') }}
            </h2>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="flex flex-col gap-1">
                <span class="text-sm text-n-slate-11">
                  {{ t('COMPANY_DETAILS.OVERVIEW.WEBSITE') }}
                </span>
                <a
                  v-if="company.domain"
                  :href="`https://${company.domain}`"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-n-brand hover:underline flex items-center gap-1"
                >
                  https://{{ company.domain }}
                  <Icon icon="i-lucide-external-link" class="size-3" />
                </a>
                <span v-else class="text-n-slate-11">
                  {{ t('COMPANY_DETAILS.NOT_AVAILABLE') }}
                </span>
              </div>
              <div class="flex flex-col gap-1">
                <span class="text-sm text-n-slate-11">
                  {{ t('COMPANY_DETAILS.OVERVIEW.INDUSTRY') }}
                </span>
                <span class="text-n-slate-11">
                  {{ company.industry || t('COMPANY_DETAILS.NOT_AVAILABLE') }}
                </span>
              </div>
              <div class="flex flex-col gap-1">
                <span class="text-sm text-n-slate-11">
                  {{ t('COMPANY_DETAILS.OVERVIEW.EMPLOYEES') }}
                </span>
                <span class="text-n-slate-11">
                  {{
                    company.employeesCount || t('COMPANY_DETAILS.NOT_AVAILABLE')
                  }}
                </span>
              </div>
              <div class="flex flex-col gap-1">
                <span class="text-sm text-n-slate-11">
                  {{ t('COMPANY_DETAILS.OVERVIEW.REVENUE') }}
                </span>
                <span class="text-n-slate-11">
                  {{ company.revenue || t('COMPANY_DETAILS.NOT_AVAILABLE') }}
                </span>
              </div>
              <div class="flex flex-col gap-1">
                <span class="text-sm text-n-slate-11">
                  {{ t('COMPANY_DETAILS.OVERVIEW.PHONE') }}
                </span>
                <span class="text-n-slate-11">
                  {{ company.phone || t('COMPANY_DETAILS.NOT_AVAILABLE') }}
                </span>
              </div>
              <div class="flex flex-col gap-1">
                <span class="text-sm text-n-slate-11">
                  {{ t('COMPANY_DETAILS.OVERVIEW.EMAIL') }}
                </span>
                <a
                  v-if="company.email"
                  :href="`mailto:${company.email}`"
                  class="text-n-brand hover:underline"
                >
                  {{ company.email }}
                </a>
                <span v-else class="text-n-slate-11">
                  {{ t('COMPANY_DETAILS.NOT_AVAILABLE') }}
                </span>
              </div>
            </div>
          </section>

          <!-- Address Section -->
          <section
            class="p-6 rounded-xl border border-n-weak bg-n-solid-2"
          >
            <h2 class="text-lg font-medium text-n-slate-12 mb-4">
              {{ t('COMPANY_DETAILS.OVERVIEW.ADDRESS') }}
            </h2>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="flex flex-col gap-1 md:col-span-2">
                <span class="text-sm text-n-slate-11">
                  {{ t('COMPANY_DETAILS.OVERVIEW.ADDRESS') }}
                </span>
                <span class="text-n-slate-11">
                  {{ company.address || t('COMPANY_DETAILS.NOT_AVAILABLE') }}
                </span>
              </div>
              <div class="flex flex-col gap-1">
                <span class="text-sm text-n-slate-11">
                  {{ t('COMPANY_DETAILS.OVERVIEW.CITY') }}
                </span>
                <span class="text-n-slate-11">
                  {{ company.city || t('COMPANY_DETAILS.NOT_AVAILABLE') }}
                </span>
              </div>
              <div class="flex flex-col gap-1">
                <span class="text-sm text-n-slate-11">
                  {{ t('COMPANY_DETAILS.OVERVIEW.STATE') }}
                </span>
                <span class="text-n-slate-11">
                  {{ company.state || t('COMPANY_DETAILS.NOT_AVAILABLE') }}
                </span>
              </div>
              <div class="flex flex-col gap-1">
                <span class="text-sm text-n-slate-11">
                  {{ t('COMPANY_DETAILS.OVERVIEW.COUNTRY') }}
                </span>
                <span class="text-n-slate-11">
                  {{ company.country || t('COMPANY_DETAILS.NOT_AVAILABLE') }}
                </span>
              </div>
              <div class="flex flex-col gap-1">
                <span class="text-sm text-n-slate-11">
                  {{ t('COMPANY_DETAILS.OVERVIEW.POSTAL_CODE') }}
                </span>
                <span class="text-n-slate-11">
                  {{ company.postalCode || t('COMPANY_DETAILS.NOT_AVAILABLE') }}
                </span>
              </div>
            </div>
          </section>

          <!-- Contacts Section -->
          <section
            class="p-6 rounded-xl border border-n-weak bg-n-solid-2"
          >
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-lg font-medium text-n-slate-12">
                {{ t('COMPANY_DETAILS.CONTACTS.TITLE') }}
                <span
                  v-if="company.contactsCount"
                  class="text-sm text-n-slate-11 font-normal"
                >
                  ({{ company.contactsCount }})
                </span>
              </h2>
            </div>

            <div
              v-if="!company.contactsCount"
              class="text-center py-8 text-n-slate-11"
            >
              <Icon icon="i-lucide-users" class="size-12 mx-auto mb-2 opacity-50" />
              <p>{{ t('COMPANY_DETAILS.CONTACTS.EMPTY') }}</p>
            </div>

            <div v-else class="space-y-2">
              <p class="text-n-slate-11 text-sm">
                {{ t('COMPANIES.CONTACTS_COUNT', { count: company.contactsCount }) }}
              </p>
            </div>
          </section>
        </div>
      </main>
    </div>

    <!-- Edit Dialog -->
    <EditCompanyDialog
      ref="editCompanyDialogRef"
      :company="company"
      @updated="handleCompanyUpdated"
    />

    <!-- Delete Confirmation Modal -->
    <woot-delete-modal
      v-if="showDeleteConfirm"
      v-model:show="showDeleteConfirm"
      :on-close="() => (showDeleteConfirm = false)"
      :on-confirm="deleteCompany"
      :title="t('COMPANIES.DELETE.CONFIRM_TITLE')"
      :message="t('COMPANIES.DELETE.CONFIRM_MESSAGE')"
      :confirm-text="t('COMPANIES.DELETE.CONFIRM_YES')"
      :reject-text="t('COMPANIES.DELETE.CONFIRM_NO')"
    />
  </div>
</template>
