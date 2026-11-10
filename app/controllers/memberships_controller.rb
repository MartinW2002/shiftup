class MembershipsController < ApplicationController
  def create
    @organization = Organization.find(params[:organization_id])
    authorize @organization, :join?

    # create_or_find_by! relies on the unique index, so a double-submitted form cannot create two memberships.
    current_user.memberships.create_or_find_by!(organization: @organization)
    redirect_to @organization, notice: "You joined #{@organization.name} as a volunteer."
  end

  # Leaving an organization cancels the volunteer's upcoming shifts and waiting list places there.
  # Past sign-ups and attendance records are kept.
  def destroy
    @organization = Organization.find(params[:organization_id])
    authorize @organization, :leave?
    membership = current_user.membership_in(@organization)
    if membership.nil?
      return redirect_to organizations_path, alert: "You are not a member of this organization.", status: :see_other
    end

    result = MembershipCancellation.new(membership).call
    if result.success?
      redirect_to organizations_path, notice: result.message, status: :see_other
    else
      redirect_to @organization, alert: result.message, status: :see_other
    end
  end
end
