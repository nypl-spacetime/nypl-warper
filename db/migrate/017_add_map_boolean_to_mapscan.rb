class AddMapBooleanToMapscan < ActiveRecord::Migration
  def self.up
    add_column :mapscans, :map, :boolean, :default => true
    Map.update_all(:map => true)
  end

  def self.down
    remove_column :mapscans, :map
  end
end
