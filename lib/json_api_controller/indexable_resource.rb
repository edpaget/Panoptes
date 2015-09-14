module JsonApiController
  module IndexableResource
    def index
      if serializer < ActiveModel::Serializer
        render json: @controlled_resources, each_serializer: serializer#, context: context
      else
        render json_api: serializer.page(params, controlled_resources, context),
          generate_response_obj_etag: true
      end
    end
  end
end
