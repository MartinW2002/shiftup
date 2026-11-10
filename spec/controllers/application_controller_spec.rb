require 'rails_helper'

# Checks the safety nets shared by every controller: authorization and promotion notices.
RSpec.describe ApplicationController, type: :controller do
  controller do
    def show
      head :ok
    end

    def update
      authorize Organization.find(params[:id])
      head :ok
    end

    def index
      skip_policy_scope
      params[:redirect] ? redirect_to("/") : render(html: "page")
    end
  end

  before do
    routes.draw do
      get "anonymous/:id" => "anonymous#show"
      patch "anonymous/:id" => "anonymous#update"
      get "anonymous" => "anonymous#index"
    end
    sign_in user
  end

  let(:user) { create(:user) }

  it "fails loudly when an action forgets to check authorization" do
    expect { get :show, params: { id: 1 } }.to raise_error(Pundit::AuthorizationNotPerformedError)
  end

  it "falls back to a generic message for rules without their own message" do
    patch :update, params: { id: create(:organization).id }

    expect(flash[:alert]).to eq("You are not authorized to perform this action.")
  end

  describe "promotion notices" do
    let!(:promotion) { create(:signup, user: user, promoted_at: 1.minute.ago) }

    it "marks the notice as seen once a page has shown it" do
      get :index

      expect(promotion.reload.promotion_notified_at).to be_present
    end

    it "keeps the notice for later when the response is a redirect" do
      get :index, params: { redirect: true }

      expect(promotion.reload.promotion_notified_at).to be_nil
    end
  end
end
