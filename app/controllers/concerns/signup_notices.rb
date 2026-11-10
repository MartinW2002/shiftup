# Tells volunteers once about changes to their sign-ups made by someone else, on the first page
# they open afterwards (for a logged-out volunteer, the page they land on after logging in):
#  - they were moved from a waiting list to a confirmed place (green notice)
#  - an organizer removed them from a shift or its waiting list (red notice)
#
# A notice is only marked as seen when a page has actually shown it, so a redirect or a Turbo
# link prefetch (a background request when hovering a link) does not use it up.
module SignupNotices
  extend ActiveSupport::Concern

  included do
    before_action :load_signup_notices, if: :signup_notices_wanted?
    after_action :mark_signup_notices_shown, if: :signup_notices_shown?
  end

  private

  def signup_notices_wanted?
    user_signed_in? && request.get? && request.format.html? &&
      request.headers["X-Sec-Purpose"] != "prefetch" && !devise_controller?
  end

  def load_signup_notices
    signups = current_user.signups.includes(shift: { activity: :organization }).order("shifts.starts_at")
    @notified_promotions = signups.unnotified_promotions.to_a
    @notified_removals = signups.unnotified_removals.joins(:shift).to_a

    flash.now[:promotion] = promotion_notice(@notified_promotions) if @notified_promotions.any?
    flash.now[:removal] = removal_notice(@notified_removals) if @notified_removals.any?
  end

  def promotion_notice(signups)
    opened = signups.one? ? "A place opened up" : "Places opened up"
    "Good news! #{opened}, so you are now confirmed for #{signups.map { |signup| shift_name(signup) }.to_sentence}."
  end

  def removal_notice(signups)
    signups.group_by { |signup| signup.shift.activity.organization }.map do |organization, removed|
      "An organizer of #{organization.name} removed you from #{removed.map { |signup| shift_name(signup) }.to_sentence}."
    end.join(" ")
  end

  def shift_name(signup)
    "#{signup.shift.activity.title} on #{signup.shift.time_range_text}"
  end

  def signup_notices_shown?
    (@notified_promotions.present? || @notified_removals.present?) && response.successful?
  end

  def mark_signup_notices_shown
    now = Time.current
    Signup.where(id: @notified_promotions.map(&:id)).update_all(promotion_notified_at: now) if @notified_promotions.any?
    Signup.where(id: @notified_removals.map(&:id)).update_all(removal_notified_at: now) if @notified_removals.any?
  end
end
