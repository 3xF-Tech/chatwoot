<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  opportunityId: {
    type: [Number, String],
    required: true,
  },
  items: {
    type: Array,
    default: () => [],
  },
  currency: {
    type: String,
    default: 'BRL',
  },
});

const emit = defineEmits(['updated']);
const store = useStore();
const { t } = useI18n();

const isAdding = ref(false);
const editingId = ref(null);

const newItem = ref({
  name: '',
  description: '',
  quantity: 1,
  unit_price: '',
  discount_percent: 0,
});

const formatCurrency = (value, currency = 'BRL') => {
  if (!value) return '-';
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency,
  }).format(value);
};

const calculateTotal = item => {
  const qty = item.quantity || 1;
  const price = parseFloat(item.unit_price) || 0;
  const discount = item.discount_percent || 0;
  return qty * price * (1 - discount / 100);
};

const grandTotal = computed(() => {
  return props.items.reduce((sum, item) => sum + calculateTotal(item), 0);
});

const resetNewItem = () => {
  newItem.value = {
    name: '',
    description: '',
    quantity: 1,
    unit_price: '',
    discount_percent: 0,
  };
  isAdding.value = false;
};

const handleAddItem = async () => {
  if (!newItem.value.name) return;

  try {
    await store.dispatch('opportunities/createItem', {
      opportunityId: props.opportunityId,
      itemData: {
        name: newItem.value.name,
        description: newItem.value.description,
        quantity: newItem.value.quantity,
        unit_price: parseFloat(newItem.value.unit_price) || 0,
        discount_percent: newItem.value.discount_percent || 0,
      },
    });
    useAlert(t('OPPORTUNITIES.ITEMS.SUCCESS.CREATE'));
    emit('updated');
    resetNewItem();
  } catch (error) {
    useAlert(t('OPPORTUNITIES.ITEMS.ERROR.CREATE'));
  }
};

const handleDeleteItem = async itemId => {
  try {
    await store.dispatch('opportunities/deleteItem', {
      opportunityId: props.opportunityId,
      itemId,
    });
    useAlert(t('OPPORTUNITIES.ITEMS.SUCCESS.DELETE'));
    emit('updated');
  } catch (error) {
    useAlert(t('OPPORTUNITIES.ITEMS.ERROR.DELETE'));
  }
};
</script>

