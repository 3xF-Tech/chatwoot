# frozen_string_literal: true

# == Schema Information
#
# Table name: opportunity_conversations
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  conversation_id :bigint           not null
#  opportunity_id  :bigint           not null
#
# Indexes
#
#  index_opp_conversations_unique                      (opportunity_id,conversation_id) UNIQUE
#  index_opportunity_conversations_on_conversation_id  (conversation_id)
#  index_opportunity_conversations_on_opportunity_id   (opportunity_id)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (opportunity_id => opportunities.id)
#
class OpportunityConversation < ApplicationRecord
  belongs_to :opportunity
  belongs_to :conversation

  validates :opportunity_id, uniqueness: { scope: :conversation_id }

  delegate :account, to: :opportunity
end
