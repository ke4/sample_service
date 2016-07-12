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

   it "should be invalid without a material type" do
    expect(build(:material, material_type: nil)).to_not be_valid
  end

  it "should create a uuid" do
    expect(create(:material).uuid).to be_present
  end

  it "should be valid with a valid uuid" do
    expect(build(:material, uuid: UUID.new.generate)).to be_valid
  end

  it "should not be valid without a valid uuid" do
    expect(build(:material, uuid: "wibble")).to_not be_valid
  end
end
