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
  fill_in "Starts at", with: tomorrow_at(from).strftime("%Y-%m-%dT%H:%M")
  fill_in "Ends at", with: tomorrow_at(to).strftime("%Y-%m-%dT%H:%M")
end

Then("I should be confirmed for the {string} shift of {string}") do |time, title|
  expect(shift_of(time, title).signups.find_by(user: @current_user)).to be_confirmed
end

Then("I should not be signed up for the {string} shift of {string}") do |time, title|
  expect(shift_of(time, title).signups.where(user: @current_user)).to be_empty
end
