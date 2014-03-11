namespace :map do
  namespace :repo do

    desc "Sets maps bibliographic item uuid from the nypl_digital_id using the NYPL Repo API if it doesnt have one already"

    task(:update_bibl_uuid => :environment) do
      desc "updates biblio_uuid for maps"
      puts "This will update the maps uuid based on the nypl_digital_id. This cannot be undone"
      puts "Are you sure you want to continue? [y/N]"
      break unless STDIN.gets.match(/^y$/i)
      count = 0
      unsuccessful = []
      repo_client = NyplRepo::Client.new(REPO_CONFIG[:token])
      Map.find(:all).each do |map|
        next unless map.bibl_uuid.nil?  #skip this if it has one already
        next if map.nypl_digital_id.nil?

        bibl_uuid = repo_client.get_bibl_uuid(map.nypl_digital_id.upcase)
        map.bibl_uuid = bibl_uuid
        map.save
        if count % 10 == 0
          STDOUT.print "\r" 
          STDOUT.print count 
          STDOUT.flush
        end
        unsuccessful << map.id if bibl_uuid.nil?
        count = count + 1
        sleep(3) if count % 1000 == 0
      end
      puts "Done " + count.to_s + " maps."
      puts "unsuccessful maps ("+unsuccessful.size.to_s+"):"
      puts unsuccessful.inspect
    end


    desc "Updates the mods_uuid of all maps based with no existing mods_uuid on the bibliographic uuid and the image id."
    task(:update_mods_uuid => :environment) do
      puts "This will update the mods_uuid of all maps. It needs a bibl_uuid first. This cannot be undone"
      puts "Are you sure you want to continue? [y/N]"
      break unless STDIN.gets.match(/^y$/i)
      count = 0
      broken = []

      repo_client = NyplRepo::Client.new(REPO_CONFIG[:token])
      Map.find(:all).each do |map|
        next unless map.mods_uuid.nil? #skip if it has one already
        
        if map.bibl_uuid
          mods_uuid = repo_client.get_mods_uuid(map.bibl_uuid, map.nypl_digital_id.upcase)
          if mods_uuid
            map.mods_uuid = mods_uuid
            map.save
          else
            broken << map.id
          end
        end

        sleep(10) if count % 100 == 0

        if count % 10 == 0
          STDOUT.print "\r"
          STDOUT.print count.to_s + " " 
          STDOUT.flush
        end

        count = count+ 1
      end
      puts "Done " + count.to_s + " maps."
      puts "unsuccessful maps ("+broken.size.to_s+"):"
      puts broken.inspect

    end

    ##
    ## NOTE: you should make sure that  Layer.update_all(:uuid => nil)
    ## is run before doing this, as it won't update layers with existing uuids
    ##  This fixed 280 layers out of 313
    ##
    desc "updates layers uuid based on the maps within them"
    task("layers_item_uuid" => :environment) do
      puts "This will update all the layers in the database. This cannot be undone"
      puts "Before running, make sure that the uuid of all layers have been set to nil"
      puts "Are you sure you want to continue? [y/N]"
      break unless STDIN.gets.match(/^y$/i)
      count = 0
      broken = []

      def update_layer(layer, related_item)
        #puts "update layers"
        #puts related_item["identifier"].inspect
        uuid = related_item["identifier"].detect{|a| a["type"] == "uuid"}["$"]

        layer.uuid = uuid
        layer.save!
      end
      
      def match_layers(layers, related_item)
        item_title = related_item["titleInfo"]["title"]["$"]

        layers.each do |layer|
          next unless layer.uuid.nil?

          identifier = related_item["identifier"]
          if identifier.class == Hash
            identifier = [identifier]
          end

          if layer.name.squish.start_with? item_title
            #p layer.name.squish + " :: "+ item_title
            #p "match title"
            update_layer(layer, related_item)

          elsif identifier.size > 0
            catnyp_prop = layer.layer_properties.detect {|a| a.name == "catnyp"}
            layer_catnyp = catnyp_prop.value unless catnyp_prop.nil?

            item_cat_prop = identifier.detect {|a| a["type"]=="local_catnyp"}
            item_catnyp = item_cat_prop["$"] unless item_cat_prop.nil?

            if layer_catnyp && layer_catnyp == item_catnyp
              update_layer(layer, related_item)
            else
               #p "no match " + layer.id.to_s
               
            end

          else
             #nowt
          end

        end

        if related_item["relatedItem"] && related_item["relatedItem"]["titleInfo"]
          match_layers(layers, related_item["relatedItem"])
        end
      
      end

      repo_client = NyplRepo::Client.new(REPO_CONFIG[:token])
      
      Map.find(:all).each do | map |
        if map.mods_uuid
          layers = map.layers
          next if layers.empty?
          
          next unless layers.find_all{|ll| ll.uuid.nil?}.length > 0 #skip unless there is more than one layer without a uuid
          
          map_item =  repo_client.get_mods_item(map.mods_uuid)

          if map_item.nil?
            broken << {map.id => map.mods_uuid}
            next
          end
          
          related_item = map_item["relatedItem"]
          if related_item.nil?
            broken << {map.id => "relateditem nil"}
            next
          end

          match_layers(layers, related_item) 

          sleep(10) if count % 100 == 0
          if count % 10 == 0
            STDOUT.print "\r"
            STDOUT.print count.to_s + " " 
            STDOUT.flush
          end

          count = count+1
        end
      end #Map.all

      puts "unsuccessful maps ("+broken.size.to_s+"):"
      puts "Done " + count.to_s + " maps."


    end


  end
end

