Rails.application.routes.draw do
  # Auth
  resource :session
  resources :passwords, param: :token

  get "login",  to: "sessions#new"
  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  # Email verification
  get  "verify_email",        to: "email_verifications#show"
  post "resend_verification", to: "email_verifications#create"
  get  "verification_pending", to: "email_verifications#pending"

  # Security
  resources :active_sessions, only: %i[index destroy] do
    delete :destroy_all, on: :collection
  end

  scope "passkeys" do
    post "register/options",     to: "passkey_registrations#options"
    post "register/verify",      to: "passkey_registrations#verify"
    post "authenticate/options", to: "passkey_sessions#options"
    post "authenticate/verify",  to: "passkey_sessions#verify"
    delete ":id", to: "passkey_registrations#destroy", as: :passkey
  end

  # Profile
  resource :profile, only: %i[show update] do
    patch  :update_avatar
    delete :remove_avatar
    post   :connect_instagram
    delete :disconnect_instagram
  end

  # Bookmarks
  resources :bookmarks, only: %i[index create destroy]

  # History
  get "history", to: "history#index"

  # Pages
  root "pages#home"
  get "download",        to: "pages#download"
  get "stories",         to: "pages#stories"
  get "profile-picture", to: "pages#profile_picture"
  get "analyzer",        to: "pages#analyzer"
  get "hashtags",        to: "pages#hashtags"
  get "influencers",     to: "pages#influencers"
  get "pricing",         to: "pages#pricing"
  get "privacy",         to: "pages#privacy"
  get "terms",           to: "pages#terms"
  get "cookies",         to: "pages#cookies_policy"
  get "refund",          to: "pages#refund"

  # API
  namespace :api do
    post "download",        to: "downloads#create"
    post "stories",         to: "stories#create"
    post "profile_picture", to: "profile_pictures#create"
    post "analyze",         to: "analyzers#create"
    post "hashtags",        to: "hashtags#create"
    get  "proxy",           to: "proxy#show"
    get  "usage",           to: "usage#show"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
