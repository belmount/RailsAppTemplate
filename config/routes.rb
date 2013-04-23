RailsAppTemplate::Application.routes.draw do
  #match '/auth/:provider/callback' => 'authentications#create'
  match '/registrations' => 'registrations#email'
  match "/signout" => "authentications#destroy", :as => :signout
  root :to => "home#index"
  devise_for :users, :controllers => {:omniauth_callbacks => 'users::omniauth_callbacks'}
  resources :users, :only => :show
  resources :authentications
end
