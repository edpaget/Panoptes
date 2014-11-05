class Api::V1::ClassificationsController < Api::ApiController
  include JsonApiController

  skip_before_filter :require_login, only: :create
  doorkeeper_for :show, :index, :destory, :update, scopes: [:classification]
  resource_actions :default

  allowed_params :create, :completed,
    annotations: [:key, :value, :started_at, :finished_at, :user_agent],
    links: [:project, :workflow, :set_member_subject, :subject]

  allowed_params :update, :completed,
    annotations: [:key, :value, :started_at, :finished_at, :user_agent]

  alias_method :classification, :controlled_resource

  private

  def build_resource_for_update(update_params)
    super
    lifecycle(:update)
    classification
  end

  def visible_scope
    Classification.visible_to(api_user)
  end

  def build_resource_for_create(create_params)
    create_params[:links][:user] = api_user.user
    create_params[:user_ip] = request_ip
    classification = super(create_params)
    classification.workflow_version = classification.workflow.versions.last
    lifecycle(:create, classification)
    classification
  end

  def cellect_host
    super(classification.workflow.id)
  end

  def lifecycle(action, classification=classification)
    lifecycle = ClassificationLifecycle.new(classification)
    lifecycle.update_cellect(cellect_host)
    lifecycle.queue(action)
  end
end
