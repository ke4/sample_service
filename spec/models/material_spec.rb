# See README.md for copyright details

require 'rails_helper'

RSpec.describe Material, type: :model do
  it "should make a valid material" do
    expect(build(:material)).to be_valid
  end

  it "should be invalid without a name" do
    expect(build(:material, name: nil)).to_not be_valid
  end

  it "should be invalid with a blank name" do
    expect(build(:material, name: '')).to_not be_valid
  end

  it "should have a valid UUID value" do
    expect(Material.new.uuid).to match(/^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$/i)
  end

  it "should be invalid without a material type" do
    expect(build(:material, material_type: nil)).to_not be_valid
  end
end