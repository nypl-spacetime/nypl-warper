class MapLayer < ActiveRecord::Base
def self.table_name()
 "map_layers"
end
belongs_to :layer
belongs_to :map, :foreign_key => "map_id"
validates_uniqueness_of :layer_id, :scope => :map_id, :message => "Layer already has this map"

end
