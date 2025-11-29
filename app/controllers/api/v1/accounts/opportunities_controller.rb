# frozen_string_literal: true

class Api::V1::Accounts::OpportunitiesController < Api::V1::Accounts::BaseController
  include Sift

  RESULTS_PER_PAGE = 25

  sort_on :value, type: :decimal
  sort_on :name, type: :string
  sort_on :expected_close_date, type: :date
  sort_on :created_at, type: :datetime
  sort_on :last_activity_at, type: :datetime

  before_action :check_authorization
  before_action :set_current_page, only: [:index, :search]
  before_action :fetch_opportunity, only: [:show, :update, :destroy, :move_stage, :mark_won, :mark_lost]

  def index
    @opportunities = fetch_opportunities(filtered_opportunities)
    @opportunities_count = @opportunities.total_count
  end

  def search
    return render json: { error: 'Query is required' }, status: :unprocessable_entity if params[:q].blank?

    opportunities = Current.account.opportunities.where(
      'name ILIKE :search OR description ILIKE :search',
      search: "%#{params[:q]}%"
    )
    @opportunities = fetch_opportunities(opportunities)
    @opportunities_count = @opportunities.total_count
  end

  def show; end

  def stats
    @stats = {
      total_count: Current.account.opportunities.count,
      open_count: Current.account.opportunities.open.count,
      won_count: Current.account.opportunities.won.count,
      lost_count: Current.account.opportunities.lost.count,
      total_value: Current.account.opportunities.open.sum(:value),
      weighted_value: Current.account.opportunities.open.sum('value * probability / 100'),
      won_value: Current.account.opportunities.won.sum(:value)
    }
    render json: @stats
  end

  def create
    @opportunity = Current.account.opportunities.new(opportunity_params)
    @opportunity.owner = Current.user if @opportunity.owner_id.blank?
    @opportunity.save!
    render :show, status: :created
  end

  def update
    @opportunity.update!(opportunity_params)
    render :show
  end

  def destroy
    @opportunity.destroy!
    head :ok
  end

  def move_stage
    authorize(@opportunity, :move_stage?)
    stage = Current.account.pipeline_stages.find(params[:stage_id])
    @opportunity.move_to_stage!(stage, user: Current.user, notes: params[:notes])
    render :show
  end

  def mark_won
    authorize(@opportunity, :mark_won?)
    @opportunity.mark_won!(user: Current.user, notes: params[:notes])
    render :show
  end

  def mark_lost
    authorize(@opportunity, :mark_lost?)
    @opportunity.mark_lost!(reason: params[:reason], user: Current.user, notes: params[:notes])
    render :show
  end

  private

  def filtered_opportunities
    opportunities = Current.account.opportunities.includes(:pipeline, :pipeline_stage, :contact, :company, :owner)
    opportunities = opportunities.by_pipeline(params[:pipeline_id]) if params[:pipeline_id].present?
    opportunities = opportunities.by_stage(params[:stage_id]) if params[:stage_id].present?
    opportunities = opportunities.by_owner(params[:owner_id]) if params[:owner_id].present?
    opportunities = opportunities.by_company(params[:company_id]) if params[:company_id].present?
    opportunities = opportunities.by_contact(params[:contact_id]) if params[:contact_id].present?
    opportunities = opportunities.by_status(params[:status]) if params[:status].present?
    opportunities = opportunities.where('value >= ?', params[:value_min]) if params[:value_min].present?
    opportunities = opportunities.where('value <= ?', params[:value_max]) if params[:value_max].present?
    if params[:expected_close_from].present?
      opportunities = opportunities.where('expected_close_date >= ?', params[:expected_close_from])
    end
    opportunities = opportunities.where('expected_close_date <= ?', params[:expected_close_to]) if params[:expected_close_to].present?
    opportunities
  end

  def set_current_page
    @current_page = params[:page] || 1
  end

  def fetch_opportunities(opportunities)
    filtrate(opportunities)
      .page(@current_page)
      .per(params[:per_page] || RESULTS_PER_PAGE)
  end

  def fetch_opportunity
    @opportunity = Current.account.opportunities.find(params[:id])
  end

  def check_authorization
    authorize(Opportunity)
  end

  def opportunity_params
    params.require(:opportunity).permit(
      :name, :description, :value, :currency, :probability,
      :expected_close_date, :pipeline_id, :pipeline_stage_id,
      :contact_id, :company_id, :owner_id, :team_id, :source,
      :status, :lost_reason, custom_attributes: {}
    )
  end
end
