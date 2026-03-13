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

ActiveRecord::Schema[8.1].define(version: 2026_03_13_100000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bookmark_items", force: :cascade do |t|
    t.integer "bookmark_id", null: false
    t.datetime "created_at", null: false
    t.string "media_type"
    t.string "media_url", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["bookmark_id", "media_url"], name: "index_bookmark_items_on_bookmark_id_and_media_url", unique: true
    t.index ["bookmark_id"], name: "index_bookmark_items_on_bookmark_id"
  end

  create_table "bookmarks", force: :cascade do |t|
    t.string "author"
    t.string "bookmark_type", null: false
    t.text "caption"
    t.datetime "created_at", null: false
    t.string "instagram_username"
    t.datetime "posted_at"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "bookmark_type"], name: "index_bookmarks_on_user_id_and_bookmark_type"
    t.index ["user_id", "url"], name: "index_bookmarks_on_user_id_and_url", unique: true
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "passkey_credentials", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.string "nickname"
    t.string "public_key", null: false
    t.integer "sign_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["external_id"], name: "index_passkey_credentials_on_external_id", unique: true
    t.index ["user_id"], name: "index_passkey_credentials_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "usage_logs", force: :cascade do |t|
    t.string "action_type", null: false
    t.datetime "created_at", null: false
    t.string "ip_address", null: false
    t.json "metadata", default: {}
    t.string "session_token"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["action_type", "ip_address", "created_at"], name: "index_usage_logs_on_action_type_and_ip_address_and_created_at"
    t.index ["action_type", "user_id", "created_at"], name: "index_usage_logs_on_action_type_and_user_id_and_created_at"
    t.index ["created_at"], name: "index_usage_logs_on_created_at"
    t.index ["user_id"], name: "index_usage_logs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "full_name"
    t.datetime "instagram_connected_at"
    t.string "instagram_id"
    t.string "instagram_username"
    t.string "locale", limit: 5
    t.string "password_digest", null: false
    t.string "plan"
    t.datetime "terms_accepted_at"
    t.datetime "updated_at", null: false
    t.boolean "verified", default: false, null: false
    t.string "webauthn_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bookmark_items", "bookmarks"
  add_foreign_key "bookmarks", "users"
  add_foreign_key "passkey_credentials", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "usage_logs", "users"
end
