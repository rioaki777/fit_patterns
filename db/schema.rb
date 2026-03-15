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

ActiveRecord::Schema[8.0].define(version: 2026_03_02_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.string "auditable_type", null: false
    t.bigint "auditable_id", null: false
    t.string "event", null: false
    t.integer "user_id"
    t.jsonb "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "weekly_reports", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "period_start", null: false
    t.date "period_end", null: false
    t.integer "avg_weight_g"
    t.integer "avg_body_fat_bp"
    t.integer "total_calories_kcal"
    t.integer "total_workout_min"
    t.datetime "notified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "period_start", "period_end"], name: "idx_on_user_id_period_start_period_end_a2389f76e5", unique: true
    t.index ["user_id"], name: "index_weekly_reports_on_user_id"
  end

  create_table "weight_entries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "recorded_on", null: false
    t.integer "weight_g", null: false
    t.integer "body_fat_bp"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "recorded_on"], name: "index_weight_entries_on_user_id_and_recorded_on", unique: true
    t.index ["user_id"], name: "index_weight_entries_on_user_id"
  end

  create_table "workouts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "recorded_on", null: false
    t.string "kind", null: false
    t.integer "duration_min"
    t.integer "calories_kcal"
    t.integer "intensity"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "kind", "recorded_on"], name: "index_workouts_on_user_id_and_kind_and_recorded_on"
    t.index ["user_id", "recorded_on"], name: "index_workouts_on_user_id_and_recorded_on"
    t.index ["user_id"], name: "index_workouts_on_user_id"
  end

  add_foreign_key "weekly_reports", "users"
  add_foreign_key "weight_entries", "users"
  add_foreign_key "workouts", "users"
end
