/* global axios */
import ApiClient from './ApiClient';

export const buildOpportunityParams = params => {
  const {
    page = 1,
    sort = '-created_at',
    status,
    pipelineId,
    stageId,
    assigneeId,
    contactId,
    companyId,
  } = params;

  const queryParams = new URLSearchParams();
  queryParams.append('page', page);
  queryParams.append('sort', sort);

  if (status) queryParams.append('status', status);
  if (pipelineId) queryParams.append('pipeline_id', pipelineId);
  if (stageId) queryParams.append('stage_id', stageId);
  if (assigneeId) queryParams.append('assignee_id', assigneeId);
  if (contactId) queryParams.append('contact_id', contactId);
  if (companyId) queryParams.append('company_id', companyId);

  return queryParams.toString();
};

class OpportunitiesAPI extends ApiClient {
  constructor() {
    super('opportunities', { accountScoped: true });
  }

  get(params = {}) {
    const queryString = buildOpportunityParams(params);
    return axios.get(`${this.url}?${queryString}`);
  }

  // Override to wrap data in { opportunity: data }
  create(data) {
    return axios.post(this.url, { opportunity: data });
  }

  // Override to wrap data in { opportunity: data }
  update(id, data) {
    return axios.patch(`${this.url}/${id}`, { opportunity: data });
  }

  search(query, params = {}) {
    const { page = 1, sort = '-created_at' } = params;
    return axios.get(`${this.url}/search`, {
      params: { q: query, page, sort },
    });
  }

  stats(params = {}) {
    const { pipelineId, assigneeId, startDate, endDate } = params;
    const queryParams = new URLSearchParams();

    if (pipelineId) queryParams.append('pipeline_id', pipelineId);
    if (assigneeId) queryParams.append('assignee_id', assigneeId);
    if (startDate) queryParams.append('start_date', startDate);
    if (endDate) queryParams.append('end_date', endDate);

    return axios.get(`${this.url}/stats?${queryParams.toString()}`);
  }

  moveStage(opportunityId, stageId) {
    return axios.post(`${this.url}/${opportunityId}/move_stage`, {
      stage_id: stageId,
    });
  }

  markWon(opportunityId) {
    return axios.post(`${this.url}/${opportunityId}/mark_won`);
  }

  markLost(opportunityId, lostReason = '') {
    return axios.post(`${this.url}/${opportunityId}/mark_lost`, {
      lost_reason: lostReason,
    });
  }

  // Items
  getItems(opportunityId) {
    return axios.get(`${this.url}/${opportunityId}/items`);
  }

  createItem(opportunityId, itemData) {
    return axios.post(`${this.url}/${opportunityId}/items`, itemData);
  }

  updateItem(opportunityId, itemId, itemData) {
    return axios.patch(`${this.url}/${opportunityId}/items/${itemId}`, itemData);
  }

  deleteItem(opportunityId, itemId) {
    return axios.delete(`${this.url}/${opportunityId}/items/${itemId}`);
  }

  reorderItems(opportunityId, itemIds) {
    return axios.post(`${this.url}/${opportunityId}/items/reorder`, {
      item_ids: itemIds,
    });
  }

  // Activities
  getActivities(opportunityId) {
    return axios.get(`${this.url}/${opportunityId}/activities`);
  }

  createActivity(opportunityId, activityData) {
    return axios.post(`${this.url}/${opportunityId}/activities`, activityData);
  }

  updateActivity(opportunityId, activityId, activityData) {
    return axios.patch(
      `${this.url}/${opportunityId}/activities/${activityId}`,
      activityData
    );
  }

  deleteActivity(opportunityId, activityId) {
    return axios.delete(
      `${this.url}/${opportunityId}/activities/${activityId}`
    );
  }

  completeActivity(opportunityId, activityId) {
    return axios.post(
      `${this.url}/${opportunityId}/activities/${activityId}/complete`
    );
  }

  // Conversations
  getConversations(opportunityId) {
    return axios.get(`${this.url}/${opportunityId}/conversations`);
  }

  linkConversation(opportunityId, conversationId) {
    return axios.post(`${this.url}/${opportunityId}/conversations`, {
      conversation_id: conversationId,
    });
  }

  unlinkConversation(opportunityId, conversationId) {
    return axios.delete(
      `${this.url}/${opportunityId}/conversations/${conversationId}`
    );
  }

  // Stage Changes (History)
  getStageChanges(opportunityId) {
    return axios.get(`${this.url}/${opportunityId}/stage_changes`);
  }
}

export default new OpportunitiesAPI();
