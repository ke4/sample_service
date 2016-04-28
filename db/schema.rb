# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160425123715) do

  create_table "material_batches", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "material_batches_materials", id: false, force: :cascade do |t|
    t.integer  "material_id"
    t.integer  "material_batch_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "material_batches_materials", ["material_batch_id"], name: "index_material_batches_materials_on_material_batch_id"
  add_index "material_batches_materials", ["material_id"], name: "index_material_batches_materials_on_material_id"

  create_table "material_derivatives", force: :cascade do |t|
    t.integer  "parent_id"
    t.integer  "child_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "material_derivatives", ["child_id"], name: "index_material_derivatives_on_child_id"
  add_index "material_derivatives", ["parent_id"], name: "index_material_derivatives_on_parent_id"

  create_table "material_types", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "materials", force: :cascade do |t|
    t.integer  "material_type_id"
    t.string   "uuid",             limit: 36
    t.string   "name"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "materials", ["material_type_id"], name: "index_materials_on_material_type_id"
  add_index "materials", ["uuid"], name: "index_materials_on_uuid"

  create_table "metadata", force: :cascade do |t|
    t.string   "key"
    t.string   "value"
    t.integer  "material_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "metadata", ["material_id"], name: "index_metadata_on_material_id"

end
