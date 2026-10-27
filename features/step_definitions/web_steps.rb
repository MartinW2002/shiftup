When("I go to the organizations page") do
  visit organizations_path
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end

Then("I should not see {string}") do |text|
  expect(page).not_to have_content(text)
end

When("I press {string}") do |button|
  click_button button
end

When("I follow {string}") do |link|
  click_link link
end

When("I fill in {string} with {string}") do |field, value|
  fill_in field, with: value
end
