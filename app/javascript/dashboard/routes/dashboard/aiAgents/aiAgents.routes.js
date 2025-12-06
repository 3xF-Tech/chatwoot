import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { frontendURL } from '../../../helper/URLHelper';

import AIAgentsLayout from './pages/AIAgentsLayout.vue';
import DashboardPage from './pages/Dashboard.vue';
import MyAgentsPage from './pages/MyAgents.vue';
import MarketplacePage from './pages/Marketplace.vue';

const meta = {
  permissions: ['administrator'],
  featureFlag: FEATURE_FLAGS.AGENT_BOTS,
};

const aiAgentRoutes = [
  {
    path: '',
    redirect: to => ({
      name: 'ai_agents_dashboard',
      params: { ...to.params },
    }),
  },
  {
    path: frontendURL('accounts/:accountId/ai-agents/dashboard'),
    component: DashboardPage,
    name: 'ai_agents_dashboard',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/ai-agents/my-agents'),
    component: MyAgentsPage,
    name: 'ai_agents_my_agents',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/ai-agents/marketplace'),
    component: MarketplacePage,
    name: 'ai_agents_marketplace',
    meta,
  },
];

export const routes = [
  {
    path: frontendURL('accounts/:accountId/ai-agents'),
    component: AIAgentsLayout,
    children: aiAgentRoutes,
  },
];
