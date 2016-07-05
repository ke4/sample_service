require 'test_helper'
require 'rails/performance_test_help'

class MaterialBatchTest < ActionDispatch::PerformanceTest
  # Refer to the documentation for all available options
  # self.profile_options = { runs: 5, metrics: [:wall_time, :memory],
  #                          output: 'tmp/performance', formats: [:flat] }

  test "creating 384 materials" do
    materials = build_material_batch_with_metadata

    post '/api/v1/material_batches', materials.to_json, {'Content-Type' => 'application/json'}
  end
end
