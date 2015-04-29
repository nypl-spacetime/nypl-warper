# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 30) do

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "action"
    t.text     "changes"
    t.integer  "version",        :default => 0
    t.datetime "created_at"
  end

  add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"
  add_index "audits", ["created_at"], :name => "index_audits_on_created_at"
  add_index "audits", ["user_id", "user_type"], :name => "user_index"

  create_table "client_applications", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.string   "support_url"
    t.string   "callback_url"
    t.string   "key",          :limit => 20
    t.string   "secret",       :limit => 40
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "client_applications", ["key"], :name => "index_client_applications_on_key", :unique => true

  create_table "comments", :force => true do |t|
    t.string   "title",            :limit => 50, :default => ""
    t.text     "comment",                        :default => ""
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["commentable_id"], :name => "index_comments_on_commentable_id"
  add_index "comments", ["commentable_type"], :name => "index_comments_on_commentable_type"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "gcps", :force => true do |t|
    t.integer  "mapscan_id"
    t.float    "x"
    t.float    "y"
    t.decimal  "lat",        :precision => 15, :scale => 10
    t.decimal  "lon",        :precision => 15, :scale => 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "soft",                                       :default => false
    t.string   "name"
  end

  add_index "gcps", ["soft"], :name => "index_gcps_on_soft"

  create_table "layer_properties", :force => true do |t|
    t.integer "layer_id"
    t.string  "name"
    t.text    "value"
    t.integer "level"
  end

  create_table "layers", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "catnyp"
    t.string   "uuid"
    t.string   "parent_uuid"
    t.boolean  "is_visible",                            :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mapscans_count",                        :default => 0
    t.integer  "rectified_mapscans_count",              :default => 0
    t.string   "bbox"
    t.string   "depicts_year",             :limit => 4, :default => ""
    t.polygon  "bbox_geom",                                               :srid => 0
  end

  add_index "layers", ["bbox_geom"], :name => "index_layers_on_bbox_geom", :spatial => true

  create_table "mapscan_layers", :force => true do |t|
    t.integer "mapscan_id"
    t.integer "layer_id"
  end

  create_table "mapscans", :force => true do |t|
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
    t.boolean  "map",                                             :default => true
    t.string   "bbox"
    t.integer  "map_type"
    t.polygon  "bbox_geom",                                                         :srid => 0
    t.decimal  "rough_lat",       :precision => 15, :scale => 10
    t.decimal  "rough_lon",       :precision => 15, :scale => 10
    t.point    "rough_centroid",                                                    :srid => 0
    t.integer  "rough_zoom"
    t.integer  "rough_state"
    t.datetime "rectified_at"
    t.datetime "gcp_touched_at"
  end

  add_index "mapscans", ["bbox_geom"], :name => "index_mapscans_on_bbox_geom", :spatial => true
  add_index "mapscans", ["rough_centroid"], :name => "index_mapscans_on_rough_centroid", :spatial => true

  create_table "my_maps", :force => true do |t|
    t.integer  "mapscan_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "my_maps", ["mapscan_id", "user_id"], :name => "index_my_maps_on_mapscan_id_and_user_id", :unique => true
  add_index "my_maps", ["mapscan_id"], :name => "index_my_maps_on_mapscan_id"

  create_table "oauth_nonces", :force => true do |t|
    t.string   "nonce"
    t.integer  "timestamp"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_nonces", ["nonce", "timestamp"], :name => "index_oauth_nonces_on_nonce_and_timestamp", :unique => true

  create_table "oauth_tokens", :force => true do |t|
    t.integer  "user_id"
    t.string   "type",                  :limit => 20
    t.integer  "client_application_id"
    t.string   "token",                 :limit => 20
    t.string   "secret",                :limit => 40
    t.string   "callback_url"
    t.string   "verifier",              :limit => 20
    t.datetime "authorized_at"
    t.datetime "invalidated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_tokens", ["token"], :name => "index_oauth_tokens_on_token", :unique => true

  create_table "permissions", :force => true do |t|
    t.integer  "role_id",    :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.string   "password_reset_code",       :limit => 40
    t.boolean  "enabled",                                 :default => true
    t.integer  "updated_by"
    t.text     "description",                             :default => ""
  end

end
