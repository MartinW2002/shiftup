class ShiftsController < ApplicationController
  before_action :set_activity, only: %i[new create]
  before_action :set_shift, only: %i[show edit update destroy]

  def index
    @search = ShiftSearch.new(search_params)
    @shifts = @search.results(policy_scope(Shift))
    @organizations = current_user.organizations.order(:name)
    @my_signups = current_user.signups.active.where(shift: @shifts).index_by(&:shift_id)
  end

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
    # Locked so a capacity change cannot race with a volunteer signing up. A higher capacity
    # immediately confirms volunteers from the waiting list.
    promoted = []
    saved = @shift.with_lock do
      @shift.update(shift_params).tap { |updated| promoted = ShiftPromotion.new(@shift).call if updated }
    end

    if saved
      notice = "Shift updated."
      notice += " #{helpers.pluralize(promoted.size, 'volunteer')} #{promoted.one? ? 'was' : 'were'} moved from the waiting list." if promoted.any?
      redirect_to @shift, notice: notice
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

  def search_params
    params.fetch(:search, {}).permit(:q, :organization_id, :from, :to, :open_only)
  end

  def shift_params
    params.expect(shift: %i[starts_at ends_at capacity])
  end
end
