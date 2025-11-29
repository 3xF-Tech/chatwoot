import { frontendURL } from '../../../helper/URLHelper';
import { FEATURE_FLAGS } from '../../../featureFlags';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';

const OpportunitiesIndex = () => import('./pages/OpportunitiesIndex.vue');
const OpportunityDetails = () => import('./pages/OpportunityDetails.vue');

const commonMeta = {
  featureFlag: FEATURE_FLAGS.OPPORTUNITIES,
  permissions: ['administrator', 'agent'],
  installationTypes: [
    INSTALLATION_TYPES.CLOUD,
    INSTALLATION_TYPES.ENTERPRISE,
    INSTALLATION_TYPES.COMMUNITY,
  ],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/opportunities'),
    name: 'opportunities_index',
    component: OpportunitiesIndex,
    meta: commonMeta,
  },
  {
    path: frontendURL('accounts/:accountId/opportunities/:opportunityId'),
    name: 'opportunity_details',
    component: OpportunityDetails,
    meta: commonMeta,
  },
];
