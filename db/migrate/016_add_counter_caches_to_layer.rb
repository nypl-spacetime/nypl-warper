class AddCounterCachesToLayer < ActiveRecord::Migration
  def self.up
    add_column :layers, :mapscans_count, :integer, :default => 0
    Layer.reset_column_information
    def Layer.readonly_attributes; nil end #evil hack

    Layer.find(:all).each do |l|
      l.mapscans_count = l.mapscans.count
      l.save!
    end

    add_column :layers, :rectified_mapscans_count, :integer, :default=> 0
    Layer.reset_column_information
    def Layer.readonly_attributes; nil end #evil hack
    Layer.find(:all).each do |l|
      l.rectified_mapscans_count = l.mapscans.count(:conditions => ["status = 4"])
      l.save!
    end
  end

  def self.down
    remove_column :layers, :mapscans_count
    remove_column :layers, :rectified_mapscans_count
  end
end
