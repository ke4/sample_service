class Api::V1::ApplicationController < ActionController::Base
  include JSONAPI::ActsAsResourceController

  protect_from_forgery with: :null_session
end