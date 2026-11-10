# Organizers remove a volunteer from a shift or its waiting list. The volunteer is told on their
# next visit (SignupNotices).
class RemovalsController < ApplicationController
  def create
    signup = Signup.find(params[:signup_id])
    authorize signup, :remove?

    result = ShiftRemoval.new(signup).call
    if result.success?
      redirect_to signup.shift, notice: removed_message(result), status: :see_other
    else
      redirect_to signup.shift, alert: result.error, status: :see_other
    end
  end

  private

  def removed_message(result)
    name = result.signup.user.name
    return "#{name} was removed from the waiting list." unless result.was_confirmed

    message = "#{name} was removed from this shift."
    moved_up = result.promoted.map { |signup| signup.user.name }
    message += " #{moved_up.to_sentence} moved up from the waiting list." if moved_up.any?
    message
  end
end
