# See README.md for copyright details

Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      jsonapi_resources :materials
      jsonapi_resources :material_types
    end
  end
end
