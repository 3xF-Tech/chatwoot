import OpportunitiesAPI from 'dashboard/api/opportunities';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';

const MUTATION_TYPES = {
  SET_UI_FLAG: 'SET_OPPORTUNITY_UI_FLAG',
  SET: 'SET_OPPORTUNITIES',
  ADD: 'ADD_OPPORTUNITY',
  EDIT: 'EDIT_OPPORTUNITY',
  DELETE: 'DELETE_OPPORTUNITY',
  SET_META: 'SET_OPPORTUNITY_META',
  UPSERT: 'UPSERT_OPPORTUNITY',
  SET_CURRENT: 'SET_CURRENT_OPPORTUNITY',
  SET_ITEMS: 'SET_OPPORTUNITY_ITEMS',
  SET_ACTIVITIES: 'SET_OPPORTUNITY_ACTIVITIES',
  SET_CONVERSATIONS: 'SET_OPPORTUNITY_CONVERSATIONS',
  SET_STAGE_CHANGES: 'SET_OPPORTUNITY_STAGE_CHANGES',
  SET_STATS: 'SET_OPPORTUNITY_STATS',
};

export const state = {
  records: [],
  meta: {
    totalCount: 0,
    page: 1,
  },
  uiFlags: {
    fetchingList: false,
    fetchingItem: false,
    creatingItem: false,
    updatingItem: false,
    deletingItem: false,
    movingStage: false,
    fetchingStats: false,
  },
  current: null,
  items: {}, // { opportunityId: [items] }
  activities: {}, // { opportunityId: [activities] }
  conversations: {}, // { opportunityId: [conversations] }
  stageChanges: {}, // { opportunityId: [stageChanges] }
  stats: null,
};

export const getters = {
  getOpportunities: state => state.records,
  getOpportunity: state => id =>
    state.records.find(o => o.id === Number(id)) || null,
  getCurrentOpportunity: state => state.current,
  getUIFlags: state => state.uiFlags,
  getMeta: state => state.meta,
  getStats: state => state.stats,

  getOpportunitiesByStage: state => stageId =>
    state.records.filter(o => o.pipeline_stage_id === Number(stageId)),

  getOpportunitiesByPipeline: state => pipelineId =>
    state.records.filter(o => o.pipeline_id === Number(pipelineId)),

  getOpportunitiesByContact: state => contactId =>
    state.records.filter(o => o.contact_id === Number(contactId)),

  getOpportunitiesByCompany: state => companyId =>
    state.records.filter(o => o.company_id === Number(companyId)),

  getItems: state => opportunityId => state.items[opportunityId] || [],
  getActivities: state => opportunityId =>
    state.activities[opportunityId] || [],
  getConversations: state => opportunityId =>
    state.conversations[opportunityId] || [],
  getStageChanges: state => opportunityId =>
    state.stageChanges[opportunityId] || [],
};

export const mutations = {
  [MUTATION_TYPES.SET_UI_FLAG](state, data) {
    state.uiFlags = { ...state.uiFlags, ...data };
  },

  [MUTATION_TYPES.SET_META](state, meta) {
    state.meta = {
      totalCount: Number(meta.total_count || meta.totalCount || 0),
      page: Number(meta.page || 1),
    };
  },

  [MUTATION_TYPES.SET]: MutationHelpers.set,
  [MUTATION_TYPES.ADD]: MutationHelpers.create,
  [MUTATION_TYPES.EDIT]: MutationHelpers.update,
  [MUTATION_TYPES.DELETE]: MutationHelpers.destroy,
  [MUTATION_TYPES.UPSERT]: MutationHelpers.setSingleRecord,

  [MUTATION_TYPES.SET_CURRENT](state, opportunity) {
    state.current = opportunity;
  },

  [MUTATION_TYPES.SET_ITEMS](state, { opportunityId, items }) {
    state.items = { ...state.items, [opportunityId]: items };
  },

  [MUTATION_TYPES.SET_ACTIVITIES](state, { opportunityId, activities }) {
    state.activities = { ...state.activities, [opportunityId]: activities };
  },

  [MUTATION_TYPES.SET_CONVERSATIONS](state, { opportunityId, conversations }) {
    state.conversations = {
      ...state.conversations,
      [opportunityId]: conversations,
    };
  },

  [MUTATION_TYPES.SET_STAGE_CHANGES](state, { opportunityId, stageChanges }) {
    state.stageChanges = {
      ...state.stageChanges,
      [opportunityId]: stageChanges,
    };
  },

  [MUTATION_TYPES.SET_STATS](state, stats) {
    state.stats = stats;
  },
};

