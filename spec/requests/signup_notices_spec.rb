require 'rails_helper'

RSpec.describe "Signup notices", type: :request do
  let(:user) { create(:user) }
  let(:lake) { create(:activity, title: "Lake Clean-up") }
  let(:shift) { create(:shift, activity: lake, starts_at: 2.days.from_now.change(hour: 9), ends_at: 2.days.from_now.change(hour: 11)) }

  def promoted(to: shift)
    create(:signup, user: user, shift: to, promoted_at: 1.minute.ago)
  end

  def notice
    Nokogiri::HTML(response.body).css(".message-success .message-body").map(&:text).find { |text| text.start_with?("Good news!") }
  end

  it "tells the volunteer on the page after logging in" do
    promoted

    post user_session_path, params: { user: { email: user.email, password: "password123" } }
    follow_redirect!

    expect(notice).to eq("Good news! A place opened up, so you are now confirmed for Lake Clean-up on #{shift.time_range_text}.")
    expect(response.body).to include("Signed in successfully.")
  end

  it "tells them only once" do
    promoted
    sign_in user

    get root_path
    expect(notice).to be_present

    get root_path
    expect(notice).to be_nil
  end

  it "combines several promotions in one notice, soonest first" do
    later = create(:shift, activity: create(:activity, title: "Recycling Drive"), starts_at: 5.days.from_now, ends_at: 5.days.from_now + 2.hours)
    promoted(to: later)
    promoted
    sign_in user

    get root_path

    expect(notice).to eq("Good news! Places opened up, so you are now confirmed for " \
                         "Lake Clean-up on #{shift.time_range_text} and Recycling Drive on #{later.time_range_text}.")
  end

  it "is not used up by a refused request, which redirects without showing it" do
    promoted
    sign_in user

    get organization_path(create(:organization)) # not a member: redirected
    expect(response).to have_http_status(:redirect)

    follow_redirect!
    expect(notice).to be_present
  end

  it "is not used up by a Turbo link prefetch" do
    promoted
    sign_in user

    get signups_path, headers: { "X-Sec-Purpose" => "prefetch" }
    expect(notice).to be_nil

    get signups_path
    expect(notice).to be_present
  end

  it "is not shown for a place the volunteer has cancelled since" do
    promoted.cancelled!
    sign_in user

    get root_path

    expect(notice).to be_nil
  end

  it "is not shown for a shift that has already started" do
    promoted(to: create(:shift, :past))
    sign_in user

    get root_path

    expect(notice).to be_nil
  end

  it "is never shown to other volunteers" do
    promoted
    sign_in create(:user)

    get root_path

    expect(notice).to be_nil
    expect(Signup.unnotified_promotions.count).to eq(1)
  end

  it "comes from a real cancellation end to end" do
    leaving = create(:signup, shift: shift.tap { |s| s.update!(capacity: 1) })
    create(:signup, :waitlisted, user: user, shift: shift)
    ShiftCancellation.new(shift: shift, user: leaving.user).call
    sign_in user

    get root_path

    expect(notice).to start_with("Good news! A place opened up, so you are now confirmed for Lake Clean-up")
  end

  describe "removal notices" do
    let(:organization) { create(:organization, name: "Green Campus Society") }
    let(:lake) { create(:activity, title: "Lake Clean-up", organization: organization) }

    def removal_notice
      Nokogiri::HTML(response.body).css(".message-error .message-body").map(&:text).find { |text| text.include?("removed you from") }
    end

    def removed(from: shift)
      create(:signup, :cancelled, user: user, shift: from, removed_at: 1.minute.ago)
    end

    it "tells the volunteer once, in red, after logging in" do
      removed

      post user_session_path, params: { user: { email: user.email, password: "password123" } }
      follow_redirect!
      expect(removal_notice).to eq("An organizer of Green Campus Society removed you from Lake Clean-up on #{shift.time_range_text}.")

      get root_path
      expect(removal_notice).to be_nil
    end

    it "combines removals by the same organization in one sentence" do
      later = create(:shift, activity: create(:activity, title: "Recycling Drive", organization: organization),
                             starts_at: 5.days.from_now, ends_at: 5.days.from_now + 2.hours)
      removed(from: later)
      removed
      sign_in user

      get root_path

      expect(removal_notice).to eq("An organizer of Green Campus Society removed you from " \
                                   "Lake Clean-up on #{shift.time_range_text} and Recycling Drive on #{later.time_range_text}.")
    end

    it "is not used up by a Turbo link prefetch" do
      removed
      sign_in user

      get signups_path, headers: { "X-Sec-Purpose" => "prefetch" }
      get signups_path

      expect(removal_notice).to be_present
    end

    it "shows a promotion and a removal side by side" do
      removed
      create(:signup, user: user, promoted_at: 1.minute.ago)
      sign_in user

      get root_path

      expect(removal_notice).to be_present
      expect(notice).to start_with("Good news!")
    end

    it "comes from a real removal end to end" do
      signup = create(:signup, user: user, shift: shift)
      ShiftRemoval.new(signup).call
      sign_in user

      get root_path

      expect(removal_notice).to start_with("An organizer of")
    end
  end
end
