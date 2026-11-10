def shift_of(time, title)
  activity = Activity.find_by!(title: title)
  activity.shifts.find { |shift| shift.starts_at.strftime("%H:%M") == time } ||
    raise("No #{time} shift for #{title}")
end

def tomorrow_at(time)
  Time.zone.parse("#{Date.tomorrow} #{time}")
end

def member_of_shift(shift)
  user = create(:user)
  create(:membership, user: user, organization: shift.activity.organization)
  user
end

Given("{string} has a shift tomorrow from {string} to {string} with capacity {int}") do |title, from, to, capacity|
  create(:shift, activity: Activity.find_by!(title: title),
                 starts_at: tomorrow_at(from), ends_at: tomorrow_at(to), capacity: capacity)
end

Given("the {string} shift of {string} is full") do |time, title|
  shift = shift_of(time, title)
  (shift.capacity - shift.signups.confirmed.count).times do
    create(:signup, shift: shift, user: member_of_shift(shift))
  end
end

Given("{int} other volunteer(s) is/are waiting for the {string} shift of {string}") do |count, time, title|
  shift = shift_of(time, title)
  count.times { create(:signup, :waitlisted, shift: shift, user: member_of_shift(shift)) }
end

Given("I am confirmed for the {string} shift of {string}") do |time, title|
  create(:signup, shift: shift_of(time, title), user: @current_user)
end

Given("I am waiting for the {string} shift of {string}") do |time, title|
  create(:signup, :waitlisted, shift: shift_of(time, title), user: @current_user)
end

When("I go to the page for the activity {string}") do |title|
  visit activity_path(Activity.find_by!(title: title))
end

When("I go to my shifts") do
  visit signups_path
end

When("I try to sign up for the {string} shift of {string} directly") do |time, title|
  page.driver.submit :post, shift_signup_path(shift_of(time, title)), {}
end

When("I try to edit the {string} shift of {string} directly") do |time, title|
  visit edit_shift_path(shift_of(time, title))
end

When("I fill in the shift times for tomorrow from {string} to {string}") do |from, to|
  fill_in "Date", with: Date.tomorrow.iso8601
  fill_in "Start time", with: from
  fill_in "End time", with: to
end

# Days in the repeat calendar are checkboxes labelled like "Saturday 14 November 2026".
When("I also pick the dates {int} and {int} days after tomorrow") do |first, second|
  [ first, second ].each { |days| check (Date.tomorrow + days).strftime("%A %-d %B %Y") }
end

Then("the {string} shift of {string} should end the next day at {string}") do |time, title, end_time|
  shift = shift_of(time, title)
  expect(shift.ends_at.to_date).to eq(shift.starts_at.to_date + 1)
  expect(shift.ends_at.strftime("%H:%M")).to eq(end_time)
end

Then("{string} should have {int} shifts from {string} to {string}, a week apart") do |title, count, from, to|
  shifts = Activity.find_by!(title: title).shifts.order(:starts_at)
  expect(shifts.size).to eq(count)
  expect(shifts.map { |shift| [ shift.starts_at.strftime("%H:%M"), shift.ends_at.strftime("%H:%M") ] }.uniq).to eq([ [ from, to ] ])
  expect(shifts.each_cons(2).map { |a, b| (b.starts_at.to_date - a.starts_at.to_date).to_i }.uniq).to eq([ 7 ])
end

Then("I should be confirmed for the {string} shift of {string}") do |time, title|
  expect(shift_of(time, title).signups.find_by(user: @current_user)).to be_confirmed
end

Then("I should not be signed up for the {string} shift of {string}") do |time, title|
  expect(shift_of(time, title).signups.active.where(user: @current_user)).to be_empty
end

def volunteer_named(first_name)
  User.find_by(name: "#{first_name} Volunteer") || create(:user, name: "#{first_name} Volunteer")
end

def yesterday_at(time)
  Time.zone.parse("#{Date.yesterday} #{time}")
end

Given("{string} is waiting for the {string} shift of {string}") do |name, time, title|
  shift = shift_of(time, title)
  user = volunteer_named(name)
  create(:membership, user: user, organization: shift.activity.organization) unless user.member_of?(shift.activity.organization)
  create(:signup, :waitlisted, shift: shift, user: user, created_at: Time.current + Signup.count.seconds)
end

Given("{string} is confirmed for another shift tomorrow from {string} to {string}") do |name, from, to|
  create(:signup, user: volunteer_named(name), shift: create(:shift, starts_at: tomorrow_at(from), ends_at: tomorrow_at(to)))
end

Given("{string} had a shift yesterday from {string} to {string}") do |title, from, to|
  create(:shift, :past, activity: Activity.find_by!(title: title), starts_at: yesterday_at(from), ends_at: yesterday_at(to))
end

Given("{string} was confirmed for the {string} shift of {string}") do |name, time, title|
  shift = shift_of(time, title)
  user = volunteer_named(name)
  create(:membership, user: user, organization: shift.activity.organization) unless user.member_of?(shift.activity.organization)
  create(:signup, shift: shift, user: user)
end

Given("{string} was recorded as {word} for the {string} shift of {string}") do |name, attendance, time, title|
  shift_of(time, title).signups.find_by!(user: volunteer_named(name)).update!(attendance: attendance)
end

Given("I am {string}") do |name|
  @current_user = volunteer_named(name)
end

When("I go to edit the {string} shift of {string}") do |time, title|
  visit edit_shift_path(shift_of(time, title))
end

When("I go to the {string} shift of {string}") do |time, title|
  visit shift_path(shift_of(time, title))
end

When("I go to find shifts") do
  visit shifts_path
end

When("I mark {string} as {string}") do |name, button|
  within("#confirmed-volunteers li", text: volunteer_named(name).name) { click_button button }
end

When("I try to mark {string} as present for the {string} shift of {string} directly") do |name, time, title|
  signup = shift_of(time, title).signups.find_by!(user: volunteer_named(name))
  page.driver.submit :patch, signup_attendance_path(signup), { attendance: "present" }
end

Then("{string} should be confirmed for the {string} shift of {string}") do |name, time, title|
  expect(shift_of(time, title).signups.find_by!(user: volunteer_named(name))).to be_confirmed
end

Then("{string} should be number {int} on the waiting list for the {string} shift of {string}") do |name, position, time, title|
  expect(shift_of(time, title).signups.find_by!(user: volunteer_named(name)).waitlist_position).to eq(position)
end

Then("{string} should be recorded as {word} for the {string} shift of {string}") do |name, attendance, time, title|
  expect(shift_of(time, title).signups.find_by!(user: volunteer_named(name)).attendance).to eq(attendance)
end

Given("I was confirmed and present for the {string} shift of {string}") do |time, title|
  create(:signup, shift: shift_of(time, title), user: @current_user).update!(attendance: :present)
end

Given("{string} cancels the {string} shift of {string}") do |name, time, title|
  result = ShiftCancellation.new(shift: shift_of(time, title), user: volunteer_named(name)).call
  expect(result).to be_success
end

Then("the delete confirmation should say {string}") do |text|
  form = find("form[action='#{page.current_path}']", text: "Delete shift")
  expect(form["data-turbo-confirm"]).to eq(text)
end

Then("{string} should have no shifts") do |title|
  expect(Activity.find_by!(title: title).shifts).to be_empty
end
