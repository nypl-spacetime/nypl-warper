class NyplRepo

  #get the item detail from a uuid
  def self.get_mods_item(mods_uuid)
    url = "http://api.repo.nypl.org/api/v1/items/mods/#{mods_uuid}.json"
    json = self.get_json(url)
    
    item = nil
    if json["nyplAPI"]["response"]["mods"]
      item = json["nyplAPI"]["response"]["mods"]
    end

    return item
  end

  #gets the mods uuid of the item, passing in the bibliographic uuid and image_id
  #since there could be many maps for the same item
  def self.get_mods_uuid(bibl_uuid, image_id)
   url = "http://api.repo.nypl.org/api/v1/items/#{bibl_uuid}.json?per_page=500"
   json = self.get_json(url)
   mods_uuid = nil
 puts url
   json["nyplAPI"]["response"]["capture"].each do | capture|
     if capture["imageID"] == image_id
       mods_uuid = capture["uuid"]
       break
     end #if
   end if json["nyplAPI"]["response"]["numResults"].to_i > 0


   return mods_uuid
  end


  # get bibliographic container uuid from an image_id
  def self.get_bibl_uuid(image_id)
    url = "http://api.repo.nypl.org/api/v1/items/local_image_id/#{image_id}.json"   
    json = self.get_json(url)
    bibl_uuid = nil
    if json["nyplAPI"]["response"]["numResults"].to_i > 0
      bibl_uuid = json["nyplAPI"]["response"]["uuid"]
    end
   
    return bibl_uuid
  end


  #get highreslink from an item, matching up the image idi
  #since some bibliographic items may have many maps under them
  def self.get_highreslink(bibl_uuid, image_id)
    url = "http://api.repo.nypl.org/api/v1/items/#{bibl_uuid}.json?per_page=500"
    json = self.get_json(url)
    
    highreslink = nil

    json["nyplAPI"]["response"]["capture"].each do | capture|
      if capture["imageID"] == image_id
        highreslink = capture["highResLink"]
        break 
      end #if
    end if json["nyplAPI"]["response"]["numResults"].to_i > 0 

    return highreslink
  end

  def self.get_token
    return REPO_CONFIG[:token]
  end


  def self.get_json(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)

    headers = { "Authorization" => "Token token=#{REPO_CONFIG[:token]}" }
    request = Net::HTTP::Get.new(uri.request_uri, headers)
    response = http.request(request)
    body = response.body
    json = JSON.parse(body)

    return json
  end


end
