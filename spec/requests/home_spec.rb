require 'rails_helper'

RSpec.describe "Home", type: :request do
  it "invites visitors to log in or sign up" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(new_user_session_path, new_user_registration_path)
  end

  it "labels every page as a course demonstration" do
    get root_path

    expect(response.body).to include("Course demonstration project for CSCI3100. Not an official CUHK service.")
  end

  it "lists the user's organizations with their role in each" do
    user = create(:user)
    create(:membership, :organizer, user: user, organization: create(:organization, name: "Green Campus Society"))
    create(:membership, user: user, organization: create(:organization, name: "Harbour Tutoring Club"))
    sign_in user

    get root_path

    page = Nokogiri::HTML(response.body)
    cards = page.css("a.card").to_h { |card| [ card.at_css("strong").text, card.at_css(".badge").text ] }
    expect(cards).to eq("Green Campus Society" => "Organizer", "Harbour Tutoring Club" => "Volunteer")
  end

  it "points users without memberships to the organizations page" do
    sign_in create(:user)

    get root_path

    expect(response.body).to include("You are not a member of any organization yet.")
    expect(response.body).to include(%(href="#{organizations_path}"))
  end
end
