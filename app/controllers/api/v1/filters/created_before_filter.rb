# See README.md for copyright details

class Api::V1::Filters::CreatedBeforeFilter
  def self.filter(params)
    [ 'created_at <= ?', params[:created_before].to_datetime ]
  end
end