class OrganizationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  # Members (volunteers and organizers) can see their organization's activities.
  def show?
    user.present? && user.member_of?(record)
  end

  # Any signed-in user can join an organization they do not belong to yet.
  # Joining always grants the volunteer role; organizer roles are never self-assigned.
  def join?
    user.present? && !user.member_of?(record)
  end

  # Only the organization's own organizers may change it.
  def update?
    user.present? && user.organizer_of?(record)
  end

  # The directory of organizations (name and description) is visible to every
  # signed-in user so they can find one to join. Activities, shifts and sign-ups
  # stay private to members through #show? and the policies for those records.
  class Scope < ApplicationPolicy::Scope
    def resolve
      user ? scope.all : scope.none
    end
  end
end
