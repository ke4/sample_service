# See README.md for copyright details

Rails.application.routes.draw do

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :material_batches,  only: [:create]
      resources :materials,         only: [:index, :show, :create, :update]
      resources :material_types,    only: [:index, :show]
    end
  end
end
