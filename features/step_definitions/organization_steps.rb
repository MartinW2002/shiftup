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
