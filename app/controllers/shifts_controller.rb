class ShiftsController < ApplicationController
  before_action :set_activity, only: %i[new create]
  before_action :set_shift, only: %i[show edit update destroy]

  def show
    @my_signup = current_user.signups.active.find_by(shift: @shift)
    return unless policy(@shift).update?

    @confirmed = @shift.signups.confirmed.includes(:user).order(:created_at, :id)
    @waitlist = @shift.signups.waitlist_order.includes(:user)
  end

  def new
    @shift = authorize @activity.shifts.build
  end

  def create
    @shift = authorize @activity.shifts.build(shift_params)

    if @shift.save
      redirect_to @activity, notice: "Shift added."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    # Locked so a capacity change cannot race with a volunteer signing up.
    saved = @shift.with_lock { @shift.update(shift_params) }

    if saved
      redirect_to @shift, notice: "Shift updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @shift.destroy
      redirect_to @shift.activity, notice: "Shift deleted.", status: :see_other
    else
      redirect_to @shift, alert: @shift.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_activity
    @activity = Activity.find(params[:activity_id])
  end

  def set_shift
    @shift = authorize Shift.find(params[:id])
  end

  def shift_params
    params.expect(shift: %i[starts_at ends_at capacity])
  end
end
