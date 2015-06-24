class Gcp < ActiveRecord::Base
  belongs_to :map
 
  has_paper_trail
  
  validates_numericality_of :x, :y, :lat, :lon
  validates_presence_of :x, :y, :lat, :lon, :map_id
  
  scope :soft, -> { where(:soft => true)}
  scope :hard, -> { where('soft IS NULL OR soft = ?', false) }
  
  attr_accessor :error
  
  after_update  {|gcp| gcp.map.paper_trail_event = 'gcp_update'  }
  after_create  {|gcp| gcp.map.paper_trail_event = 'gcp_create'  }
  
  after_save :touch_map
  
  after_destroy {|gcp| gcp.map.paper_trail_event = 'gcp_delete' if gcp.map  }
  after_destroy :touch_map
  
  
  def gdal_string
	
    gdal_string = " -gcp " + x.to_s + ", " + y.to_s + ", " + lon.to_s + ", " + lat.to_s

  end
  
 private
  def touch_map
    self.map.touch_with_version(:gcp_touched_at) if self.map
  end
  

end
