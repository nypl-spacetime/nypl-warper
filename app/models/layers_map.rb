class LayersMap < ActiveRecord::Base
  def self.table_name()
 "map_layers"
end
  belongs_to :layer
  belongs_to :map

  validates_uniqueness_of :layer_id, :scope => :map_id, :message => "already has this map"
end
