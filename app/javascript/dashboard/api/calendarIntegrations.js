import ApiClient from './ApiClient';

class CalendarIntegrationsAPI extends ApiClient {
  constructor() {
    super('calendar_integrations', { accountScoped: true });
  }

  getAuthUrl(provider) {
    return this.axiosInstance.get(`${this.url}/auth_url?provider=${provider}`);
  }

  handleCallback(provider, code) {
    return this.axiosInstance.post(`${this.url}/callback`, {
      provider,
      code,
    });
  }

  sync(integrationId) {
    return this.axiosInstance.post(`${this.url}/${integrationId}/sync`);
  }

  getCalendars(integrationId) {
    return this.axiosInstance.get(`${this.url}/${integrationId}/calendars`);
  }
}

export default new CalendarIntegrationsAPI();
