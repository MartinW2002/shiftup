class MembershipsController < ApplicationController
  def create
    @organization = Organization.find(params[:organization_id])
    authorize @organization, :join?

    # create_or_find_by! relies on the unique index, so a double-submitted form cannot create two memberships.
    current_user.memberships.create_or_find_by!(organization: @organization)
    redirect_to @organization, notice: "You joined #{@organization.name} as a volunteer."
  end
end
