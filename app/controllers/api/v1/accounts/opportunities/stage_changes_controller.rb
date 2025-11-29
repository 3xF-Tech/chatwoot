# frozen_string_literal: true

class Api::V1::Accounts::Opportunities::StageChangesController < Api::V1::Accounts::BaseController
  before_action :fetch_opportunity

  def index
    @stage_changes = @opportunity.stage_changes.includes(:user, :from_stage, :to_stage).ordered
  end

  private

  def fetch_opportunity
    @opportunity = Current.account.opportunities.find(params[:opportunity_id])
  end
end
