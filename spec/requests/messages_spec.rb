require 'rails_helper'

# Every message in the app uses the same box (ApplicationHelper#message_box).
RSpec.describe "Messages", type: :request do
  let(:user) { create(:user) }
  let(:organization) { create(:organization, name: "Green Campus Society") }

  def message(kind)
    Nokogiri::HTML(response.body).at_css(".message.message-#{kind} .message-body")&.text&.strip
  end

  it "shows a refused action as an error message" do
    sign_in user
    get organization_path(organization)
    follow_redirect!

    expect(message(:error)).to eq("Only members can see this organization's activities. Join it from the organizations page.")
  end

  it "shows a completed action as a confirmation message" do
    sign_in user
    post organization_membership_path(organization)
    follow_redirect!

    expect(message(:success)).to eq("You joined Green Campus Society as a volunteer.")
  end

  it "keeps flash messages out of Turbo's page cache, so they do not reappear on revisits" do
    sign_in user
    post organization_membership_path(organization)
    follow_redirect!

    expect(Nokogiri::HTML(response.body).at_css(".message-success")["data-turbo-temporary"]).to eq("true")
  end

  it "shows a failed login as an error message" do
    create(:user, email: "vera@example.com")

    post user_session_path, params: { user: { email: "vera@example.com", password: "wrong" } }

    expect(message(:error)).to eq("Invalid email or password.")
  end

  it "shows an invalid search as an error message" do
    sign_in user

    get shifts_path, params: { search: { from: "2026-12-10", to: "2026-12-01" } }

    expect(message(:error)).to eq("To must not be before the start date")
  end

  it "shows form errors as an error message" do
    post user_registration_path, params: { user: { name: "", email: "vera@example.com", password: "password123", password_confirmation: "password123" } }

    expect(message(:error)).to eq("Name can't be blank")
  end

  describe "error pages" do
    # The test environment shows Rails' debug page for errors; production shows public/404.html.
    around do |example|
      env_config = Rails.application.env_config
      detailed = env_config["action_dispatch.show_detailed_exceptions"]
      env_config["action_dispatch.show_detailed_exceptions"] = false
      example.run
    ensure
      env_config["action_dispatch.show_detailed_exceptions"] = detailed
    end

    it "shows a styled page for a missing record, as in production" do
      sign_in user

      get organization_path(id: 0)

      expect(response).to have_http_status(:not_found)
      page = Nokogiri::HTML(response.body)
      expect(page.at_css("h1").text).to eq("Page not found")
      expect(page.at_css(".message").text).to include("The page you were looking for doesn't exist.")
      expect(page.at_css("a.button")["href"]).to eq("/")
    end

    %w[400 404 406-unsupported-browser 422 500].each do |name|
      it "#{name}.html matches the app: logo, course banner, message box and a way home" do
        page = Nokogiri::HTML(Rails.public_path.join("#{name}.html").read)

        expect(page.at_css("title").text).to end_with("· ShiftUp")
        expect(page.at_css(".demo-banner").text).to include("Not an official CUHK service")
        expect(page.at_css(".message .message-icon").text).to eq("!")
        expect(page.at_css("a.button")["href"]).to eq("/")
        expect(page.text).not_to include("application owner")
      end
    end
  end
end
