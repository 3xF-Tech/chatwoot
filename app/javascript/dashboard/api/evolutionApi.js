/* global axios */
import ApiClient from './ApiClient';

class EvolutionApi extends ApiClient {
  constructor() {
    super('evolution_instances', { accountScoped: true });
  }

  /**
   * Create a new Evolution API instance with QR code
   * @param {Object} data - Instance creation data
   * @param {string} data.instance_name - Unique name for the instance
   * @param {string} data.inbox_name - Name for the inbox
   * @param {boolean} data.reject_call - Reject incoming calls
   * @param {boolean} data.groups_ignore - Ignore group messages
   * @param {boolean} data.always_online - Always show online status
   * @param {boolean} data.read_messages - Mark messages as read
   * @param {boolean} data.sync_full_history - Sync full message history
   */
  createInstance(data) {
    return axios.post(this.url, data);
  }

  /**
   * Get QR code for an existing instance (reconnection)
   * @param {number} inboxId - ID of the inbox
   */
  getQrCode(inboxId) {
    return axios.get(`${this.url}/${inboxId}/qrcode`);
  }

  /**
   * Check connection status of an instance
   * @param {number} inboxId - ID of the inbox
   */
  getConnectionStatus(inboxId) {
    return axios.get(`${this.url}/${inboxId}/status`);
  }

  /**
   * Disconnect/logout an instance
   * @param {number} inboxId - ID of the inbox
   */
  disconnectInstance(inboxId) {
    return axios.delete(`${this.url}/${inboxId}/disconnect`);
  }

  /**
   * Delete an instance completely
   * @param {number} inboxId - ID of the inbox
   */
  deleteInstance(inboxId) {
    return axios.delete(`${this.url}/${inboxId}`);
  }
}

export default new EvolutionApi();
