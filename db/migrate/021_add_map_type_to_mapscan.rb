class AddMapTypeToMapscan < ActiveRecord::Migration
  def self.up
    add_column :mapscans, :map_type, :integer

    # 0  = index , 1 = map 2 = not a map (see Mapscan model)
    # is_map
    Map.update_all("map_type = 1", "map = true")
    
    #not map
    Map.update_all("map_type = 2", "map = false")

  end

  def self.down
    remove_column :mapscans, :map_type
  end
end
