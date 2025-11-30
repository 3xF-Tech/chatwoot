import { FEATURE_FLAGS } from '../../../featureFlags';
import { frontendURL } from '../../../helper/URLHelper';

const CalendarIndex = () => import('./CalendarIndex.vue');
const CalendarView = () => import('./CalendarView.vue');
const CalendarSettings = () => import('./CalendarSettings.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/calendar'),
      name: 'calendar_wrapper',
      component: CalendarIndex,
      meta: {
        featureFlag: FEATURE_FLAGS.CALENDAR,
        permissions: ['administrator', 'agent'],
      },
      children: [
        {
          path: '',
          name: 'calendar_home',
          component: CalendarView,
          meta: {
            featureFlag: FEATURE_FLAGS.CALENDAR,
            permissions: ['administrator', 'agent'],
          },
        },
        {
          path: 'settings',
          name: 'calendar_settings',
          component: CalendarSettings,
          meta: {
            featureFlag: FEATURE_FLAGS.CALENDAR,
            permissions: ['administrator', 'agent'],
          },
        },
      ],
    },
  ],
};
