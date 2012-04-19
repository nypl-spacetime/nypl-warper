class Gcp < ActiveRecord::Base
  
  def self.table_name()
    "gcps"
  end

  belongs_to :map, :foreign_key => "mapscan_id"

  acts_as_audited 
  validates_numericality_of :x, :y, :lat, :lon
  validates_presence_of :x, :y, :lat, :lon, :mapscan_id

  named_scope  :soft, :conditions => {:soft => true}
  named_scope  :hard, :conditions => ["gcps.soft IS NULL OR gcps.soft = 'F'"]

  after_save :update_map_timestamp
  after_destroy :update_map_timestamp

  attr_accessor :error

  def gdal_string
	
    gdal_string = " -gcp " + x.to_s + ", " + y.to_s + ", " + lon.to_s + ", " + lat.to_s

  end

  private
  def update_map_timestamp
    self.map.update_gcp_touched_at
  end

end


