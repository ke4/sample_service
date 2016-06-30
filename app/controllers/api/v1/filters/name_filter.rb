# See README.md for copyright details

class Api::V1::Filters::NameFilter
  def self.filter(params)
    { name: params[:name]}
  end
end