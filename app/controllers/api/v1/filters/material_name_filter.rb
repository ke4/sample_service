# See README.md for copyright details

class Api::V1::Filters::MaterialNameFilter
  def self.filter(params)
    { name: params[:name]}
  end
end