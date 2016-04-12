# See README.md for copyright details

require 'rails_helper'

RSpec.describe MaterialType, type: :model do
  it "should make a valid material type" do
    expect(build(:material_type)).to be_valid
  end

  it "should be invalid without a name" do
    expect(build(:material_type, name: nil)).to_not be_valid
  end

  it "should be invalid with a blank name" do
    expect(build(:material_type, name: '')).to_not be_valid
  end
end