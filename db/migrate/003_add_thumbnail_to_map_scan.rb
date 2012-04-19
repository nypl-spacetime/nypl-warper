class AddThumbnailToMapScan < ActiveRecord::Migration
  def self.up
  add_column :mapscans, :parent_id, :integer
  end

  def self.down
  remove_column :mapscans, :parent_id
  end
end
