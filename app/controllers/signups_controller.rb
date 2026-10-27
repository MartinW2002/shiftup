class SignupsController < ApplicationController
  def index
    @signups = policy_scope(Signup).active
                                   .joins(:shift).merge(Shift.upcoming)
                                   .includes(shift: { activity: :organization })
  end

  def create
    shift = Shift.find(params[:shift_id])
    authorize Signup.new(shift: shift, user: current_user)

    result = ShiftSignup.new(shift: shift, user: current_user).call
    flash_type = result.success? ? :notice : :alert
    redirect_back_or_to shift.activity, flash_type => result.message, status: :see_other
  end
end
