class OrganizationsController < ApplicationController
  def index
    organizations = policy_scope(Organization).order(:name)
    member_ids = current_user.memberships.pluck(:organization_id)
    @my_organizations, @other_organizations = organizations.partition { |organization| member_ids.include?(organization.id) }
  end

  def show
    @organization = Organization.find(params[:id])
    authorize @organization
    @activities = @organization.activities.order(:title)
  end
end
