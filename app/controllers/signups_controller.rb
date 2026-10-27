class SignupsController < ApplicationController
  def index
    signups = policy_scope(Signup).includes(shift: { activity: :organization })
    @upcoming = signups.active.joins(:shift).merge(Shift.upcoming)
    @past = signups.confirmed.joins(:shift).where(shifts: { starts_at: ..Time.current }).order("shifts.starts_at DESC")
  end

  def create
    shift = Shift.find(params[:shift_id])
    authorize Signup.new(shift: shift, user: current_user)

    result = ShiftSignup.new(shift: shift, user: current_user).call
    redirect_with(result, shift)
  end

  def destroy
    shift = Shift.find(params[:shift_id])
    authorize Signup.new(shift: shift, user: current_user)

    result = ShiftCancellation.new(shift: shift, user: current_user).call
    redirect_with(result, shift)
  end

  private

  def redirect_with(result, shift)
    flash_type = result.success? ? :notice : :alert
    redirect_back_or_to shift.activity, flash_type => result.message, status: :see_other
  end
end
