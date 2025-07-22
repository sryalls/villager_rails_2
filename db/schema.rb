# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_22_155527) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "building_outputs", force: :cascade do |t|
    t.bigint "building_id", null: false
    t.bigint "resource_id", null: false
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["building_id"], name: "index_building_outputs_on_building_id"
    t.index ["resource_id"], name: "index_building_outputs_on_resource_id"
  end

  create_table "buildings", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "costs", force: :cascade do |t|
    t.bigint "building_id", null: false
    t.bigint "tag_id", null: false
    t.integer "quantity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["building_id"], name: "index_costs_on_building_id"
    t.index ["tag_id"], name: "index_costs_on_tag_id"
  end

  create_table "job_executions", force: :cascade do |t|
    t.string "job_id", null: false
    t.string "job_type", null: false
    t.datetime "executed_at", null: false
    t.text "resource_snapshot"
    t.bigint "village_id"
    t.bigint "building_id"
    t.integer "multiplier", default: 1
    t.string "status", default: "completed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["building_id", "executed_at"], name: "index_job_executions_on_building_id_and_executed_at"
    t.index ["building_id"], name: "index_job_executions_on_building_id"
    t.index ["job_id", "job_type"], name: "index_job_executions_on_job_id_and_job_type", unique: true
    t.index ["status"], name: "index_job_executions_on_status"
    t.index ["village_id", "executed_at"], name: "index_job_executions_on_village_id_and_executed_at"
    t.index ["village_id"], name: "index_job_executions_on_village_id"
  end

  create_table "resource_productions", force: :cascade do |t|
    t.bigint "village_id", null: false
    t.bigint "building_id", null: false
    t.bigint "resource_id", null: false
    t.integer "quantity_produced", null: false
    t.integer "building_multiplier", default: 1
    t.datetime "produced_at", null: false
    t.string "loop_cycle_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["building_id"], name: "index_resource_productions_on_building_id"
    t.index ["loop_cycle_id"], name: "index_resource_productions_on_loop_cycle_id"
    t.index ["resource_id"], name: "index_resource_productions_on_resource_id"
    t.index ["village_id", "building_id", "produced_at"], name: "idx_on_village_id_building_id_produced_at_890d6ef435"
    t.index ["village_id", "building_id", "resource_id", "produced_at"], name: "index_resource_productions_on_unique_production"
    t.index ["village_id"], name: "index_resource_productions_on_village_id"
  end

  create_table "resources", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_resources_on_name", unique: true
  end

  create_table "resources_tags", id: false, force: :cascade do |t|
    t.bigint "resource_id", null: false
    t.bigint "tag_id", null: false
    t.index ["resource_id"], name: "index_resources_tags_on_resource_id"
    t.index ["tag_id"], name: "index_resources_tags_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tiles", force: :cascade do |t|
    t.integer "x"
    t.integer "y"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "username", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "village_buildings", force: :cascade do |t|
    t.bigint "village_id", null: false
    t.bigint "building_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["building_id"], name: "index_village_buildings_on_building_id"
    t.index ["village_id"], name: "index_village_buildings_on_village_id"
  end

  create_table "village_loop_failures", force: :cascade do |t|
    t.bigint "village_id", null: false
    t.string "loop_cycle_id"
    t.text "error_message"
    t.datetime "failed_at", null: false
    t.boolean "recovered", default: false
    t.datetime "recovered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loop_cycle_id"], name: "index_village_loop_failures_on_loop_cycle_id"
    t.index ["recovered", "failed_at"], name: "index_village_loop_failures_on_recovered_and_failed_at"
    t.index ["village_id", "failed_at"], name: "index_village_loop_failures_on_village_id_and_failed_at"
    t.index ["village_id"], name: "index_village_loop_failures_on_village_id"
  end

  create_table "village_resources", force: :cascade do |t|
    t.bigint "village_id", null: false
    t.bigint "resource_id", null: false
    t.integer "count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_id"], name: "index_village_resources_on_resource_id"
    t.index ["village_id"], name: "index_village_resources_on_village_id"
  end

  create_table "villages", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "tile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tile_id"], name: "index_villages_on_tile_id"
    t.index ["user_id"], name: "index_villages_on_user_id"
  end

  add_foreign_key "building_outputs", "buildings"
  add_foreign_key "building_outputs", "resources"
  add_foreign_key "costs", "buildings"
  add_foreign_key "costs", "tags"
  add_foreign_key "job_executions", "buildings"
  add_foreign_key "job_executions", "villages"
  add_foreign_key "resource_productions", "buildings"
  add_foreign_key "resource_productions", "resources"
  add_foreign_key "resource_productions", "villages"
  add_foreign_key "village_buildings", "buildings"
  add_foreign_key "village_buildings", "villages"
  add_foreign_key "village_loop_failures", "villages"
  add_foreign_key "village_resources", "resources"
  add_foreign_key "village_resources", "villages"
  add_foreign_key "villages", "tiles"
  add_foreign_key "villages", "users"
end
