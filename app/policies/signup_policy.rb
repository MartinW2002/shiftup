class SignupPolicy < ApplicationPolicy
  # Any member of the shift's organization may sign up. Capacity, overlap and duplicate
  # checks are business rules enforced by ShiftSignup, with their own messages.
  def create?
    user.present? && user.member_of?(record.shift.activity.organization)
  end

  # Volunteers only ever see their own sign-ups.
  class Scope < ApplicationPolicy::Scope
    def resolve
      user ? scope.where(user: user) : scope.none
    end
  end
end
