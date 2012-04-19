class AddSpatialBboxGeomColumnToMapscans < ActiveRecord::Migration
  def self.up
    add_column :mapscans, :bbox_geom, :polygon 
    add_index :mapscans, :bbox_geom, :spatial => true
    say "added column and index, now updating maps" 
    Map.reset_column_information
    Map.find(:all).each do | map |
      map.update_bbox
      sleep(0.05)
    end
    say "all done!"
  end

  def self.down
    remove_column :mapscans, :bbox_geom
    remove_index :mapscans, :bbox_geom
  end
end
