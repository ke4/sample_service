require 'rails_helper'

RSpec.describe MaterialBatch, type: :model do
  it "should have at least one material" do
    expect(build(:material_batch)).to be_valid
  end

  it "should be invalid without material" do
    expect(build(:material_batch, materials: [])).to_not be_valid
  end
end
