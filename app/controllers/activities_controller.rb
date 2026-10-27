class ActivitiesController < ApplicationController
  before_action :set_organization, only: %i[new create]
  before_action :set_activity, only: %i[show edit update destroy]

  def show
    @shifts = @activity.shifts.order(:starts_at)
    @my_signups = current_user.signups.active.where(shift: @shifts).index_by(&:shift_id)
  end

  def new
    @activity = authorize @organization.activities.build
  end

  def create
    @activity = authorize @organization.activities.build(activity_params)

    if @activity.save
      redirect_to @activity, notice: "Activity created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @activity.update(activity_params)
      redirect_to @activity, notice: "Activity updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @activity.destroy
      redirect_to @activity.organization, notice: "Activity deleted.", status: :see_other
    else
      redirect_to @activity, alert: @activity.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_activity
    @activity = authorize Activity.find(params[:id])
  end

  def activity_params
    params.expect(activity: %i[title location description])
  end
end
