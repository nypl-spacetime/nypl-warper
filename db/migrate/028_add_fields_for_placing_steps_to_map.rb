class AddFieldsForPlacingStepsToMap < ActiveRecord::Migration
  def self.up
    add_column :mapscans, :rough_lat, :decimal, :precision => 15, :scale => 10
    add_column :mapscans,  :rough_lon, :decimal, :precision => 15, :scale => 10

    add_column :mapscans, :rough_centroid, :st_point, :srid => 4326
    add_index :mapscans, :rough_centroid, :using => :gist

    add_column :mapscans, :rough_zoom, :integer
    add_column :mapscans, :rough_state, :integer
  end

  def self.down
    remove_column :mapscans, :rough_lat
    remove_column :mapscans, :rough_lon

    remove_index :mapscans, :rough_centroid
    remove_column :mapscans, :rough_centroid


    remove_column :mapscans, :rough_zoom
    remove_column :mapscans, :rough_state

  end
end
