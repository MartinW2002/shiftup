class ActivityPolicy < ApplicationPolicy
  # Members (volunteers and organizers) can see the organization's activities and shifts.
  def show?
    user.present? && user.member_of?(organization)
  end

  # Only the organization's own organizers may publish or change its activities.
  def create?
    user.present? && user.organizer_of?(organization)
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  private

  def organization
    record.organization
  end
end
