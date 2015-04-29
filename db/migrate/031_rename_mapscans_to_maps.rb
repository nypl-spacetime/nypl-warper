class RenameMapscansToMaps < ActiveRecord::Migration
  def self.up
    rename_table :mapscans, :maps
   
    rename_table :mapscan_layers, :map_layers
    rename_column :map_layers, :mapscan_id, :map_id
    
    rename_column :gcps, :mapscan_id, :map_id
    
    rename_column :layers, :mapscans_count, :maps_count
    rename_column :layers, :rectified_mapscans_count, :rectified_maps_count

    rename_column :my_maps, :mapscan_id, :map_id
    
  end
  
  def self.down
    rename_table :maps, :mapscans
    rename_table :map_layers, :mapscan_layers
    
    rename_column :mapscan_layers, :map_id, :mapscan_id
    
    rename_column :gcps, :map_id, :mapscan_id 
    
    rename_column :layers, :maps_count, :mapscans_count 
    rename_column :layers, :rectified_maps_count, :rectified_mapscans_count

    rename_column :my_maps,  :map_id, :mapscan_id
    
  end
end
