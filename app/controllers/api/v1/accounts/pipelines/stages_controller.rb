# frozen_string_literal: true

class Api::V1::Accounts::Pipelines::StagesController < Api::V1::Accounts::BaseController
  before_action :fetch_pipeline
  before_action :check_authorization
  before_action :fetch_stage, only: [:show, :update, :destroy]

  def index
    @stages = @pipeline.stages.ordered
  end

  def show; end

  def create
    @stage = @pipeline.stages.new(stage_params)
    @stage.save!
    render :show, status: :created
  end

  def update
    @stage.update!(stage_params)
    render :show
  end

  def destroy
    @stage.destroy!
    head :ok
  end

  def reorder
    authorize(PipelineStage, :reorder?)
    params[:stages].each_with_index do |stage_id, index|
      @pipeline.stages.find(stage_id).update!(position: index)
    end
    @stages = @pipeline.stages.ordered
    render :index
  end

  private

  def fetch_pipeline
    @pipeline = Current.account.pipelines.find(params[:pipeline_id])
  end

  def fetch_stage
    @stage = @pipeline.stages.find(params[:id])
  end

  def stage_params
    params.require(:stage).permit(:name, :position, :probability, :stage_type, :rotting_days, :color)
  end

  def check_authorization
    authorize(PipelineStage)
  end
end
