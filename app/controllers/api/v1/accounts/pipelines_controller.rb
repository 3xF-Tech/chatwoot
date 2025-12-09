# frozen_string_literal: true

class Api::V1::Accounts::PipelinesController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_pipeline, only: [:show, :update, :destroy, :set_default]

  def index
    @pipelines = Current.account.pipelines.includes(:stages).ordered
  end

  def show; end

  def create
    @pipeline = Current.account.pipelines.new(pipeline_params)
    @pipeline.save!
    render :show, status: :created
  rescue ActiveRecord::RecordNotUnique => e
    # Handle race condition when setting is_default
    raise unless e.message.include?('index_pipelines_on_account_default')

    @pipeline.is_default = false
    @pipeline.save!
    render :show, status: :created
  end

  def update
    @pipeline.update!(pipeline_params)
    render :show
  end

  def destroy
    @pipeline.destroy!
    head :ok
  end

  def set_default
    @pipeline.update!(is_default: true)
    render :show
  end

  private

  def fetch_pipeline
    @pipeline = Current.account.pipelines.find(params[:id])
  end

  def pipeline_params
    params.require(:pipeline).permit(:name, :description, :is_default, settings: {})
  end

  def check_authorization
    authorize(Pipeline)
  end
end
