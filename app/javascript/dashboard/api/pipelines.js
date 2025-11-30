/* global axios */
import ApiClient from './ApiClient';

class PipelinesAPI extends ApiClient {
  constructor() {
    super('pipelines', { accountScoped: true });
  }

  setDefault(pipelineId) {
    return axios.post(`${this.url}/${pipelineId}/set_default`);
  }
}

export default new PipelinesAPI();
