# frozen_string_literal: true

class Api::V1::Accounts::Opportunities::ActivitiesController < Api::V1::Accounts::BaseController
  before_action :fetch_opportunity
  before_action :check_authorization
  before_action :fetch_activity, only: [:show, :update, :destroy, :complete]

  def index
    @activities = @opportunity.activities.ordered
    @activities = @activities.pending if params[:pending] == 'true'
    @activities = @activities.completed if params[:completed] == 'true'
  end

  def show; end

  def create
    @activity = @opportunity.activities.new(activity_params)
    @activity.user = Current.user if @activity.user_id.blank?
    @activity.save!
    render :show, status: :created
  end

  def update
    @activity.update!(activity_params)
    render :show
  end

  def destroy
    @activity.destroy!
    head :ok
  end

  def complete
    authorize(@activity, :complete?)
    @activity.complete!
    render :show
  end

  private

  def fetch_opportunity
    @opportunity = Current.account.opportunities.find(params[:opportunity_id])
  end

  def fetch_activity
    @activity = @opportunity.activities.find(params[:id])
  end

  def activity_params
    params.require(:activity).permit(
      :activity_type, :title, :description, :scheduled_at,
      :reminder_at, :duration_minutes, :user_id, :is_done,
      metadata: {}
    )
  end

  def check_authorization
    authorize(OpportunityActivity)
  end
end
