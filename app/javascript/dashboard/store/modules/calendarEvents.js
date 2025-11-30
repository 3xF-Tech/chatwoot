import CalendarEventsAPI from '../../api/calendarEvents';

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
  currentDateRange: {
    startTime: null,
    endTime: null,
  },
};

export const getters = {
  getEvents: $state => $state.records,
  getUIFlags: $state => $state.uiFlags,
  getEventById: $state => id => {
    return $state.records.find(record => record.id === id);
  },
  getEventsByDate: $state => date => {
    const dateStr = new Date(date).toDateString();
    return $state.records.filter(event => {
      const eventDate = new Date(event.start_time).toDateString();
      return eventDate === dateStr;
    });
  },
  getEventsByType: $state => type => {
    return $state.records.filter(event => event.event_type === type);
  },
  getCurrentDateRange: $state => $state.currentDateRange,
};

export const actions = {
  get: async ({ commit }, { startTime, endTime, filters = {} }) => {
    commit('setUIFlag', { isFetching: true });
    commit('setDateRange', { startTime, endTime });
    try {
      const response = await CalendarEventsAPI.getByDateRange(
        startTime,
        endTime,
        filters
      );
      commit('setEvents', response.data);
    } catch (error) {
      throw error;
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },

  getUpcoming: async ({ commit }, limit = 10) => {
    commit('setUIFlag', { isFetching: true });
    try {
      const response = await CalendarEventsAPI.getUpcoming(limit);
      return response.data;
    } catch (error) {
      throw error;
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },

  getByLink: async (_, { linkableType, linkableId }) => {
    const response = await CalendarEventsAPI.getByLink(
      linkableType,
      linkableId
    );
    return response.data;
  },

  create: async ({ commit }, eventData) => {
    commit('setUIFlag', { isCreating: true });
    try {
      const response = await CalendarEventsAPI.create({
        calendar_event: eventData,
      });
      commit('addEvent', response.data);
      return response.data;
    } catch (error) {
      throw error;
    } finally {
      commit('setUIFlag', { isCreating: false });
    }
  },

  update: async ({ commit }, { id, ...eventData }) => {
    commit('setUIFlag', { isUpdating: true });
    try {
      const response = await CalendarEventsAPI.update(id, {
        calendar_event: eventData,
      });
      commit('updateEvent', response.data);
      return response.data;
    } catch (error) {
      throw error;
    } finally {
      commit('setUIFlag', { isUpdating: false });
    }
  },

  delete: async ({ commit }, id) => {
    commit('setUIFlag', { isDeleting: true });
    try {
      await CalendarEventsAPI.delete(id);
      commit('deleteEvent', id);
    } catch (error) {
      throw error;
    } finally {
      commit('setUIFlag', { isDeleting: false });
    }
  },
};

export const mutations = {
  setUIFlag($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },

  setDateRange($state, { startTime, endTime }) {
    $state.currentDateRange = { startTime, endTime };
  },

  setEvents($state, data) {
    $state.records = data;
  },

  addEvent($state, data) {
    // Add and sort by start_time
    $state.records.push(data);
    $state.records.sort(
      (a, b) => new Date(a.start_time) - new Date(b.start_time)
    );
  },

  updateEvent($state, data) {
    const index = $state.records.findIndex(record => record.id === data.id);
    if (index !== -1) {
      $state.records[index] = data;
    }
  },

  deleteEvent($state, id) {
    $state.records = $state.records.filter(record => record.id !== id);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
