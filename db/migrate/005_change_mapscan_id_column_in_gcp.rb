class ChangeMapscanIdColumnInGcp < ActiveRecord::Migration
  def self.up
  rename_column "gcps", "map_id", "mapscan_id" 
  end

  def self.down
   rename_column "gcps", "mapscan_id", "map_id"
  end
end
