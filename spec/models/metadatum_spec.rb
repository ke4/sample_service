# See README.md for copyright details

require 'rails_helper'

RSpec.describe Metadatum, type: :model do
  it "should make a valid metadatum" do
    expect(build(:metadatum)).to be_valid
  end

  it "should be invalid without a key" do
    expect(build(:metadatum, key: nil)).to_not be_valid
  end

  it "should be invalid with a blank key" do
    expect(build(:metadatum, key: '')).to_not be_valid
  end

  it "should be invalid without a material" do
    expect(build(:metadatum, material: nil)).to_not be_valid
  end

  it "should be valid with same key but different material" do
    metadatum_1 = create(:metadatum, key: "key_1")
    
    metadatum_2 = build(:metadatum, key: "key_1")
    expect(metadatum_2).to be_valid
  end

  it "should be invalid with same key and same material" do
    material = create(:material)
    metadatum_1 = create(:metadatum, key: 'key_1', material: material)
   
    metadatum_2 = build(:metadatum, key: 'key_1', material: material)
    expect(metadatum_2).to_not be_valid
  end
end
