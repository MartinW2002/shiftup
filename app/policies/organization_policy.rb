class OrganizationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  # Members (volunteers and organizers) can see their organization's activities.
  def show?
    user.present? && user.member_of?(record)
  end

  # Only the organization's own organizers may change it.
  def update?
    user.present? && user.organizer_of?(record)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      scope.joins(:memberships).where(memberships: { user_id: user.id })
    end
  end
end
