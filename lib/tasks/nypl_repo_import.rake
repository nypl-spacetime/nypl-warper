namespace :map do
  namespace :repo do

    #creates a map object from an item
    #optionally pass in image_id if you know it
    def get_map(item, uuid, image_id=nil)
      title = item["titleInfo"].select{|a|a["usage"]=="primary"}.last["title"]["$"] if item["titleInfo"].class == Array
      title = item["titleInfo"]["title"]["$"] if item["titleInfo"].class == Hash
      extra = item["note"].detect{|a| a["type"]=="statement of responsibility"} if item["note"] && item["note"].class == Array
      extra = item["note"]["statement of responsibility"] if item["note"].class == Hash && item["note"]["statement of responsibility"]
      
      extra_title = extra.nil? ? "" : " / " + extra["$"]
      title = title + extra_title

      #truncate long titles
      title = (title.chars.to_a.size > 254 ? title.chars.to_a[0...251].join + "..." : title).to_s
      
      #relatedItem for :
      identifier =  item["relatedItem"]["identifier"]
      if identifier.class == Hash
        identifier = [identifier]
      end
      parent_uuid = identifier.detect{|a| a["type"]=="uuid"}["$"]
      description = "From " + item["relatedItem"]["titleInfo"]["title"]["$"]
      description = (description.chars.to_a.size > 254 ? description.chars.to_a[0...251].join + "..." : description).to_s

      
      #go into layers to find:
      client = NyplRepo::Client.new(REPO_CONFIG[:token])
      
      nypl_digital_id = image_id || client.get_image_id(parent_uuid, uuid)

      map = Map.new(:title => title, :description => description,
                    :uuid => uuid, :parent_uuid => parent_uuid,
                    :nypl_digital_id => nypl_digital_id,
                    :status => :unloaded, :map_type=>:is_map, :mask_status => :unmasked)
      
      map
    end

    def get_layer(related_item)
      identifier =  related_item["identifier"]
      if identifier.class == Hash
        identifier = [identifier]
      end
      uuid = identifier.detect{|a| a["type"]=="uuid"}["$"]
      title = related_item["titleInfo"]["title"]["$"]
      title = (title.chars.to_a.size > 254 ? title.chars.to_a[0...251].join + "..." : title).to_s

      layer = Layer.new(:name => title, :uuid => uuid, :description => "")
      #TODO - parse originInfo date issued keydate=yes
      match_data = /1[3456789][0-9][0-9]/.match title
      if match_data
        layer.depicts_year = match_data[0]
      end
      layer
    end
    
    def get_layers(related_item)
      layers = []
      layers << get_layer(related_item) 
      if related_item["relatedItem"] && related_item["relatedItem"]["titleInfo"]
        layers << get_layers(related_item["relatedItem"])
      end

      layers
    end

    def update_layer_counts
      puts "Updating layer counts...."
      Layer.all.each do | layer |
        layer.update_counts
      end
    end

    #saves a map if it's new and with associated layers to that map
    def save_map_with_layers(map, layers)
      ActiveRecord::Base.transaction do
        #1 save map
        if map.new_record?
          #
          # This is a check for records where they have the digital id but the API is unable to find it
          # So there uuids were not updated
          #
          if Map.exists?(:nypl_digital_id => map.nypl_digital_id)
            existing_map = Map.find_by_nypl_digital_id(map.nypl_digital_id)
            if existing_map.uuid.nil?
              existing_map.uuid = map.uuid
              existing_map.parent_uuid = map.parent_uuid
              existing_map.save
              puts "Updated existing map: "+ existing_map.inspect
            end
            map = existing_map

          else #map  is really new now
          
          map.save
          puts "Saved new Map: " + map.inspect
        
          end #already exists?
        end #new record

        #2 save new  or get layers
        assign_layers = []
        layers.each do | layer |
          if Layer.exists?(:uuid => layer.uuid)
            #the layer exists
            layer = Layer.find_by_uuid(layer.uuid)
            unless LayersMap.exists?(:map_id => map.id, :layer_id => layer.id) 
              #layer exists, but the map is not in the relationship
              assign_layers << layer
            end

          else
            #the layer does not exist, create is as  new Layer
            if layer.new_record?
              layer.save
              puts "Saved new Layer: "+ layer.inspect
            end
            assign_layers << layer
          end
        end
        #3 then set the map to the layer
        map.layers << assign_layers 

      end #transaction

    end


    desc "imports a map and any associated layer based on a uuid environment variable"
    task(:import_map => :environment) do
      unless ENV["uuid"]
        puts "usage: rake map:repo:import_map uuid=uuid"
        break
      end
      uuid = ENV["uuid"]

      if Map.exists?(:uuid => uuid)
        map = Map.find_by_uuid(uuid)
        puts "Map #{map.id.to_s} with uuid #{uuid} exists."
        break
      end

      client = NyplRepo::Client.new(REPO_CONFIG[:token])
      item = client.get_mods_item(uuid)
      
      map = get_map(item, uuid)
      layers = get_layers(item["relatedItem"]) 
      layers.flatten! 
      
      save_map_with_layers(map,layers)
      update_layer_counts

    end #task



    desc "imports a layer / collection of maps, based on uuid of layer id"
    task(:import_layer => :environment) do
      unless ENV["uuid"]
        puts "usage: rake map:repo:import_layer uuid=uuid"
        break
      end
      uuid = ENV["uuid"]
      client = NyplRepo::Client.new(REPO_CONFIG[:token], true)
      map_items = client.get_capture_items(uuid)
      # the above call only gets the items with image AND highreslink (true, true)
      map_items.each do | map_item |
        if map_item["imageID"].nil? || map_item["highResLink"].nil?
          puts "Missing ImageID or highResLink: "+ map_item["uuid"]
          next
        end

        item = client.get_mods_item(map_item["uuid"])

        if Map.exists?(:uuid => map_item["uuid"])
          map = Map.find_by_uuid(map_item["uuid"])
        else
          map = get_map(item, map_item["uuid"], map_item["imageID"])
        end
        
        layers = get_layers(item["relatedItem"]) 
        layers.flatten! 
        
        save_map_with_layers(map,layers)
      end

      update_layer_counts
    end



    desc "Imports new maps (with highreslinks and imageids) and associated layers from a date to a date.  Date to be in YYYY-MM-DD"
    task(:import_latest => :environment) do
      unless ENV["since"] && ENV["until"]
        puts "usage: rake map:repo:import_latest since=date until=date"
        break
      end
      since_date = ENV["since"] 
      until_date = ENV["until"]
      client = NyplRepo::Client.new(REPO_CONFIG[:token], true)
      map_items = client.get_items_since("%22Map%20Division%22&field=physicalLocation", since_date, until_date)
      
      if map_items == [nil]
        puts "No items found!"
      end

      map_items.each do | map_item |
        next if map_item.nil? 
        next if map_item["imageID"].nil?
    
        item = client.get_mods_item(map_item["uuid"])

        if Map.exists?(:uuid => map_item["uuid"])
          map = Map.find_by_uuid(map_item["uuid"])
        else
          map = get_map(item, map_item["uuid"], map_item["imageID"])
        end

        #TODO - possible problem with the API here. no highResLink in results
        #workaround starts
        highResLink = client.get_highreslink(map.bibl_uuid, map.nypl_digital_id)
        next if highResLink.nil?
        
        layers = get_layers(item["relatedItem"]) 
        layers.flatten! 
        
        save_map_with_layers(map,layers)

      end #map_items

      update_layer_counts
    end #task

  end
end
