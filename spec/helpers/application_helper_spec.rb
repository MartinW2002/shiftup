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

    it "can be kept out of Turbo's page snapshots, so a one-time message is not shown again" do
      expect(box(helper.message_box(:success, "Saved", temporary: true))["data-turbo-temporary"]).to eq("true")
      expect(box(helper.message_box(:success, "Saved"))["data-turbo-temporary"]).to be_nil
    end

    it "escapes the text" do
      expect(helper.message_box(:error, "<b>bold</b>")).to include("&lt;b&gt;bold&lt;/b&gt;")
    end
  end

  describe "#flash_kind" do
    it "treats alerts and removal notices as errors, and everything else as confirmations" do
      expect(helper.flash_kind("alert")).to eq(:error)
      expect(helper.flash_kind(:removal)).to eq(:error)
      expect(helper.flash_kind(:notice)).to eq(:success)
      expect(helper.flash_kind(:promotion)).to eq(:success)
    end
  end
end
