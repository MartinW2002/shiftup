Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  resources :organizations, only: %i[index show] do
    resource :membership, only: :create
    resources :activities, only: %i[new create]
  end

  resources :activities, only: %i[show edit update destroy] do
    resources :shifts, only: %i[new create]
  end

  resources :shifts, only: %i[index show edit update destroy] do
    resource :signup, only: %i[create destroy]
  end

  resources :signups, only: [] do
    resource :attendance, only: :update
  end

  # The signed-in volunteer's own schedule.
  get "my/shifts" => "signups#index", as: :signups

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
