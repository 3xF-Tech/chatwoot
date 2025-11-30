import CalendarIntegrationsAPI from '../../api/calendarIntegrations';

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isDeleting: false,
    isSyncing: false,
  },
};

export const getters = {
  getIntegrations: $state => $state.records,
  getUIFlags: $state => $state.uiFlags,
  getIntegrationById: $state => id => {
    return $state.records.find(record => record.id === id);
  },
  getIntegrationByProvider: $state => provider => {
    return $state.records.find(record => record.provider === provider);
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit('setUIFlag', { isFetching: true });
    try {
      const response = await CalendarIntegrationsAPI.get();
      commit('setIntegrations', response.data);
    } catch (error) {
      throw error;
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },

  delete: async ({ commit }, integrationId) => {
    commit('setUIFlag', { isDeleting: true });
    try {
      await CalendarIntegrationsAPI.delete(integrationId);
      commit('deleteIntegration', integrationId);
    } catch (error) {
      throw error;
    } finally {
      commit('setUIFlag', { isDeleting: false });
    }
  },

  sync: async ({ commit }, integrationId) => {
    commit('setUIFlag', { isSyncing: true });
    try {
      await CalendarIntegrationsAPI.sync(integrationId);
    } catch (error) {
      throw error;
    } finally {
      commit('setUIFlag', { isSyncing: false });
    }
  },

  getAuthUrl: async (_, provider) => {
    try {
      const response = await CalendarIntegrationsAPI.getAuthUrl(provider);
      return response.data;
    } catch (error) {
      const message =
        error.response?.data?.error || 'Failed to get authorization URL';
      throw new Error(message);
    }
  },

  handleCallback: async ({ commit }, { provider, code }) => {
    commit('setUIFlag', { isCreating: true });
    try {
      const response = await CalendarIntegrationsAPI.handleCallback(
        provider,
        code
      );
      commit('addIntegration', response.data);
      return response.data;
    } catch (error) {
      throw error;
    } finally {
      commit('setUIFlag', { isCreating: false });
    }
  },

  getCalendars: async (_, integrationId) => {
    const response = await CalendarIntegrationsAPI.getCalendars(integrationId);
    return response.data;
  },
};

export const mutations = {
  setUIFlag($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },

  setIntegrations($state, data) {
    $state.records = data;
  },

  addIntegration($state, data) {
    $state.records.push(data);
  },

  updateIntegration($state, data) {
    const index = $state.records.findIndex(record => record.id === data.id);
    if (index !== -1) {
      $state.records[index] = data;
    }
  },

  deleteIntegration($state, id) {
    $state.records = $state.records.filter(record => record.id !== id);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
