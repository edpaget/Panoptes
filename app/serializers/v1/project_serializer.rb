class V1::ProjectSerializer < ActiveModel::Serializer
  attributes :id, :display_name, :classifications_count,
    :subjects_count, :retired_subjects_count,
    :created_at, :updated_at,
    :title, :description, :introduction, :private,
    :configuration, :live, :urls, :migrated, :classifiers_count, :slug, :redirect,
    :beta_requested, :beta_approved, :launch_requested, :launch_approved,
    :href, :workflow_description, :primary_language, :tags

  has_many :workflows
  has_many :subject_sets
  has_many :project_contents
  has_many :project_roles
  has_many :pages
  has_many :attached_images

  belongs_to :owner

  has_one :avatar
  has_one :background
  has_one :classification_export
  has_one :subjects_export
  has_one :aggregations_export

  def title
    content[:title]
  end

  def description
    content[:description]
  end

  def workflow_description
    content[:workflow_description]
  end

  def introduction
    content[:introduction]
  end

  def urls
    if content
      urls = @model.urls.dup
      TasksVisitors::InjectStrings.new(content[:url_labels]).visit(urls)
      urls
    else
      []
    end
  end

  def content
    @content ||= _content
  end

  def tags
    @model.tags.map(&:name)
  end

  def fields
    %i(title description workflow_description introduction url_labels)
  end

  def _content
    content = @model.content_for(@context[:languages])
    content = fields.map{ |k| Hash[k, content.send(k)] }.reduce(&:merge)
    content.default_proc = proc { |hash, key| "" }
    content
  end
end
