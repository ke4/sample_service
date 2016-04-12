# See README.md for copyright details

Rails.application.routes.draw do
  resources :metadata
  resources :materials
  resources :material_types
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'
end
