class AddGcpTouchedAtAndLastRectifiedToMap < ActiveRecord::Migration
  def self.up
    add_column :mapscans, :rectified_at, :datetime
    add_column :mapscans, :gcp_touched_at, :datetime
  end

  def self.down
    remove_column :mapscans, :rectified_at
    remove_column :mapscans, :gcp_touched_at
  end
end
