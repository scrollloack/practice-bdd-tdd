Rails.application.routes.draw do
  resources :products, only: [ :index ] do
    collection do
      post 'add_to_cart', to: 'products#add_to_cart'
    end
  end

  get 'up' => 'rails/health#show', as: :rails_health_check

  root to: redirect('/products', status: 301)
end