export const actions = {
  async get({ commit }, params = {}) {
    commit(MUTATION_TYPES.SET_UI_FLAG, { fetchingList: true });
    try {
      const response = await OpportunitiesAPI.get(params);
      const { payload, meta } = response.data;
      commit(MUTATION_TYPES.SET, payload || response.data);
      if (meta) commit(MUTATION_TYPES.SET_META, meta);
      return payload;
    } catch (error) {
      throw error;
    } finally {
      commit(MUTATION_TYPES.SET_UI_FLAG, { fetchingList: false });
    }
  },

  async show({ commit }, id) {
    commit(MUTATION_TYPES.SET_UI_FLAG, { fetchingItem: true });
    try {
      const response = await OpportunitiesAPI.show(id);
      const opportunity = response.data.payload || response.data;
      commit(MUTATION_TYPES.UPSERT, opportunity);
      commit(MUTATION_TYPES.SET_CURRENT, opportunity);
      return opportunity;
    } catch (error) {
      throw error;
    } finally {
      commit(MUTATION_TYPES.SET_UI_FLAG, { fetchingItem: false });
    }
  },

  async create({ commit }, opportunityData) {
    commit(MUTATION_TYPES.SET_UI_FLAG, { creatingItem: true });
    try {
      const response = await OpportunitiesAPI.create(opportunityData);
      const opportunity = response.data.payload || response.data;
      commit(MUTATION_TYPES.ADD, opportunity);
      return opportunity;
    } catch (error) {
      throw error;
    } finally {
      commit(MUTATION_TYPES.SET_UI_FLAG, { creatingItem: false });
    }
  },

  async update({ commit }, { id, ...opportunityData }) {
    commit(MUTATION_TYPES.SET_UI_FLAG, { updatingItem: true });
    try {
      const response = await OpportunitiesAPI.update(id, opportunityData);
      const opportunity = response.data.payload || response.data;
      commit(MUTATION_TYPES.EDIT, opportunity);
      return opportunity;
    } catch (error) {
      throw error;
    } finally {
      commit(MUTATION_TYPES.SET_UI_FLAG, { updatingItem: false });
    }
  },

  async delete({ commit }, id) {
    commit(MUTATION_TYPES.SET_UI_FLAG, { deletingItem: true });
    try {
      await OpportunitiesAPI.delete(id);
      commit(MUTATION_TYPES.DELETE, id);
    } catch (error) {
      throw error;
    } finally {
      commit(MUTATION_TYPES.SET_UI_FLAG, { deletingItem: false });
    }
  },

  async search({ commit }, { query, params = {} }) {
    commit(MUTATION_TYPES.SET_UI_FLAG, { fetchingList: true });
    try {
      const response = await OpportunitiesAPI.search(query, params);
      const { payload, meta } = response.data;
      commit(MUTATION_TYPES.SET, payload || response.data);
      if (meta) commit(MUTATION_TYPES.SET_META, meta);
      return payload;
    } catch (error) {
      throw error;
    } finally {
      commit(MUTATION_TYPES.SET_UI_FLAG, { fetchingList: false });
    }
  },

  async fetchStats({ commit }, params = {}) {
    commit(MUTATION_TYPES.SET_UI_FLAG, { fetchingStats: true });
    try {
      const response = await OpportunitiesAPI.stats(params);
      const stats = response.data.payload || response.data;
      commit(MUTATION_TYPES.SET_STATS, stats);
      return stats;
    } catch (error) {
      throw error;
    } finally {
      commit(MUTATION_TYPES.SET_UI_FLAG, { fetchingStats: false });
    }
  },

  async moveStage({ commit }, { opportunityId, stageId }) {
    commit(MUTATION_TYPES.SET_UI_FLAG, { movingStage: true });
    try {
      const response = await OpportunitiesAPI.moveStage(opportunityId, stageId);
      const opportunity = response.data.payload || response.data;
      commit(MUTATION_TYPES.EDIT, opportunity);
      return opportunity;
    } catch (error) {
      throw error;
    } finally {
      commit(MUTATION_TYPES.SET_UI_FLAG, { movingStage: false });
    }
  },

  async markWon({ commit }, opportunityId) {
    commit(MUTATION_TYPES.SET_UI_FLAG, { updatingItem: true });
    try {
      const response = await OpportunitiesAPI.markWon(opportunityId);
      const opportunity = response.data.payload || response.data;
      commit(MUTATION_TYPES.EDIT, opportunity);
      return opportunity;
    } catch (error) {
      throw error;
    } finally {
      commit(MUTATION_TYPES.SET_UI_FLAG, { updatingItem: false });
    }
  },

  async markLost({ commit }, { opportunityId, lostReason }) {
    commit(MUTATION_TYPES.SET_UI_FLAG, { updatingItem: true });
    try {
      const response = await OpportunitiesAPI.markLost(
        opportunityId,
        lostReason
      );
      const opportunity = response.data.payload || response.data;
      commit(MUTATION_TYPES.EDIT, opportunity);
      return opportunity;
    } catch (error) {
      throw error;
    } finally {
      commit(MUTATION_TYPES.SET_UI_FLAG, { updatingItem: false });
    }
  },

  // Items
  async fetchItems({ commit }, opportunityId) {
    try {
      const response = await OpportunitiesAPI.getItems(opportunityId);
      const items = response.data.payload || response.data;
      commit(MUTATION_TYPES.SET_ITEMS, { opportunityId, items });
      return items;
    } catch (error) {
      throw error;
    }
  },

  async createItem({ commit, state }, { opportunityId, itemData }) {
    try {
      const response = await OpportunitiesAPI.createItem(
        opportunityId,
        itemData
      );
      const item = response.data.payload || response.data;
      const items = [...(state.items[opportunityId] || []), item];
      commit(MUTATION_TYPES.SET_ITEMS, { opportunityId, items });
      return item;
    } catch (error) {
      throw error;
    }
  },

  async updateItem({ commit, state }, { opportunityId, itemId, itemData }) {
    try {
      const response = await OpportunitiesAPI.updateItem(
        opportunityId,
        itemId,
        itemData
      );
      const item = response.data.payload || response.data;
      const items = (state.items[opportunityId] || []).map(i =>
        i.id === itemId ? item : i
      );
      commit(MUTATION_TYPES.SET_ITEMS, { opportunityId, items });
      return item;
    } catch (error) {
      throw error;
    }
  },

  async deleteItem({ commit, state }, { opportunityId, itemId }) {
    try {
      await OpportunitiesAPI.deleteItem(opportunityId, itemId);
      const items = (state.items[opportunityId] || []).filter(
        i => i.id !== itemId
      );
      commit(MUTATION_TYPES.SET_ITEMS, { opportunityId, items });
    } catch (error) {
      throw error;
    }
  },

  // Activities
  async fetchActivities({ commit }, opportunityId) {
    try {
      const response = await OpportunitiesAPI.getActivities(opportunityId);
      const activities = response.data.payload || response.data;
      commit(MUTATION_TYPES.SET_ACTIVITIES, { opportunityId, activities });
      return activities;
    } catch (error) {
      throw error;
    }
  },

  async createActivity({ commit, state }, { opportunityId, activityData }) {
    try {
      const response = await OpportunitiesAPI.createActivity(
        opportunityId,
        activityData
      );
      const activity = response.data.payload || response.data;
      const activities = [...(state.activities[opportunityId] || []), activity];
      commit(MUTATION_TYPES.SET_ACTIVITIES, { opportunityId, activities });
      return activity;
    } catch (error) {
      throw error;
    }
  },

  async updateActivity(
    { commit, state },
    { opportunityId, activityId, activityData }
  ) {
    try {
      const response = await OpportunitiesAPI.updateActivity(
        opportunityId,
        activityId,
        activityData
      );
      const activity = response.data.payload || response.data;
      const activities = (state.activities[opportunityId] || []).map(a =>
        a.id === activityId ? activity : a
      );
      commit(MUTATION_TYPES.SET_ACTIVITIES, { opportunityId, activities });
      return activity;
    } catch (error) {
      throw error;
    }
  },

  async deleteActivity({ commit, state }, { opportunityId, activityId }) {
    try {
      await OpportunitiesAPI.deleteActivity(opportunityId, activityId);
      const activities = (state.activities[opportunityId] || []).filter(
        a => a.id !== activityId
      );
      commit(MUTATION_TYPES.SET_ACTIVITIES, { opportunityId, activities });
    } catch (error) {
      throw error;
    }
  },

  async completeActivity({ commit, state }, { opportunityId, activityId }) {
    try {
      const response = await OpportunitiesAPI.completeActivity(
        opportunityId,
        activityId
      );
      const activity = response.data.payload || response.data;
      const activities = (state.activities[opportunityId] || []).map(a =>
        a.id === activityId ? activity : a
      );
      commit(MUTATION_TYPES.SET_ACTIVITIES, { opportunityId, activities });
      return activity;
    } catch (error) {
      throw error;
    }
  },

  // Conversations
  async fetchConversations({ commit }, opportunityId) {
    try {
      const response = await OpportunitiesAPI.getConversations(opportunityId);
      const conversations = response.data.payload || response.data;
      commit(MUTATION_TYPES.SET_CONVERSATIONS, {
        opportunityId,
        conversations,
      });
      return conversations;
    } catch (error) {
      throw error;
    }
  },

  async linkConversation({ commit, state }, { opportunityId, conversationId }) {
    try {
      const response = await OpportunitiesAPI.linkConversation(
        opportunityId,
        conversationId
      );
      const conversation = response.data.payload || response.data;
      const conversations = [
        ...(state.conversations[opportunityId] || []),
        conversation,
      ];
      commit(MUTATION_TYPES.SET_CONVERSATIONS, {
        opportunityId,
        conversations,
      });
      return conversation;
    } catch (error) {
      throw error;
    }
  },

  async unlinkConversation(
    { commit, state },
    { opportunityId, conversationId }
  ) {
    try {
      await OpportunitiesAPI.unlinkConversation(opportunityId, conversationId);
      const conversations = (state.conversations[opportunityId] || []).filter(
        c => c.id !== conversationId
      );
      commit(MUTATION_TYPES.SET_CONVERSATIONS, {
        opportunityId,
        conversations,
      });
    } catch (error) {
      throw error;
    }
  },

  // Stage Changes (History)
  async fetchStageChanges({ commit }, opportunityId) {
    try {
      const response = await OpportunitiesAPI.getStageChanges(opportunityId);
      const stageChanges = response.data.payload || response.data;
      commit(MUTATION_TYPES.SET_STAGE_CHANGES, { opportunityId, stageChanges });
      return stageChanges;
    } catch (error) {
      throw error;
    }
  },

  clearCurrent({ commit }) {
    commit(MUTATION_TYPES.SET_CURRENT, null);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
