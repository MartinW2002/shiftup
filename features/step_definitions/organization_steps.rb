Given("the organization {string} exists") do |name|
  create(:organization, name: name)
end

Given("I am a(n) {word} of {string}") do |role, name|
  @current_user ||= create(:user)
  create(:membership, user: @current_user, organization: Organization.find_by!(name: name), role: role)
end

When("I visit the page for {string}") do |name|
  visit organization_path(Organization.find_by!(name: name))
end

When("I join {string}") do |name|
  within("#other-organizations .card", text: name) { click_button "Join" }
end

Then("I should be a(n) {word} of {string}") do |role, name|
  membership = @current_user.membership_in(Organization.find_by!(name: name))
  expect(membership&.role).to eq(role)
end

Then("{string} should be listed under {string}") do |name, heading|
  within(:xpath, "//section[h2[normalize-space()='#{heading}']]") do
    expect(page).to have_css(".card", text: name)
  end
end

Then("there should be no join button for {string}") do |name|
  expect(page).not_to have_css("#other-organizations .card", text: name)
end

When("I open {string} from my organizations") do |name|
  within("#my-organizations") { find("a.card", text: name).click }
end

Then("I should be on the page for {string}") do |name|
  expect(page).to have_current_path(organization_path(Organization.find_by!(name: name)))
end
