class CreateLayers < ActiveRecord::Migration
  def self.up
    create_table "layers" do |t|
      t.string   :name
      t.text     :description
      t.string   :catnyp
      t.string   :uuid
      t.string   :parent_uuid
      t.boolean  :is_visible, :default => true
      t.datetime :depicts_year
      t.datetime :created_at
      t.datetime :updated_at
      t.timestamps     
    end
    create_table "layer_properties" do |t|
      t.integer :layer_id     
      t.string  :name
      t.text    :value
      t.integer :level     
    end
    create_table "mapscan_layers" do |t|
      t.integer :mapscan_id
      t.integer :layer_id
    end
  end

  def self.down
    drop_table "layers"
    drop_table "layer_properties"
    drop_table "mapscan_layers"
  end
end
