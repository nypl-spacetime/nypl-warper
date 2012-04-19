class AddMaskingStatusFieldToMapscans < ActiveRecord::Migration
  def self.up
    add_column :mapscans, :mask_status, :integer
  end

  def self.down
    remove_column :mapscans, :mask_status
  end
end
