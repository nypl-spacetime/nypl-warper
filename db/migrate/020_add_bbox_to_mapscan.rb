class AddBboxToMapscan < ActiveRecord::Migration
  def self.up
    add_column :mapscans, :bbox, :string
  end

  def self.down
    remove_column :mapscans, :bbox
  end
end
