# Lets a volunteer leave an organization.
#
# Their upcoming shifts and waiting list places in the organization are cancelled one by one
# through ShiftCancellation, so each confirmed place goes to the next eligible volunteer on the
# waiting list. Each cancellation runs in its own transaction, so only one shift is locked at a
# time (see ShiftPromotion for the lock order). Past sign-ups and attendance records are kept.
class MembershipCancellation
  Result = Data.define(:organization, :cancelled, :cancelled_summary, :error) do
    def success? = error.nil?

    def message
      return error unless success?

      message = "You left #{organization.name}."
      message += " Your #{cancelled_summary} there #{cancelled == 1 ? 'was' : 'were'} cancelled." if cancelled.positive?
      message
    end
  end

  def initialize(membership)
    @membership = membership
  end

  def call
    summary = membership.upcoming_signups_summary
    signups = membership.upcoming_signups.includes(:shift).to_a
    signups.each { |signup| ShiftCancellation.new(shift: signup.shift, user: membership.user).call }

    # The guard in Membership refuses if a sign-up appeared meanwhile (for example from another tab).
    if membership.destroy
      Result.new(organization: membership.organization, cancelled: signups.size, cancelled_summary: summary, error: nil)
    else
      Result.new(organization: membership.organization, cancelled: signups.size, cancelled_summary: summary,
                 error: membership.errors.full_messages.to_sentence)
    end
  end

  private

  attr_reader :membership
end
