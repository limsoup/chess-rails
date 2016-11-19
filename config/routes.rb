Rails.application.routes.draw do
  resources :chess_games
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'static_pages#home'

  resources :users, path_names: {new: "register", show: "profile"}
  # resources :sessions, only: [:new, :create, :destroy], path_names: {new: "login", create:"login", destroy: "logout"}
  get 'login' => "sessions#new", as: 'login'
  post 'login' => "sessions#create"
  get 'logout' => "sessions#destroy", as: 'logout'

  resources :chess_games, only: [:new, :create, :destroy] do
    member do
      get 'destroy', as: 'destroy'
      get 'accept', as: 'accept'
      get 'moves', as: 'moves'
      get 'reset', as: 'reset'
      get 'recalculate', as: 'recalculate'
      get 'ping', as: 'ping'
      get 'game_state', as: 'game_state'
      post 'do_move', as: 'do_move'
    end
  end
  # get 'register' => 'users#new', as: :register
  # post 'register' => 'users#create'
  # get 'users/:id' => 'users#show'
  # get 'profile' => 'users#profile'


  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
