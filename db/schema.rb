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

ActiveRecord::Schema.define(version: 20160512195825) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "audits", force: :cascade do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "action"
    t.text     "audited_changes"
    t.integer  "version",          default: 0
    t.datetime "created_at"
    t.string   "comment"
    t.string   "remote_address"
    t.integer  "association_id"
    t.string   "association_type"
  end

  add_index "audits", ["auditable_id", "auditable_type"], name: "auditable_index", using: :btree
  add_index "audits", ["created_at"], name: "index_audits_on_created_at", using: :btree
  add_index "audits", ["user_id", "user_type"], name: "user_index", using: :btree

  create_table "client_applications", force: :cascade do |t|
    t.string   "name"
    t.string   "url"
    t.string   "support_url"
    t.string   "callback_url"
    t.string   "key",          limit: 20
    t.string   "secret",       limit: 40
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "client_applications", ["key"], name: "index_client_applications_on_key", unique: true, using: :btree

  create_table "comments", force: :cascade do |t|
    t.string   "title",            limit: 50, default: ""
    t.text     "comment",                     default: ""
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["commentable_id"], name: "index_comments_on_commentable_id", using: :btree
  add_index "comments", ["commentable_type"], name: "index_comments_on_commentable_type", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "flags", force: :cascade do |t|
    t.integer  "flaggable_id"
    t.string   "flaggable_type"
    t.string   "reason"
    t.text     "message"
    t.integer  "reporter_id"
    t.integer  "closer_id"
    t.datetime "closed_at"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "flags", ["flaggable_id", "flaggable_type"], name: "index_flags_on_flaggable_id_and_flaggable_type", unique: true, using: :btree
  add_index "flags", ["flaggable_id"], name: "index_flags_on_flaggable_id", using: :btree

  create_table "gcps", force: :cascade do |t|
    t.integer  "map_id"
    t.float    "x"
    t.float    "y"
    t.decimal  "lat",        precision: 15, scale: 10
    t.decimal  "lon",        precision: 15, scale: 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "soft",                                 default: false
    t.string   "name"
  end

  add_index "gcps", ["soft"], name: "index_gcps_on_soft", using: :btree

  create_table "imports", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "status"
    t.integer  "import_type"
    t.string   "uuid"
    t.string   "since_date"
    t.string   "until_date"
    t.string   "log_filename"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.datetime "finished_at"
  end

  create_table "layer_properties", force: :cascade do |t|
    t.integer "layer_id"
    t.string  "name"
    t.text    "value"
    t.integer "level"
  end

  create_table "layers", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.string   "catnyp"
    t.string   "uuid"
    t.string   "parent_uuid"
    t.boolean  "is_visible",                                                   default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "maps_count",                                                   default: 0
    t.integer  "rectified_maps_count",                                         default: 0
    t.string   "bbox"
    t.string   "depicts_year",         limit: 4,                               default: ""
    t.geometry "bbox_geom",            limit: {:srid=>4326, :type=>"polygon"}
  end

  add_index "layers", ["bbox_geom"], name: "index_layers_on_bbox_geom", using: :gist

  create_table "map_layers", force: :cascade do |t|
    t.integer "map_id"
    t.integer "layer_id"
  end

  create_table "maps", force: :cascade do |t|
    t.string   "title"
    t.text     "description"
    t.string   "filename"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "content_type"
    t.string   "thumbnail"
    t.integer  "size"
    t.integer  "width"
    t.integer  "height"
    t.integer  "parent_id"
    t.string   "nypl_digital_id"
    t.string   "catnyp"
    t.string   "uuid"
    t.string   "parent_uuid"
    t.integer  "status"
    t.integer  "mask_status"
    t.boolean  "map",                                                                                 default: true
    t.string   "bbox"
    t.integer  "map_type"
    t.geometry "bbox_geom",         limit: {:srid=>4326, :type=>"polygon"}
    t.decimal  "rough_lat",                                                 precision: 15, scale: 10
    t.decimal  "rough_lon",                                                 precision: 15, scale: 10
    t.geometry "rough_centroid",    limit: {:srid=>4326, :type=>"point"}
    t.integer  "rough_zoom"
    t.integer  "rough_state"
    t.datetime "rectified_at"
    t.datetime "gcp_touched_at"
    t.integer  "issue_year"
    t.string   "transform_options",                                                                   default: "auto"
    t.string   "resample_options",                                                                    default: "cubic"
  end

  add_index "maps", ["bbox_geom"], name: "index_maps_on_bbox_geom", using: :gist
  add_index "maps", ["rough_centroid"], name: "index_maps_on_rough_centroid", using: :gist

  create_table "my_maps", force: :cascade do |t|
    t.integer  "map_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "my_maps", ["map_id", "user_id"], name: "index_my_maps_on_map_id_and_user_id", unique: true, using: :btree
  add_index "my_maps", ["map_id"], name: "index_my_maps_on_map_id", using: :btree

  create_table "oauth_nonces", force: :cascade do |t|
    t.string   "nonce"
    t.integer  "timestamp"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_nonces", ["nonce", "timestamp"], name: "index_oauth_nonces_on_nonce_and_timestamp", unique: true, using: :btree

  create_table "oauth_tokens", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "type",                  limit: 20
    t.integer  "client_application_id"
    t.string   "token",                 limit: 20
    t.string   "secret",                limit: 40
    t.string   "callback_url"
    t.string   "verifier",              limit: 20
    t.datetime "authorized_at"
    t.datetime "invalidated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_tokens", ["token"], name: "index_oauth_tokens_on_token", unique: true, using: :btree

  create_table "permissions", force: :cascade do |t|
    t.integer  "role_id",    null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "settings", force: :cascade do |t|
    t.string "site_status"
    t.text   "banner_text"
  end

  create_table "users", force: :cascade do |t|
    t.string   "login"
    t.string   "email"
    t.string   "encrypted_password",        limit: 128, default: "",   null: false
    t.string   "password_salt",                         default: "",   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.string   "reset_password_token"
    t.boolean  "enabled",                               default: true
    t.integer  "updated_by"
    t.text     "description",                           default: ""
    t.datetime "confirmation_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         default: 0,    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "reset_password_sent_at"
    t.string   "provider"
    t.string   "uid"
  end

  create_table "version_associations", force: :cascade do |t|
    t.integer "version_id"
    t.string  "foreign_key_name", null: false
    t.integer "foreign_key_id"
  end

  add_index "version_associations", ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key", using: :btree
  add_index "version_associations", ["version_id"], name: "index_version_associations_on_version_id", using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.string   "ip"
    t.integer  "user_id"
    t.string   "user_agent"
    t.integer  "transaction_id"
    t.text     "object_changes"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  add_index "versions", ["transaction_id"], name: "index_versions_on_transaction_id", using: :btree

end
