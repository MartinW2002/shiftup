class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized, :verify_policy_scoped

  def index
    @memberships = current_user&.memberships&.includes(:organization)&.order("organizations.name")
  end
end
