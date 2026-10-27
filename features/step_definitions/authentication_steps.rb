Given("a user {string} with password {string}") do |email, password|
  create(:user, email: email, password: password)
end

Given("I am logged in") do
  @current_user ||= create(:user)
  step %(I log in as "#{@current_user.email}" with password "password123")
end

When("I log in as {string} with password {string}") do |email, password|
  visit new_user_session_path
  fill_in "Email", with: email
  fill_in "Password", with: password
  click_button "Log in"
end

When("I sign up as {string} with email {string}") do |name, email|
  visit new_user_registration_path
  fill_in "Name", with: name
  fill_in "Email", with: email
  fill_in "Password", with: "password123"
  fill_in "Password confirmation", with: "password123"
  click_button "Sign up"
end
