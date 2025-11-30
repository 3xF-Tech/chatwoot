/* global axios */
import ApiClient from './ApiClient';

class PipelineStagesAPI extends ApiClient {
  constructor() {
    super('pipelines', { accountScoped: true });
  }

  getUrl(pipelineId) {
    return `${this.url}/${pipelineId}/stages`;
  }

  get(pipelineId) {
    return axios.get(this.getUrl(pipelineId));
  }

  show(pipelineId, stageId) {
    return axios.get(`${this.getUrl(pipelineId)}/${stageId}`);
  }

  create(pipelineId, stageData) {
    return axios.post(this.getUrl(pipelineId), stageData);
  }

  update(pipelineId, stageId, stageData) {
    return axios.patch(`${this.getUrl(pipelineId)}/${stageId}`, stageData);
  }

  delete(pipelineId, stageId) {
    return axios.delete(`${this.getUrl(pipelineId)}/${stageId}`);
  }

  reorder(pipelineId, stageIds) {
    return axios.post(`${this.getUrl(pipelineId)}/reorder`, {
      stage_ids: stageIds,
    });
  }
}

export default new PipelineStagesAPI();
