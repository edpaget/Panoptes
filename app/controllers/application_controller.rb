class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_filter :configure_permitted_parameters, if: :devise_controller?

  def unknown_route
    exception = ActionController::RoutingError.new("Not Found")
    response_body = JSONApiRender::JSONApiResponse.format_response_body(exception)
    respond_to do |format|
      format.html { raise exception }
      format.json { render status: :not_found, json: response_body }
      format.json_api { render status: :not_found, json_api: response_body }
    end
  end

  protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.for(:sign_up) do |u|
        u.permit(:email, :password, :password_confirmation, :login, :name)
      end
    end
end
