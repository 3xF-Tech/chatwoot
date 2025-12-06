class Api::V1::Accounts::AgentBotsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :check_authorization
  before_action :agent_bot, except: [:index, :create]

  def index
    @agent_bots = AgentBot.accessible_to(Current.account)
  end

  def show; end

  def create
    @agent_bot = Current.account.agent_bots.create!(permitted_params.except(:avatar_url, :inbox_ids))
    process_avatar_from_url
    update_inbox_associations
  end

  def update
    @agent_bot.update!(permitted_params.except(:avatar_url, :inbox_ids))
    process_avatar_from_url
    update_inbox_associations
  end

  def avatar
    @agent_bot.avatar.purge if @agent_bot.avatar.attached?
    @agent_bot
  end

  def destroy
    @agent_bot.destroy!
    head :ok
  end

  def reset_access_token
    @agent_bot.access_token.regenerate_token
    @agent_bot.reload
  end

  # Associate multiple inboxes with this agent bot
  def update_inboxes
    update_inbox_associations
    head :ok
  end

  private

  def agent_bot
    @agent_bot = AgentBot.accessible_to(Current.account).find(params[:id]) if params[:action] == 'show'
    @agent_bot ||= Current.account.agent_bots.find(params[:id])
  end

  def permitted_params
    params.permit(
      :name,
      :description,
      :outgoing_url,
      :avatar,
      :avatar_url,
      :bot_type,
      :context_prompt,
      :enable_signature,
      :ai_agent_type,
      :response_mode,
      :is_active,
      bot_config: {},
      inbox_ids: []
    )
  end

  def process_avatar_from_url
    ::Avatar::AvatarFromUrlJob.perform_later(@agent_bot, params[:avatar_url]) if params[:avatar_url].present?
  end

  def update_inbox_associations
    return unless params.key?(:inbox_ids)

    inbox_ids = Array(params[:inbox_ids]).reject(&:blank?).map(&:to_i)
    current_inbox_ids = @agent_bot.agent_bot_inboxes.pluck(:inbox_id)

    # Remove associations for inboxes not in the new list
    inboxes_to_remove = current_inbox_ids - inbox_ids
    @agent_bot.agent_bot_inboxes.where(inbox_id: inboxes_to_remove).destroy_all if inboxes_to_remove.any?

    # Add associations for new inboxes
    inboxes_to_add = inbox_ids - current_inbox_ids
    inboxes_to_add.each do |inbox_id|
      inbox = Current.account.inboxes.find_by(id: inbox_id)
      next unless inbox

      # Remove any existing agent_bot_inbox for this inbox (one bot per inbox)
      inbox.agent_bot_inbox&.destroy

      AgentBotInbox.create!(
        agent_bot: @agent_bot,
        inbox: inbox,
        account: Current.account,
        status: :active
      )
    end
  end
end
