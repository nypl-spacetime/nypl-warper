namespace :map do
  namespace :repo do

    def deep_find(key, object=self, found=nil)
      if object.respond_to?(:key?) && object.key?(key)
        return object
      elsif object.is_a? Enumerable
        object.find { |*a| found = deep_find(key, a.last) }
        return found
      end
    end
    
      #cleans the date string and returns int
    def clean_date(date_string)
      date_string.gsub!(/\?/ ,'')
      if (date_string.length == 3  || date_string.length == 4) && date_string.end_with?("-")
        date_string.gsub!(/-/ ,'0')
      elsif date_string.start_with?("-") || (date_string.length >= 5 && date_string.end_with?("-"))
        date_string.gsub!(/-/ ,'')
      end
      date_string.gsub!(/\[|\]/ ,'')

      date_string.to_i
    end
                  
    
    desc "imports a map and any associated layer based on a uuid environment variable"
    task(:import_map => :environment) do
      unless ENV["uuid"]
        puts "usage: rake map:repo:import_map uuid=uuid"
        break
      end
      uuid = ENV["uuid"]

      import = Import.new(:uuid => uuid, :import_type => :map)
      if import.valid?
        import.import!
      else
        puts "Invalid import. errors were: #{import.errors.messages}"
      end
      
    end #task



    desc "imports a layer / collection of maps, based on uuid of layer id"
    task(:import_layer => :environment) do
      unless ENV["uuid"]
        puts "usage: rake map:repo:import_layer uuid=uuid"
        break
      end
      uuid = ENV["uuid"]

      import = Import.new(:uuid => uuid, :import_type => :layer)

      if import.valid?
        import.import!
      else
        puts "Invalid import. errors were: #{import.errors.messages}"
      end
    end



    desc "Imports new maps (with highreslinks and imageids) and associated layers from a date to a date.  Date to be in YYYY-MM-DD"
    task(:import_latest => :environment) do
      unless ENV["since"] && ENV["until"]
        puts "usage: rake map:repo:import_latest since=date until=date"
        break
      end
      since_date = ENV["since"] 
      until_date = ENV["until"]
      import = Import.new(:import_type => :latest, :since_date => since_date, :until_date => until_date)
      if import.valid?
        import.import!
      else
        puts "Invalid import. errors were: #{import.errors.messages}"
      end
      

    end #task
    
    desc "Counts the number of items from the repository. Date to be in YYYY-MM-DD"
    task(:count_latest => :environment) do
      unless ENV["since"] && ENV["until"]
        puts "usage: rake map:repo:count_latest since=date until=date"
        break
      end
      since_date = ENV["since"] 
      until_date = ENV["until"]
      client = NyplRepo::Client.new(REPO_CONFIG[:token], true)
      
      count = client.count_items_since("%22Map%20Division%22&field=physicalLocation", since_date, until_date)
      
      if count == "0"
        puts "No items found."
      else
        puts "#{count} items found."
      end
      
    end
    
    
    desc "updates maps issue_year from the API if the map hasn't got one already."
    task(:update_map_year => :environment) do
      puts "[#{Time.now}] map:repo:update_map_year started. "
      maps = Map.where("uuid <> '' AND issue_year is null") 
      broken = []
      not_found = []
      client = NyplRepo::Client.new(REPO_CONFIG[:token], true)
      
      maps.each do | map |
        
        map_item =  client.get_mods_item(map.uuid)
        
        if map_item.nil?
          broken << {map.id => map.uuid}
          next
        end
        
        origin_info = map_item["originInfo"]
        
        if origin_info.class == Hash
          origin_info = [origin_info]
        end
        
        key_date = deep_find("keyDate", origin_info)
        
        issue_year = nil
        
        if key_date && key_date["$"]
          issue_year = clean_date(key_date["$"])
        end
        
        if issue_year.nil?
          other_date = nil
          ["dateIssued","dateCreated", "copyrightDate" , "dateModified"].each do | other_key |
            other_date = deep_find(other_key, origin_info)
            
            if other_date
              other_date_year = deep_find("$", other_date)
              issue_year = clean_date(other_date_year["$"])
              
              break
            end
            
          end 
        end
        
        if issue_year.nil?
          not_found << {map.id => map.uuid}
        else
          puts "Updating #{map.uuid}  : #{issue_year}"
          map.update_attribute(:issue_year, issue_year)
        end
        
      end
      
      
      if broken.size > 0
        puts "No repo API item found for these maps:  "
        puts broken.inspect
      end
      
      if not_found.size > 0
        puts "No issue year found for these maps "
        puts not_found.inspect
      end
      
       puts "[#{Time.now}] map:repo:update_map_year finished. "
       
    end
    
  end
end
