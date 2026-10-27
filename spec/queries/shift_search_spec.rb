require 'rails_helper'

RSpec.describe ShiftSearch do
  let(:green) { create(:organization, name: "Green Campus Society") }
  let(:harbour) { create(:organization, name: "Harbour Tutoring Club") }
  let(:tomorrow) { 1.day.from_now.change(hour: 9) }
  let!(:lake) do
    create(:shift, capacity: 1, starts_at: tomorrow, ends_at: tomorrow + 2.hours,
                   activity: create(:activity, organization: green, title: "Lake Clean-up", location: "Weiyuan Lake"))
  end
  let!(:tutoring) do
    create(:shift, starts_at: tomorrow + 5.days, ends_at: tomorrow + 5.days + 2.hours,
                   activity: create(:activity, organization: harbour, title: "Weekend Maths Tutoring", description: "Help with homework."))
  end

  def search(**filters)
    described_class.new(filters).results(Shift.all)
  end

  it "returns upcoming shifts soonest first" do
    create(:shift, :past)

    expect(search).to eq([ lake, tutoring ])
  end

  it "matches the activity title, location or description, ignoring case" do
    expect(search(q: "TUTORING")).to eq([ tutoring ])
    expect(search(q: "weiyuan")).to eq([ lake ])
    expect(search(q: "homework")).to eq([ tutoring ])
  end

  it "treats % and _ in the search text literally" do
    expect(search(q: "%")).to be_empty
  end

  it "filters by organization" do
    expect(search(organization_id: harbour.id)).to eq([ tutoring ])
  end

  it "filters by date range, including whole days" do
    expect(search(from: (tomorrow + 1.day).to_date)).to eq([ tutoring ])
    expect(search(to: tomorrow.to_date)).to eq([ lake ])
  end

  it "never returns shifts that have started, even with an earlier start date" do
    create(:shift, :past)

    expect(search(from: 1.week.ago.to_date)).to eq([ lake, tutoring ])
  end

  it "can show only shifts with free places" do
    create(:signup, shift: lake)
    create(:signup, :waitlisted, shift: tutoring)
    create(:signup, :cancelled, shift: tutoring)

    expect(search(open_only: true)).to eq([ tutoring ])
  end

  it "combines filters" do
    expect(search(q: "lake", organization_id: harbour.id)).to be_empty
  end

  it "rejects an end date before the start date" do
    search = described_class.new(from: tomorrow.to_date, to: Date.current)

    expect(search.results(Shift.all)).to be_empty
    expect(search.errors.full_messages).to include("To must not be before the start date")
  end

  it "ignores dates that cannot be read" do
    expect(search(from: "not-a-date")).to eq([ lake, tutoring ])
  end

  it "knows whether any filter is applied" do
    expect(described_class.new).not_to be_filtered
    expect(described_class.new(open_only: "1")).to be_filtered
  end
end