<template>
  <div class="space-y-4">
    <div class="flex items-center justify-between">
      <h3 class="text-lg font-medium text-n-slate-12">
        {{ t('OPPORTUNITIES.ITEMS.TITLE') }}
      </h3>
      <Button
        v-if="!isAdding"
        :label="t('OPPORTUNITIES.ITEMS.ADD')"
        icon="i-lucide-plus"
        size="sm"
        @click="isAdding = true"
      />
    </div>

    <!-- Add Item Form -->
    <div
      v-if="isAdding"
      class="p-4 rounded-xl border border-n-weak bg-n-solid-2 space-y-4"
    >
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="lg:col-span-2">
          <Input
            v-model="newItem.name"
            :label="t('OPPORTUNITIES.ITEMS.FORM.NAME.LABEL')"
            :placeholder="t('OPPORTUNITIES.ITEMS.FORM.NAME.PLACEHOLDER')"
          />
        </div>
        <Input
          v-model="newItem.quantity"
          type="number"
          :label="t('OPPORTUNITIES.ITEMS.FORM.QUANTITY.LABEL')"
          :placeholder="t('OPPORTUNITIES.ITEMS.FORM.QUANTITY.PLACEHOLDER')"
        />
        <Input
          v-model="newItem.unit_price"
          type="number"
          :label="t('OPPORTUNITIES.ITEMS.FORM.UNIT_PRICE.LABEL')"
          :placeholder="t('OPPORTUNITIES.ITEMS.FORM.UNIT_PRICE.PLACEHOLDER')"
        />
        <Input
          v-model="newItem.discount_percent"
          type="number"
          :label="t('OPPORTUNITIES.ITEMS.FORM.DISCOUNT_PERCENT.LABEL')"
          :placeholder="
            t('OPPORTUNITIES.ITEMS.FORM.DISCOUNT_PERCENT.PLACEHOLDER')
          "
        />
        <div class="lg:col-span-3">
          <Input
            v-model="newItem.description"
            :label="t('OPPORTUNITIES.ITEMS.FORM.DESCRIPTION.LABEL')"
            :placeholder="t('OPPORTUNITIES.ITEMS.FORM.DESCRIPTION.PLACEHOLDER')"
          />
        </div>
      </div>
      <div class="flex items-center justify-end gap-2">
        <Button
          :label="t('DIALOG.BUTTONS.CANCEL')"
          variant="ghost"
          color="slate"
          size="sm"
          @click="resetNewItem"
        />
        <Button
          :label="t('OPPORTUNITIES.ITEMS.ADD')"
          size="sm"
          @click="handleAddItem"
        />
      </div>
    </div>

    <!-- Items List -->
    <div
      v-if="items.length === 0 && !isAdding"
      class="flex flex-col items-center justify-center py-12 text-n-slate-11"
    >
      <Icon icon="i-lucide-package" class="size-12 mb-4 opacity-50" />
      <span>{{ t('OPPORTUNITIES.ITEMS.EMPTY') }}</span>
    </div>

    <div v-else class="overflow-x-auto">
      <table class="w-full">
        <thead>
          <tr class="border-b border-n-weak">
            <th class="text-left py-3 px-4 text-sm font-medium text-n-slate-11">
              {{ t('OPPORTUNITIES.ITEMS.FORM.NAME.LABEL') }}
            </th>
            <th
              class="text-right py-3 px-4 text-sm font-medium text-n-slate-11"
            >
              {{ t('OPPORTUNITIES.ITEMS.FORM.QUANTITY.LABEL') }}
            </th>
            <th
              class="text-right py-3 px-4 text-sm font-medium text-n-slate-11"
            >
              {{ t('OPPORTUNITIES.ITEMS.FORM.UNIT_PRICE.LABEL') }}
            </th>
            <th
              class="text-right py-3 px-4 text-sm font-medium text-n-slate-11"
            >
              {{ t('OPPORTUNITIES.ITEMS.FORM.DISCOUNT_PERCENT.LABEL') }}
            </th>
            <th
              class="text-right py-3 px-4 text-sm font-medium text-n-slate-11"
            >
              {{ t('OPPORTUNITIES.ITEMS.FORM.TOTAL.LABEL') }}
            </th>
            <th class="w-12" />
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="item in items"
            :key="item.id"
            class="border-b border-n-weak hover:bg-n-solid-2"
          >
            <td class="py-3 px-4">
              <div class="flex flex-col">
                <span class="text-n-slate-12">{{ item.name }}</span>
                <span v-if="item.description" class="text-sm text-n-slate-11">
                  {{ item.description }}
                </span>
              </div>
            </td>
            <td class="text-right py-3 px-4 text-n-slate-12">
              {{ item.quantity }}
            </td>
            <td class="text-right py-3 px-4 text-n-slate-12">
              {{ formatCurrency(item.unit_price, currency) }}
            </td>
            <td class="text-right py-3 px-4 text-n-slate-12">
              {{ item.discount_percent || 0 }}%
            </td>
            <td class="text-right py-3 px-4 font-medium text-n-slate-12">
              {{ formatCurrency(calculateTotal(item), currency) }}
            </td>
            <td class="py-3 px-4">
              <Button
                icon="i-lucide-trash-2"
                variant="ghost"
                color="ruby"
                size="xs"
                @click="handleDeleteItem(item.id)"
              />
            </td>
          </tr>
        </tbody>
        <tfoot>
          <tr class="bg-n-solid-2">
            <td
              colspan="4"
              class="py-3 px-4 text-right font-medium text-n-slate-12"
            >
              {{ t('OPPORTUNITIES.ITEMS.SUMMARY.TOTAL') }}
            </td>
            <td
              class="py-3 px-4 text-right font-semibold text-lg text-n-slate-12"
            >
              {{ formatCurrency(grandTotal, currency) }}
            </td>
            <td />
          </tr>
        </tfoot>
      </table>
    </div>
  </div>
</template>
