# See README.md for copyright details

JSONAPI.configure do |config|
  config.use_text_errors = true
  config.default_paginator = :paged
  config.default_page_size = 10

  config.json_key_format = :underscored_key
  config.route_format = :underscored_key
end