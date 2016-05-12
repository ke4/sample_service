require 'rails_helper'

RSpec.describe Api::V1::ApplicationController, type: :request do

  it 'should filter a single object' do
    schema = {
        data: [
            :id,
            :name,
            :uuid
        ]
    }

    object = ActionController::Parameters.new({
        data: {
            id: 1,
            name: 'test',
            extra_name: 'foo'
        }
    })

    filtered_object = object.permit(schema)

    expect(filtered_object).to eq({
                                      data: {
                                          id: 1,
                                          name: 'test'
                                      }
                                  })
  end

  it 'should filter nested objects' do
    schema = {
        data: [
            :id,
            attributes: [
                :name,
                :uuid,
                :size
            ]
        ]
    }

    object = ActionController::Parameters.new({
        data: {
            id: 1,
            attributes: {
                name: 'foo',
                size: 3,
                extra_name: 'bar'
            }
        }
    })

    filtered_object = object.permit(schema)

    expect(filtered_object).to eq({
                                      data: {
                                          id: 1,
                                          attributes: {
                                              name: 'foo',
                                              size: 3
                                          }
                                      }
                                  })
  end

  it 'should filter with arrays' do
    schema = {
        data: [
            :id,
            attributes: [
                :name,
                :uuid,
                :size
            ]
        ]
    }

    object = ActionController::Parameters.new({
        data: [
            {
                id: 1,
                attributes: {
                    name: 'foo1',
                    size: 1,
                    extra_name: 'bar1'
                }
            },
            {
                id: 2,
                attributes: {
                    name: 'foo2',
                    size: 2,
                    extra_name: 'bar2'
                }
            },
        ]
    })

    filtered_object = object.permit(schema)

    expect(filtered_object).to eq({
                                      data: [
                                          {
                                              id: 1,
                                              attributes: {
                                                  name: 'foo1',
                                                  size: 1
                                              }
                                          },
                                          {
                                              id: 2,
                                              attributes: {
                                                  name: 'foo2',
                                                  size: 2
                                              }
                                          }
                                      ]
                                  })

  end

  it 'should filter a nested has with missing hashes' do
    schema = {
        data: [
            :id,
            attributes: [
                :name,
                :uuid,
                :size
            ],
            relationships: {
                parents: {
                    data: [
                        :id
                    ]
                },
                material_type: {
                    data: {
                        attributes: [
                            :name
                        ]
                    }
                }
            }
        ]
    }

    object = ActionController::Parameters.new({
        data: {
            id: 1,
            attributes: {
                name: 'foo',
                size: 3,
                extra_name: 'bar'
            },
            relationships: {
                material_type: {
                    data: {
                        attributes: {
                            name: 'sample'
                        }
                    }
                }
            }
        }
    })

    filtered_object = object.permit(schema)

    expect(filtered_object).to eq({
                                      data: {
                                          id: 1,
                                          attributes: {
                                              name: 'foo',
                                              size: 3
                                          },
                                          relationships: {
                                              material_type: {
                                                  data: {
                                                      attributes: {
                                                          name: 'sample'
                                                      }
                                                  }
                                              }
                                          }
                                      }
                                  })
  end
end