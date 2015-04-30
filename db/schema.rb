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

ActiveRecord::Schema.define(version: 20150424134733) do

  create_table "audits", force: :cascade do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type",   limit: 255
    t.integer  "user_id"
    t.string   "user_type",        limit: 255
    t.string   "username",         limit: 255
    t.string   "action",           limit: 255
    t.text     "audited_changes"
    t.integer  "version",                      default: 0
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
    t.string   "name",         limit: 255
    t.string   "url",          limit: 255
    t.string   "support_url",  limit: 255
    t.string   "callback_url", limit: 255
    t.string   "key",          limit: 20
    t.string   "secret",       limit: 40
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "client_applications", ["key"], name: "index_client_applications_on_key", unique: true, using: :btree

  create_table "comments", force: :cascade do |t|
    t.string   "title",            limit: 50,  default: ""
    t.text     "comment",                      default: ""
    t.integer  "commentable_id"
    t.string   "commentable_type", limit: 255
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["commentable_id"], name: "index_comments_on_commentable_id", using: :btree
  add_index "comments", ["commentable_type"], name: "index_comments_on_commentable_type", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "gcps", force: :cascade do |t|
    t.integer  "map_id"
    t.float    "x"
    t.float    "y"
    t.decimal  "lat",                    precision: 15, scale: 10
    t.decimal  "lon",                    precision: 15, scale: 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "soft",                                             default: false
    t.string   "name",       limit: 255
  end

  add_index "gcps", ["soft"], name: "index_gcps_on_soft", using: :btree

  create_table "layer_properties", force: :cascade do |t|
    t.integer "layer_id"
    t.string  "name",     limit: 255
    t.text    "value"
    t.integer "level"
  end

  create_table "layers", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.text     "description"
    t.string   "catnyp",               limit: 255
    t.string   "uuid",                 limit: 255
    t.string   "parent_uuid",          limit: 255
    t.boolean  "is_visible",                                                default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "maps_count",                                                default: 0
    t.integer  "rectified_maps_count",                                      default: 0
    t.string   "bbox",                 limit: 255
    t.string   "depicts_year",         limit: 4,                            default: ""
    t.geometry "bbox_geom",            limit: {:srid=>0, :type=>"polygon"}
  end

  add_index "layers", ["bbox_geom"], name: "index_layers_on_bbox_geom", using: :gist

  create_table "map_layers", force: :cascade do |t|
    t.integer "map_id"
    t.integer "layer_id"
  end

  create_table "maps", force: :cascade do |t|
    t.string   "title",           limit: 255
    t.text     "description"
    t.string   "filename",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "content_type",    limit: 255
    t.string   "thumbnail",       limit: 255
    t.integer  "size"
    t.integer  "width"
    t.integer  "height"
    t.integer  "parent_id"
    t.string   "nypl_digital_id", limit: 255
    t.string   "catnyp",          limit: 255
    t.string   "uuid",            limit: 255
    t.string   "parent_uuid",     limit: 255
    t.integer  "status"
    t.integer  "mask_status"
    t.boolean  "map",                                                                            default: true
    t.string   "bbox",            limit: 255
    t.integer  "map_type"
    t.geometry "bbox_geom",       limit: {:srid=>0, :type=>"polygon"}
    t.decimal  "rough_lat",                                            precision: 15, scale: 10
    t.decimal  "rough_lon",                                            precision: 15, scale: 10
    t.geometry "rough_centroid",  limit: {:srid=>0, :type=>"point"}
    t.integer  "rough_zoom"
    t.integer  "rough_state"
    t.datetime "rectified_at"
    t.datetime "gcp_touched_at"
  end

  add_index "maps", ["bbox_geom"], name: "index_mapscans_on_bbox_geom", using: :gist
  add_index "maps", ["rough_centroid"], name: "index_mapscans_on_rough_centroid", using: :gist

  create_table "my_maps", force: :cascade do |t|
    t.integer  "map_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "my_maps", ["map_id", "user_id"], name: "index_my_maps_on_mapscan_id_and_user_id", unique: true, using: :btree
  add_index "my_maps", ["map_id"], name: "index_my_maps_on_mapscan_id", using: :btree

  create_table "oauth_nonces", force: :cascade do |t|
    t.string   "nonce",      limit: 255
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
    t.string   "callback_url",          limit: 255
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
    t.string   "name",       limit: 255
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "login",                     limit: 255
    t.string   "email",                     limit: 255
    t.string   "encrypted_password",        limit: 128, default: "",   null: false
    t.string   "password_salt",                         default: "",   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",            limit: 255
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

end
