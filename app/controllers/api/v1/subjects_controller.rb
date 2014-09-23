class Api::V1::SubjectsController < Api::ApiController
  before_action :merge_cellect_host, only: :index
  doorkeeper_for :update, :create, :update, scopes: [:subject]

  def show
    render json_api: SubjectSerializer.page(params)
  end

  def index
    render json_api: selector.create_response
  end

  def update

  end

  def create

  end

  def destroy

  end

  private

  def merge_cellect_host
    params[:host] = cellect_host(params[:workflow_id])
  end

  def selector
    @selector ||= SubjectSelector.new(api_user, params)
  end
end
