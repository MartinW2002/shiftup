# Demo data for local development and the deployed course demonstration.
# All organizations, people and events are fictional. Running this file twice is safe.

def demo_user(email, name)
  User.find_or_create_by!(email: email) do |user|
    user.name = name
    user.password = ENV.fetch("DEMO_PASSWORD", "password123")
  end
end

green = Organization.find_or_create_by!(name: "Green Campus Society") do |org|
  org.description = "Campus clean-ups, recycling drives and tree planting."
end
harbour = Organization.find_or_create_by!(name: "Harbour Tutoring Club") do |org|
  org.description = "Free weekend tutoring for secondary school students."
end

green_organizer   = demo_user("organizer.green@example.com", "Grace Organizer")
harbour_organizer = demo_user("organizer.harbour@example.com", "Henry Organizer")
volunteers = [
  demo_user("volunteer1@example.com", "Vera Volunteer"),
  demo_user("volunteer2@example.com", "Victor Volunteer"),
  demo_user("volunteer3@example.com", "Wendy Volunteer")
]

Membership.find_or_create_by!(user: green_organizer, organization: green) { |m| m.role = :organizer }
Membership.find_or_create_by!(user: harbour_organizer, organization: harbour) { |m| m.role = :organizer }
volunteers.each do |volunteer|
  Membership.find_or_create_by!(user: volunteer, organization: green) { |m| m.role = :volunteer }
end
Membership.find_or_create_by!(user: volunteers.first, organization: harbour) { |m| m.role = :volunteer }

def demo_activity(organization, title, location:, description:, shifts:)
  activity = organization.activities.find_or_create_by!(title: title) do |a|
    a.location = location
    a.description = description
  end
  # Render seeds on every deploy. Shifts are only added when the activity has no upcoming
  # ones, so redeploying never duplicates them, and stale demo data is refreshed once it is in the past.
  if activity.shifts.upcoming.none?
    shifts.each do |starts_at, hours, capacity|
      activity.shifts.create!(starts_at: starts_at, ends_at: starts_at + hours.hours, capacity: capacity)
    end
  end
  activity
end

base = Time.zone.now.next_occurring(:saturday).change(hour: 9)

demo_activity(green, "Lake Clean-up",
              location: "Weiyuan Lake",
              description: "Collect litter around the lake. Gloves and bags provided.",
              shifts: [ [ base, 2, 3 ], [ base + 2.hours, 2, 3 ] ])
demo_activity(green, "Recycling Drive",
              location: "University Station",
              description: "Sort donated items and help visitors at the collection point.",
              shifts: [ [ base + 1.day, 3, 2 ] ])
demo_activity(harbour, "Weekend Maths Tutoring",
              location: "Library Learning Commons",
              description: "Help secondary students with homework.",
              shifts: [ [ base + 1.hour, 2, 2 ], [ base + 7.days, 2, 2 ] ])

puts "Seeded #{Organization.count} organizations, #{User.count} users, #{Shift.count} shifts."
