import PipelinesAPI from 'dashboard/api/pipelines';
import PipelineStagesAPI from 'dashboard/api/pipelineStages';
import { createStore } from 'dashboard/store/captain/storeFactory';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';

const MUTATION_TYPES = {
  SET_UI_FLAG: 'SET_PIPELINE_UI_FLAG',
  SET: 'SET_PIPELINE',
  ADD: 'ADD_PIPELINE',
  EDIT: 'EDIT_PIPELINE',
  DELETE: 'DELETE_PIPELINE',
  SET_META: 'SET_PIPELINE_META',
  UPSERT: 'UPSERT_PIPELINE',
  SET_STAGES: 'SET_PIPELINE_STAGES',
  ADD_STAGE: 'ADD_PIPELINE_STAGE',
  EDIT_STAGE: 'EDIT_PIPELINE_STAGE',
  DELETE_STAGE: 'DELETE_PIPELINE_STAGE',
};

const baseStore = createStore({
  name: 'Pipeline',
  API: PipelinesAPI,
});

export const state = {
  ...baseStore.state,
  stages: {}, // { pipelineId: [stages] }
};

export const getters = {
  ...baseStore.getters,
  getPipelines: state => state.records,
  getDefaultPipeline: state => state.records.find(p => p.is_default),
  getPipelineById: state => id =>
    state.records.find(p => p.id === Number(id)) || {},
  getStagesByPipelineId: state => pipelineId => state.stages[pipelineId] || [],
  getStageById: state => (pipelineId, stageId) => {
    const stages = state.stages[pipelineId] || [];
    return stages.find(s => s.id === Number(stageId)) || {};
  },
};

export const mutations = {
  ...baseStore.mutations,
  [MUTATION_TYPES.SET_STAGES](state, { pipelineId, stages }) {
    state.stages = {
      ...state.stages,
      [pipelineId]: stages,
    };
  },
  [MUTATION_TYPES.ADD_STAGE](state, { pipelineId, stage }) {
    const stages = state.stages[pipelineId] || [];
    state.stages = {
      ...state.stages,
      [pipelineId]: [...stages, stage],
    };
  },
  [MUTATION_TYPES.EDIT_STAGE](state, { pipelineId, stage }) {
    const stages = state.stages[pipelineId] || [];
    const index = stages.findIndex(s => s.id === stage.id);
    if (index !== -1) {
      stages[index] = stage;
      state.stages = {
        ...state.stages,
        [pipelineId]: [...stages],
      };
    }
  },
  [MUTATION_TYPES.DELETE_STAGE](state, { pipelineId, stageId }) {
    const stages = state.stages[pipelineId] || [];
    state.stages = {
      ...state.stages,
      [pipelineId]: stages.filter(s => s.id !== stageId),
    };
  },
};

export const actions = {
  // Override get to handle array response
  async get({ commit }) {
    commit('SET_PIPELINE_UI_FLAG', { fetchingList: true });
    try {
      const response = await PipelinesAPI.get();
      // API returns array directly, not { payload, meta }
      const pipelines = response.data.payload || response.data;
      commit(
        'SET_PIPELINE',
        Array.isArray(pipelines) ? pipelines : [pipelines]
      );
      return pipelines;
    } catch (error) {
      throw error;
    } finally {
      commit('SET_PIPELINE_UI_FLAG', { fetchingList: false });
    }
  },

  async create({ commit }, data) {
    commit('SET_PIPELINE_UI_FLAG', { creatingItem: true });
    try {
      const response = await PipelinesAPI.create(data);
      const pipeline = response.data.payload || response.data;
      commit('UPSERT_PIPELINE', pipeline);
      return pipeline;
    } catch (error) {
      throw error;
    } finally {
      commit('SET_PIPELINE_UI_FLAG', { creatingItem: false });
    }
  },

  async setDefault({ commit }, pipelineId) {
    try {
      const response = await PipelinesAPI.setDefault(pipelineId);
      // Update all pipelines to reflect the new default
      commit(MUTATION_TYPES.SET, response.data.payload || response.data);
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  // Stage actions
  async fetchStages({ commit }, pipelineId) {
    commit(MUTATION_TYPES.SET_UI_FLAG, { fetchingList: true });
    try {
      const response = await PipelineStagesAPI.get(pipelineId);
      const stages = response.data.payload || response.data;
      commit(MUTATION_TYPES.SET_STAGES, { pipelineId, stages });
      return stages;
    } catch (error) {
      throw error;
    } finally {
      commit(MUTATION_TYPES.SET_UI_FLAG, { fetchingList: false });
    }
  },

  async createStage({ commit }, { pipelineId, stageData }) {
    commit(MUTATION_TYPES.SET_UI_FLAG, { creatingItem: true });
    try {
      const response = await PipelineStagesAPI.create(pipelineId, stageData);
      const stage = response.data.payload || response.data;
      commit(MUTATION_TYPES.ADD_STAGE, { pipelineId, stage });
      return stage;
    } catch (error) {
      throw error;
    } finally {
      commit(MUTATION_TYPES.SET_UI_FLAG, { creatingItem: false });
    }
  },

  async updateStage({ commit }, { pipelineId, stageId, stageData }) {
    commit(MUTATION_TYPES.SET_UI_FLAG, { updatingItem: true });
    try {
      const response = await PipelineStagesAPI.update(
        pipelineId,
        stageId,
        stageData
      );
      const stage = response.data.payload || response.data;
      commit(MUTATION_TYPES.EDIT_STAGE, { pipelineId, stage });
      return stage;
    } catch (error) {
      throw error;
    } finally {
      commit(MUTATION_TYPES.SET_UI_FLAG, { updatingItem: false });
    }
  },

  async deleteStage({ commit }, { pipelineId, stageId }) {
    commit(MUTATION_TYPES.SET_UI_FLAG, { deletingItem: true });
    try {
      await PipelineStagesAPI.delete(pipelineId, stageId);
      commit(MUTATION_TYPES.DELETE_STAGE, { pipelineId, stageId });
    } catch (error) {
      throw error;
    } finally {
      commit(MUTATION_TYPES.SET_UI_FLAG, { deletingItem: false });
    }
  },

  async reorderStages({ commit }, { pipelineId, stageIds }) {
    try {
      const response = await PipelineStagesAPI.reorder(pipelineId, stageIds);
      const stages = response.data.payload || response.data;
      commit(MUTATION_TYPES.SET_STAGES, { pipelineId, stages });
      return stages;
    } catch (error) {
      throw error;
    }
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
