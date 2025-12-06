import AiAgentSubscriptionsAPI from '../../api/aiAgentSubscriptions';

const state = {
  records: [],
  plans: {},
  usage: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isCanceling: false,
  },
};

const getters = {
  getSubscriptions: $state => $state.records,
  getPlans: $state => $state.plans,
  getUsage: $state => $state.usage,
  getUIFlags: $state => $state.uiFlags,
  getActiveSubscriptions: $state =>
    $state.records.filter(sub => sub.active),
  hasActivePlan: $state => planId =>
    $state.records.some(sub => sub.plan_id === planId && sub.active),
  getSubscriptionByPlan: $state => planId =>
    $state.records.find(sub => sub.plan_id === planId),
};

const actions = {
  async fetchPlans({ commit }) {
    commit('setUIFlag', { isFetching: true });
    try {
      const response = await AiAgentSubscriptionsAPI.getPlans();
      commit('setPlans', response.data.plans);
      return response.data;
    } catch (error) {
      throw error;
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },

  async fetchSubscriptions({ commit }) {
    commit('setUIFlag', { isFetching: true });
    try {
      const response = await AiAgentSubscriptionsAPI.getSubscriptions();
      commit('setSubscriptions', response.data.subscriptions);
      commit('setPlans', response.data.plans);
      return response.data;
    } catch (error) {
      throw error;
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },

  async fetchUsage({ commit }) {
    commit('setUIFlag', { isFetching: true });
    try {
      const response = await AiAgentSubscriptionsAPI.getUsage();
      commit('setUsage', response.data.subscriptions);
      return response.data;
    } catch (error) {
      throw error;
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },

  async startTrial({ commit }, planId) {
    commit('setUIFlag', { isCreating: true });
    try {
      const response = await AiAgentSubscriptionsAPI.startTrial(planId);
      commit('addSubscription', response.data);
      return response.data;
    } catch (error) {
      throw error;
    } finally {
      commit('setUIFlag', { isCreating: false });
    }
  },

  async checkout({ commit }, planId) {
    commit('setUIFlag', { isCreating: true });
    try {
      const response = await AiAgentSubscriptionsAPI.checkout(planId);
      // Returns checkout_url - redirect happens in component
      return response.data;
    } catch (error) {
      throw error;
    } finally {
      commit('setUIFlag', { isCreating: false });
    }
  },

  async cancelSubscription({ commit }, subscriptionId) {
    commit('setUIFlag', { isCanceling: true });
    try {
      const response = await AiAgentSubscriptionsAPI.cancelSubscription(subscriptionId);
      commit('updateSubscription', response.data);
      return response.data;
    } catch (error) {
      throw error;
    } finally {
      commit('setUIFlag', { isCanceling: false });
    }
  },
};

const mutations = {
  setSubscriptions($state, subscriptions) {
    $state.records = subscriptions;
  },

  setPlans($state, plans) {
    $state.plans = plans;
  },

  setUsage($state, usage) {
    $state.usage = usage;
  },

  addSubscription($state, subscription) {
    $state.records.push(subscription);
  },

  updateSubscription($state, subscription) {
    const index = $state.records.findIndex(s => s.id === subscription.id);
    if (index !== -1) {
      $state.records.splice(index, 1, subscription);
    }
  },

  setUIFlag($state, flag) {
    $state.uiFlags = { ...$state.uiFlags, ...flag };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
