class ShiftPolicy < ActivityPolicy
  # Shifts of the organizations the user belongs to.
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      scope.joins(:activity).where(activities: { organization_id: user.memberships.select(:organization_id) })
    end
  end

  private

  def organization
    record.activity.organization
  end
end
