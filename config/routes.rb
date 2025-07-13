Rails.application.routes.draw do
  resources :products, only: [ :index ]

  get "up" => "rails/health#show", as: :rails_health_check

  root to: redirect('/products', status: 301)
end
