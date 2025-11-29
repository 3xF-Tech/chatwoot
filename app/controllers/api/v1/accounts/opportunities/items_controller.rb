# frozen_string_literal: true

class Api::V1::Accounts::Opportunities::ItemsController < Api::V1::Accounts::BaseController
  before_action :fetch_opportunity
  before_action :check_authorization
  before_action :fetch_item, only: [:show, :update, :destroy]

  def index
    @items = @opportunity.items.ordered
  end

  def show; end

  def create
    @item = @opportunity.items.new(item_params)
    @item.save!
    render :show, status: :created
  end

  def update
    @item.update!(item_params)
    render :show
  end

  def destroy
    @item.destroy!
    head :ok
  end

  def reorder
    authorize(@item || @opportunity.items.first, :reorder?) if @opportunity.items.any?
    params[:items].each_with_index do |item_id, index|
      @opportunity.items.find(item_id).update!(position: index)
    end
    @items = @opportunity.items.ordered
    render :index
  end

  private

  def fetch_opportunity
    @opportunity = Current.account.opportunities.find(params[:opportunity_id])
  end

  def fetch_item
    @item = @opportunity.items.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:name, :description, :quantity, :unit_price, :discount_percent, :position)
  end

  def check_authorization
    authorize(OpportunityItem)
  end
end
