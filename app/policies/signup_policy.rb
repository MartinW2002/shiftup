class SignupPolicy < ApplicationPolicy
  # Any member of the shift's organization may sign up. Capacity, overlap and duplicate
  # checks are business rules enforced by ShiftSignup, with their own messages.
  def create?
    user.present? && user.member_of?(organization)
  end

  # Volunteers cancel only their own sign-ups.
  def destroy?
    user.present? && record.user_id == user.id
  end

  # Only the organization's own organizers record attendance (US3).
  def mark_attendance?
    user.present? && user.organizer_of?(organization)
  end

  # Volunteers only ever see their own sign-ups.
  class Scope < ApplicationPolicy::Scope
    def resolve
      user ? scope.where(user: user) : scope.none
    end
  end

  private

  def organization
    record.shift.activity.organization
  end
end
