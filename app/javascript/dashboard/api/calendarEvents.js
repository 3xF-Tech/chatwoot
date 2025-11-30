import ApiClient from './ApiClient';

class CalendarEventsAPI extends ApiClient {
  constructor() {
    super('calendar_events', { accountScoped: true });
  }

  getByDateRange(startTime, endTime, filters = {}) {
    return this.axiosInstance.get(this.url, {
      params: {
        start_time: startTime,
        end_time: endTime,
        ...filters,
      },
    });
  }

  getUpcoming(limit = 10) {
    return this.axiosInstance.get(`${this.url}/upcoming`, {
      params: { limit },
    });
  }

  getByLink(linkableType, linkableId) {
    return this.axiosInstance.get(`${this.url}/by_link`, {
      params: {
        linkable_type: linkableType,
        linkable_id: linkableId,
      },
    });
  }
}

export default new CalendarEventsAPI();
