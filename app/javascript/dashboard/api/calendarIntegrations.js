/* global axios */
import ApiClient from './ApiClient';

class CalendarIntegrationsAPI extends ApiClient {
  constructor() {
    super('calendar_integrations', { accountScoped: true });
  }

  getAuthUrl(provider) {
    return axios.get(`${this.url}/auth_url?provider=${provider}`);
  }

  handleCallback(provider, code) {
    return axios.post(`${this.url}/callback`, {
      provider,
      code,
    });
  }

  sync(integrationId) {
    return axios.post(`${this.url}/${integrationId}/sync`);
  }

  getCalendars(integrationId) {
    return axios.get(`${this.url}/${integrationId}/calendars`);
  }
}

export default new CalendarIntegrationsAPI();
