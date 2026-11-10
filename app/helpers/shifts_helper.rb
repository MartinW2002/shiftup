module ShiftsHelper
  # Badge describing where the current user stands on a shift.
  def signup_status_badge(signup)
    if signup.confirmed?
      tag.span("Confirmed", class: "badge badge-confirmed")
    else
      tag.span("Waiting list ##{signup.waitlist_position}", class: "badge badge-waitlisted")
    end
  end

  def places_text(shift)
    if shift.ended?
      "Ended"
    elsif shift.started?
      "In progress"
    elsif shift.full?
      waiting = shift.waitlist_count
      "Full · #{pluralize(waiting, 'person')} waiting"
    else
      "#{shift.places_left} of #{shift.capacity} places left"
    end
  end

  def attendance_badge(signup)
    case signup.attendance
    when "present" then tag.span("Present", class: "badge badge-confirmed")
    when "absent" then tag.span("Absent", class: "badge badge-absent")
    else tag.span("Not recorded", class: "badge")
    end
  end

  def attendance_summary(signups)
    counts = signups.map(&:attendance).tally
    [ "#{counts.fetch('present', 0)} present", "#{counts.fetch('absent', 0)} absent", "#{counts.fetch('unmarked', 0)} not recorded" ].join(" · ")
  end

  # Text of the confirmation dialog for deleting a shift, naming who is affected.
  def delete_shift_confirmation(shift)
    confirmed = shift.confirmed_count
    waiting = shift.waitlist_count

    if shift.started?
      return "Delete this shift? Its attendance records for #{pluralize(confirmed, 'volunteer')} will be deleted." if confirmed.positive?
    else
      affected = []
      affected << pluralize(confirmed, "confirmed volunteer") if confirmed.positive?
      affected << "#{pluralize(waiting, 'person')} on the waiting list" if waiting.positive?
      return "Delete this shift? #{affected.to_sentence} will lose their place." if affected.any?
    end
    "Delete this shift?"
  end
end
