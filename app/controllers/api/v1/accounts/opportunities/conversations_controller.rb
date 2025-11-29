# frozen_string_literal: true

class Api::V1::Accounts::Opportunities::ConversationsController < Api::V1::Accounts::BaseController
  before_action :fetch_opportunity
  before_action :check_authorization

  def index
    @conversations = @opportunity.conversations.includes(:contact, :inbox, :assignee)
  end

  def create
    conversation = Current.account.conversations.find(params[:conversation_id])
    @opportunity_conversation = @opportunity.opportunity_conversations.find_or_create_by!(conversation: conversation)
    render json: { message: 'Conversation linked successfully' }, status: :created
  end

  def destroy
    conversation = Current.account.conversations.find(params[:id])
    @opportunity_conversation = @opportunity.opportunity_conversations.find_by!(conversation: conversation)
    @opportunity_conversation.destroy!
    head :ok
  end

  private

  def fetch_opportunity
    @opportunity = Current.account.opportunities.find(params[:opportunity_id])
  end

  def check_authorization
    authorize(@opportunity, :link_conversation?)
  end
end
