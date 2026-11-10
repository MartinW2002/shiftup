# Tells volunteers once when they have been moved from a waiting list to a confirmed place:
# on the first page they open afterwards, which for a logged-out volunteer is the page they
# land on after logging in.
#
# The notice is only marked as seen when a page has actually shown it, so a redirect or a
# Turbo link prefetch (a background request when hovering a link) does not use it up.
module PromotionNotices
  extend ActiveSupport::Concern

  included do
    before_action :load_promotion_notice, if: :promotion_notice_wanted?
    after_action :mark_promotions_notified, if: :promotion_notice_shown?
  end

  private

  def promotion_notice_wanted?
    user_signed_in? && request.get? && request.format.html? &&
      request.headers["X-Sec-Purpose"] != "prefetch" && !devise_controller?
  end

  def load_promotion_notice
    @notified_promotions = current_user.signups.unnotified_promotions
                                       .includes(shift: :activity).order("shifts.starts_at").to_a
    return if @notified_promotions.empty?

    shifts = @notified_promotions.map { |signup| "#{signup.shift.activity.title} on #{signup.shift.time_range_text}" }
    opened = @notified_promotions.one? ? "A place opened up" : "Places opened up"
    flash.now[:promotion] = "Good news! #{opened}, so you are now confirmed for #{shifts.to_sentence}."
  end

  def promotion_notice_shown?
    @notified_promotions.present? && response.successful?
  end

  def mark_promotions_notified
    Signup.where(id: @notified_promotions.map(&:id)).update_all(promotion_notified_at: Time.current)
  end
end
