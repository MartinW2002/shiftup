require 'rails_helper'

# Checks the authorization safety net shared by every controller.
RSpec.describe ApplicationController, type: :controller do
  controller do
    def show
      head :ok
    end

    def update
      authorize Organization.find(params[:id])
      head :ok
    end
  end

  before do
    routes.draw do
      get "anonymous/:id" => "anonymous#show"
      patch "anonymous/:id" => "anonymous#update"
    end
    sign_in create(:user)
  end

  it "fails loudly when an action forgets to check authorization" do
    expect { get :show, params: { id: 1 } }.to raise_error(Pundit::AuthorizationNotPerformedError)
  end

  it "falls back to a generic message for rules without their own message" do
    patch :update, params: { id: create(:organization).id }

    expect(flash[:alert]).to eq("You are not authorized to perform this action.")
  end
end
