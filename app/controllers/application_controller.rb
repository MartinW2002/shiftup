class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Every action must call `authorize` (or `policy_scope` for index actions),
  # so a forgotten permission check fails loudly in tests.
  after_action :verify_authorized, unless: -> { skip_authorization_check? || action_name == "index" }
  after_action :verify_policy_scoped, if: -> { !skip_authorization_check? && action_name == "index" }

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def skip_authorization_check?
    devise_controller?
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  # Messages live in config/locales/pundit.en.yml, keyed by policy and rule,
  # e.g. pundit.organization_policy.join?, with pundit.default as the fallback.
  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    message = t("#{policy_name}.#{exception.query}", scope: "pundit", default: :default)

    respond_to do |format|
      format.html do
        flash[:alert] = message
        redirect_back_or_to root_path, status: :see_other
      end
      format.any { head :forbidden }
    end
  end
end
