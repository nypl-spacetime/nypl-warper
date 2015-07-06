class Import < ActiveRecord::Base
  belongs_to :user, :class_name => "User"

  acts_as_enum :status, [:ready, :running, :finished, :failed]
  acts_as_enum :import_type, [:map, :layer, :latest]

  validate :presence_of_a_param
  validate :validate_correct_import_type
  validates_presence_of :since_date, :if => (:until_date?)
  validates_presence_of :until_date, :if => (:since_date?)
  
  validates_format_of :since_date, :with => /\d{4}-\d{2}-\d{2}/, :message => "must be in the following format: YYYY-MM-DD", :allow_blank => true
  validates_format_of :until_date, :with => /\d{4}-\d{2}-\d{2}/, :message => "must be in the following format: YYYY-MM-DD", :allow_blank => true

  after_initialize :default_values
  
  after_destroy :delete_logfile

  def presence_of_a_param
    unless [uuid?, since_date?, until_date?].include?(true)
      errors.add :base, 'You need at least a uuid or since or until'
    end
  end

  def validate_correct_import_type
    if [:map, :layer].include?(import_type) && uuid.blank?
      errors.add :base, 'You need to add a uuid for map and layer types'
    end
    if import_type == :latest && (since_date.blank? || until_date.blank?)
      errors.add :base, 'You need to add since_date and until_date for latest import type'
    end
  end

  def default_values
    self.status ||= :ready
    self.import_type ||= :map 
  end
  
  def logfile
    "import-#{import_type}-#{id}-#{Time.new.strftime('%Y-%m-%d-%H%M%S')}.log"
  end

  def import_logger
    @import_logger ||= Logger.new("#{Rails.root}/log/#{log_filename}")
  end

  def prepare_run
    self.update_attribute(:status, :running)
    self.update_attribute(:log_filename, logfile)
  end

  def import!(async=false)

    if valid?
      
      unless async
        prepare_run
      end
      
      puts "Starting import. Logging in log/#{log_filename}"  if defined? Rake
      import_logger.info "Stared import #{Time.now}"
      begin
        if import_type == :map
          import_map
          finish_import
        elsif import_type == :layer
          import_layer
          finish_import
        elsif import_type == :latest
          import_latest
          finish_import
        end
      rescue Exception => e
        puts "error with import #{e.inspect}" if defined? Rake
        import_logger.error "error with import."
        import_logger.error e.inspect
        
        self.status = :failed
        self.save
      end
      
      self.status

    end
  end

  def finish_import
    self.status = :finished
    self.finished_at = Time.now
    self.save

    import_logger.info "Finished import #{Time.now}"
  end

  def import_map
    if Map.exists?(:uuid => uuid)
      map = Map.find_by_uuid(uuid)
      import_logger.warn "Map #{map.id.to_s} with uuid #{uuid} exists."
      puts "Map #{map.id.to_s} with uuid #{uuid} exists." if defined? Rake
    else
      
      client = NyplRepo::Client.new(REPO_CONFIG[:token], true, import_logger)
      item = client.get_mods_item(uuid)
      
      map = get_map(item, uuid)
      if map.nil?
        import_logger.warn "not saving"
      else
        layers = get_layers(item["relatedItem"]) 
        layers.flatten! 

        save_map_with_layers(map,layers)
        update_layer_counts
      end
    end

  end


  def import_layer
    client = NyplRepo::Client.new(REPO_CONFIG[:token], true, import_logger)
    map_items = client.get_capture_items(uuid)
    # the above call only gets the items with image AND highreslink (true, true)
    map_items.each do | map_item |
      if map_item["imageID"].nil? || map_item["highResLink"].nil?
        import_logger.warn "Missing ImageID or highResLink: "+ map_item["uuid"]
        next
      end

      item = client.get_mods_item(map_item["uuid"])

      if Map.exists?(:uuid => map_item["uuid"])
        map = Map.find_by_uuid(map_item["uuid"])
      else
        map = get_map(item, map_item["uuid"], map_item["imageID"])
      end
      next if map.nil?
      
      layers = get_layers(item["relatedItem"]) 
      layers.flatten! 
      save_map_with_layers(map,layers)
    end

    update_layer_counts
  end

  def count_latest
    client = NyplRepo::Client.new(REPO_CONFIG[:token])
      
    count = client.count_items_since("%22Map%20Division%22&field=physicalLocation", since_date, until_date)
      
    count.to_i
  end


  def import_latest
    client = NyplRepo::Client.new(REPO_CONFIG[:token], true, import_logger) 
    map_items = client.get_items_since("%22Map%20Division%22&field=physicalLocation", since_date, until_date)
    
    if map_items == [nil]
      import_logger.warn "No items found!"
      puts "No items found!" if defined? Rake
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
      next if map.nil?
      
      #TODO - possible problem with the API here. no highResLink in results
      #workaround starts
      highResLink = client.get_highreslink(map.bibl_uuid, map.nypl_digital_id)
      next if highResLink.nil?
        
      layers = get_layers(item["relatedItem"]) 
      layers.flatten! 
       
      save_map_with_layers(map,layers)

    end #map_items

    update_layer_counts
  end



  private
  def deep_find(key, object=self, found=nil)
    if object.respond_to?(:key?) && object.key?(key)
      return object
    elsif object.is_a? Enumerable
      object.find { |*a| found = deep_find(key, a.last) }
      return found
    end
  end

    
  #creates a map object from an item
  #optionally pass in image_id if you know it
  def get_map(item, uuid, image_id=nil)
    import_logger.info "get map"
    title = item["titleInfo"].select{|a|a["usage"]=="primary"}.last["title"]["$"] if item["titleInfo"].class == Array
    title = item["titleInfo"]["title"]["$"] if item["titleInfo"].class == Hash
    extra = item["note"].detect{|a| a["type"]=="statement of responsibility"} if item["note"] && item["note"].class == Array
    extra = item["note"]["statement of responsibility"] if item["note"].class == Hash && item["note"]["statement of responsibility"]
      
    extra_title = extra.nil? ? "" : " / " + extra["$"]
    title = title + extra_title

    #truncate long titles
    title = (title.chars.to_a.size > 254 ? title.chars.to_a[0...251].join + "..." : title).to_s
      
    #relatedItem for :
    if item["relatedItem"].nil? || item["relatedItem"]["identifier"].nil?
      import_logger.warn "No relatedItem or Identifier found for #{uuid}"
      return nil
    end
    identifier =  item["relatedItem"]["identifier"]
    if identifier.class == Hash
      identifier = [identifier]
    end
    parent_uuid = identifier.detect{|a| a["type"]=="uuid"}["$"]
    description = "From " + item["relatedItem"]["titleInfo"]["title"]["$"]
    description = (description.chars.to_a.size > 254 ? description.chars.to_a[0...251].join + "..." : description).to_s

    origin_info = item["originInfo"]
 
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

    #go into layers to find:
    client = NyplRepo::Client.new(REPO_CONFIG[:token], true, import_logger)
      
    nypl_digital_id = image_id || client.get_image_id(parent_uuid, uuid)

    map = Map.new(:title => title, :description => description,
      :uuid => uuid, :parent_uuid => parent_uuid,
      :nypl_digital_id => nypl_digital_id,
      :issue_year => issue_year,
      :status => :unloaded, :map_type=>:is_map, :mask_status => :unmasked)
      
    map
  end
  
  #cleans the date string and returns int
  def clean_date(date_string)
    date_string.gsub!(/\?/ ,'')
    if (date_string.length == 3  || date_string.length == 4) && date_string.end_with?("-")
      date_string.gsub!(/-/ ,'0')
    elsif date_string.start_with?("-") || (date_string.length >= 5 && date_string.end_with?("-"))
      date_string.gsub!(/-/ ,'')
    end
    date_string.gsub!(/[^0-9]/, '')
    date_string.gsub!(/\[|\]/ ,'')
    
    date_string.to_i
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
    import_logger.info "Updating layer counts...."
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
            import_logger.info "Updated existing map: "+ existing_map.inspect

          end
          map = existing_map

        else #map  is really new now
          
          map.save
          import_logger.info "Saved new Map: " + map.inspect
        
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
            import_logger.info "Saved new Layer: "+ layer.inspect
          end
          assign_layers << layer
        end
      end
      #3 then set the map to the layer
      map.layers << assign_layers 

    end #transaction

  end
 
  def delete_logfile
    if log_filename && log_filename.include?(".log") && File.exists?("#{Rails.root}/log/#{log_filename}")
      File.delete("#{Rails.root}/log/#{log_filename}")
    end
  end




end
