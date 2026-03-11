Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  # Auth
  get "login", to: "sessions#new"
  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  # Email verification
  get "verify_email", to: "email_verifications#show"
  post "resend_verification", to: "email_verifications#create"
  get "verification_pending", to: "email_verifications#pending"

  # Active sessions & security
  resources :active_sessions, only: %i[index destroy]
  delete "active_sessions", to: "active_sessions#destroy_all", as: :destroy_all_active_sessions

  # Passkeys
  post "passkeys/register/options", to: "passkey_registrations#options"
  post "passkeys/register/verify", to: "passkey_registrations#verify"
  post "passkeys/authenticate/options", to: "passkey_sessions#options"
  post "passkeys/authenticate/verify", to: "passkey_sessions#verify"
  delete "passkeys/:id", to: "passkey_registrations#destroy", as: :passkey

  # Profile
  resource :profile, only: %i[show update] do
    patch :update_avatar
    delete :remove_avatar
    post :connect_instagram
    delete :disconnect_instagram
  end

  # Pages
  root "pages#home"
  get "download", to: "pages#download"
  get "stories", to: "pages#stories"
  get "profile-picture", to: "pages#profile_picture"
  get "analyzer", to: "pages#analyzer"
  get "hashtags", to: "pages#hashtags"
  get "influencers", to: "pages#influencers"
  get "pricing", to: "pages#pricing"

  # API
  namespace :api do
    post "download", to: "downloads#create"
    post "stories", to: "stories#create"
    post "profile_picture", to: "profile_pictures#create"
    post "analyze", to: "analyzers#create"
    post "hashtags", to: "hashtags#create"
    get "proxy", to: "proxy#show"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
