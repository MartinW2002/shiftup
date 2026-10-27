# Organizers record whether a confirmed volunteer attended a shift (US3).
class AttendancesController < ApplicationController
  def update
    signup = Signup.find(params[:signup_id])
    authorize signup, :mark_attendance?

    if signup.update(attendance: params[:attendance])
      flash[:notice] = attendance_message(signup)
    else
      flash[:alert] = signup.errors.full_messages.to_sentence
    end
    redirect_to signup.shift, status: :see_other
  end

  private

  def attendance_message(signup)
    if signup.attendance_unmarked?
      "Attendance cleared for #{signup.user.name}."
    else
      "Attendance saved: #{signup.user.name} was #{signup.attendance}."
    end
  end
end
