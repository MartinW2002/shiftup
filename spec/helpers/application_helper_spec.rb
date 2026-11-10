require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "#message_box" do
    def box(html)
      Nokogiri::HTML.fragment(html).at_css(".message")
    end

    it "shows an error with a red ! icon, announced to screen readers as an alert" do
      message = box(helper.message_box(:error, "Something failed"))

      expect(message["class"]).to eq("message message-error")
      expect(message["role"]).to eq("alert")
      expect(message.at_css(".message-icon").text).to eq("!")
      expect(message.at_css(".message-body").text).to eq("Something failed")
    end

    it "shows a confirmation with a green check icon, announced politely" do
      message = box(helper.message_box(:success, "Saved"))

      expect(message["class"]).to eq("message message-success")
      expect(message["role"]).to eq("status")
      expect(message.at_css(".message-icon").text).to eq("✓")
    end

    it "accepts richer content as a block, and an extra class" do
      message = box(helper.message_box(:error, extra_class: "form-errors") { helper.tag.ul(helper.tag.li("One")) })

      expect(message["class"]).to eq("message message-error form-errors")
      expect(message.at_css(".message-body li").text).to eq("One")
    end

    it "escapes the text" do
      expect(helper.message_box(:error, "<b>bold</b>")).to include("&lt;b&gt;bold&lt;/b&gt;")
    end
  end

  describe "#flash_kind" do
    it "treats alerts as errors and everything else as confirmations" do
      expect(helper.flash_kind("alert")).to eq(:error)
      expect(helper.flash_kind(:notice)).to eq(:success)
    end
  end
end
