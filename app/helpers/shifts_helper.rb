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
    if shift.full?
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
end
