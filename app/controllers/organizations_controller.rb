class OrganizationsController < ApplicationController
  def index
    @organizations = policy_scope(Organization).order(:name)
  end

  def show
    @organization = Organization.find(params[:id])
    authorize @organization
    @activities = @organization.activities.order(:title)
  end
end
