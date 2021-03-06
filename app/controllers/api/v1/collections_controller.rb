class Api::V1::CollectionsController < Api::ApiController
  include FilterByOwner
  include FilterByCurrentUserRoles
  include IndexSearch

  doorkeeper_for :create, :update, :destroy, scopes: [:collection]
  resource_actions :default
  schema_type :strong_params

  allowed_params :create, :name, :display_name, :private, :favorite,
    links: [ :project, subjects: [], owner: polymorphic ]

  allowed_params :update, :name, :display_name, :private, links: [ subjects: [] ]

  search_by do |name, query|
    query.search_display_name(name.join(" "))
  end

  protected

  def build_resource_for_create(create_params)
    add_user_as_linked_owner(create_params)
    super(create_params)
  end
end

