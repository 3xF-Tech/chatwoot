/* global axios */
import ApiClient from './ApiClient';

class AiAgentSubscriptionsAPI extends ApiClient {
  constructor() {
    super('ai_agent_subscriptions', { accountScoped: true });
  }

  getPlans() {
    return axios.get(`${this.url}/plans`);
  }

  getUsage() {
    return axios.get(`${this.url}/usage`);
  }

  getSubscriptions() {
    return axios.get(this.url);
  }

  getSubscription(id) {
    return axios.get(`${this.url}/${id}`);
  }

  startTrial(planId) {
    return axios.post(this.url, {
      plan_id: planId,
      start_trial: true,
    });
  }

  checkout(planId) {
    return axios.post(`${this.url}/${planId}/checkout`);
  }

  createSubscription(planId) {
    return axios.post(this.url, {
      plan_id: planId,
    });
  }

  cancelSubscription(id) {
    return axios.post(`${this.url}/${id}/cancel`);
  }
}

export default new AiAgentSubscriptionsAPI();
