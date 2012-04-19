class MapLayer < ActiveRecord::Base
def self.table_name()
 "mapscan_layers"
end
belongs_to :layer
belongs_to :map, :foreign_key => "mapscan_id"
end
