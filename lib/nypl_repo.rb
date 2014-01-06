module NyplRepo

  class Client
   require 'uri'
   require 'net/http'
   require 'json'
   
    def initialize(token)
      @token = token
    end
 
    #date format: YYYY-MM-DD
    #physical_location  i.e "Map%20Division"&field=physicalLocation
    def get_items_since(query, since, untildate)
      url = 'http://api.repo.nypl.org/api/v1/items/search.json?q='+query+'&since='+since+'&until='+untildate+'&per_page=500'
      json = self.get_json(url)
      results = []
      result = json["nyplAPI"]["response"]["result"]
      results << result
      totalPages = json["nyplAPI"]["request"]["totalPages"].to_i
      
      if totalPages >= 2
        (2..totalPages).each do | page |
          newurl = url + "&page=#{page}"
          json = self.get_json(newurl)
          newresult = json["nyplAPI"]["response"]["result"]
          results << newresult
        end
      end
      results.flatten!
     
      results
    end


    # Given a container uuid, or biblographic uuid, returns a
    # list of mods uuids. 
    # optional boolean only_image and only_link parameters to only return those items with imageID and a HighResLink respectively
    def get_capture_items(c_uuid, only_image=true, only_link=true)
      url = "http://api.repo.nypl.org/api/v1/items/#{c_uuid}.json?per_page=500"
      json = self.get_json(url)
      captures = []
      capture = json["nyplAPI"]["response"]["capture"]
      captures << capture

      totalPages = json["nyplAPI"]["request"]["totalPages"].to_i
      if totalPages >= 2
        (2..totalPages).each do | page |
          newurl = url + "&page=#{page}"
          json = self.get_json(newurl)
          newcapture = json["nyplAPI"]["response"]["capture"]
          captures << newcapture
        end
      end
      captures.flatten!
      filtered_captures = []
      captures.each do | c |
        next if c["imageID"].nil? && only_image
        next if c["highResLink"].nil? && only_link
      filtered_captures << c
      end

      filtered_captures
    end

    #get the item detail from a uuid
    def get_mods_item(mods_uuid)
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
    def get_mods_uuid(bibl_uuid, image_id)
     url = "http://api.repo.nypl.org/api/v1/items/#{bibl_uuid}.json?per_page=500"
     json = self.get_json(url)
     mods_uuid = nil
   
     json["nyplAPI"]["response"]["capture"].each do | capture|
       if capture["imageID"] == image_id
         mods_uuid = capture["uuid"]
         break
       end #if
     end if json["nyplAPI"]["response"]["numResults"].to_i > 0


     return mods_uuid
    end

    # gets the image id for an item based on the the bibliographic uuid (container uuid) and the mods uuid (the actual item)
    #
    def get_image_id(bibl_uuid, mods_uuid)
      url = "http://api.repo.nypl.org/api/v1/items/#{bibl_uuid}.json?per_page=500"
      json = self.get_json(url)
      image_id = nil
      
      json["nyplAPI"]["response"]["capture"].each do | capture|
      if capture["uuid"] == mods_uuid
        image_id = capture["imageID"]
        break
      end #if
      end if json["nyplAPI"]["response"]["numResults"].to_i > 0

      return image_id
    end


    # get bibliographic container uuid from an image_id
    def get_bibl_uuid(image_id)
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
    def get_highreslink(bibl_uuid, image_id)
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


    def get_json(url)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)

      headers = { "Authorization" => "Token token=#{@token}" }
      request = Net::HTTP::Get.new(uri.request_uri, headers)
      response = http.request(request)
      body = response.body
      json = JSON.parse(body)

      return json
    end

end
end



