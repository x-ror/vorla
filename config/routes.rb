Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  # Auth
  get "login", to: "sessions#new"
  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

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
