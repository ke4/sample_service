# See README.md for copyright details

class MaterialDerivative < ApplicationRecord
  belongs_to :child, class_name: 'Material', inverse_of: :child_derivatives
  belongs_to :parent, class_name: 'Material', inverse_of: :parent_derivatives
end
