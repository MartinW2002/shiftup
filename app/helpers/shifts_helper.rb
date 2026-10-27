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
end
