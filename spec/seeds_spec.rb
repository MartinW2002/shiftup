require 'rails_helper'

# The seeds run on every Render deploy, so they must be safe to run repeatedly.
RSpec.describe "Demo seed data" do
  # Seeded shifts are placed relative to the next Saturday; a fixed Monday keeps the examples deterministic.
  before { travel_to(Time.zone.parse("2026-11-02 10:00")) }
  after { travel_back }

  def seed
    allow($stdout).to receive(:puts)
    load Rails.root.join("db/seeds.rb")
  end

  it "creates two organizations with an organizer each" do
    seed

    expect(Organization.count).to eq(2)
    Organization.find_each { |organization| expect(organization.organizers.count).to eq(1) }
  end

  it "keeps each organizer's role limited to their own organization" do
    seed

    green = Organization.find_by!(name: "Green Campus Society")
    harbour = Organization.find_by!(name: "Harbour Tutoring Club")
    organizer = User.find_by!(email: "organizer.green@example.com")
    expect(organizer.organizer_of?(green)).to be true
    expect(organizer.member_of?(harbour)).to be false
  end

  it "includes a volunteer with overlapping shifts in two organizations, for the overlap demo" do
    seed

    volunteer = User.find_by!(email: "volunteer1@example.com")
    lake = Activity.find_by!(title: "Lake Clean-up").shifts.order(:starts_at).first
    tutoring = Activity.find_by!(title: "Weekend Maths Tutoring").shifts.order(:starts_at).first
    expect(volunteer.organizations.count).to eq(2)
    expect(lake.overlaps?(tutoring)).to be true
  end

  it "sets up the sign-ups the demo relies on" do
    seed

    volunteer1 = User.find_by!(email: "volunteer1@example.com")
    lake = Activity.find_by!(title: "Lake Clean-up").shifts.upcoming.first
    tutoring = Activity.find_by!(title: "Weekend Maths Tutoring").shifts.upcoming.first
    recycling = Activity.find_by!(title: "Recycling Drive").shifts.upcoming.first

    expect(lake.signups.find_by(user: volunteer1)).to be_confirmed
    expect(recycling).to be_full
    expect(ShiftSignup.new(shift: tutoring, user: volunteer1).call.error).to start_with("This shift overlaps your confirmed shift for Lake Clean-up")
  end

  it "lets the demo accounts log in with the documented password" do
    seed

    expect(User.find_by!(email: "volunteer1@example.com").valid_password?("password123")).to be true
  end

  it "does not duplicate anything when run again" do
    seed

    expect { seed }.not_to change { [ Organization.count, User.count, Membership.count, Activity.count, Shift.count, Signup.count ] }
  end

  it "does not add shifts to an activity that still has upcoming ones when a later week's deploy seeds again" do
    seed
    tutoring = Activity.find_by!(title: "Weekend Maths Tutoring")

    travel 8.days

    expect { seed }.not_to change { tutoring.shifts.count }
  end

  it "adds fresh upcoming shifts once the demo shifts are in the past" do
    seed

    travel 30.days
    expect(Shift.upcoming).to be_empty

    seed

    expect(Shift.upcoming.count).to eq(5)
    expect(Signup.joins(:shift).merge(Shift.upcoming).count).to eq(3)
  end
end
