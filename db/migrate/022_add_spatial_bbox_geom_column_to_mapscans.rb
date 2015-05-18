class AddSpatialBboxGeomColumnToMapscans < ActiveRecord::Migration
  def self.up
    add_column :mapscans, :bbox_geom, :st_polygon, :srid => 4326
    add_index :mapscans, :bbox_geom, :using => :gist
  end

  def self.down
    remove_column :mapscans, :bbox_geom
    remove_index :mapscans, :bbox_geom
  end
end
