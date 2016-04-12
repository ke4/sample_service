# See README.md for copyright details

Rails.application.routes.draw do

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :metadata
      resources :materials
      resources :material_types
    end
  end
end
