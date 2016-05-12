# See README.md for copyright details

class Api::V1::Filters::MaterialBatchNameFilter
  def self.filter(params)
    { name: params[:name]}
  end
end