class NyplRepo

  # get uuid from an image_id
  def self.get_uuid(image_id)
    url = "http://api.repo.nypl.org/api/v1/items/local_image_id/#{image_id}.json"   
    json = self.get_json(url)
    if json["nyplAPI"]["response"]["numResults"].to_i > 0
      uuid = json["nyplAPI"]["response"]["uuid"]
    else
      uuid = nil
    end
   
    return uuid
  end

  #gets imageid from an item
  def self.get_image_id(uuid)
    url = "http://api.repo.nypl.org/api/v1/items/#{uuid}.json"
    json = self.get_json(url)
    image_id = json["nyplAPI"]["response"]["capture"][0]["imageID"]

    return image_id
  end


  #get highreslink from an item
  def self.get_highreslink(uuid)
    url = "http://api.repo.nypl.org/api/v1/items/#{uuid}.json"
    json = self.get_json(url)
    if json["nyplAPI"]["response"]["numResults"].to_i > 0
      highreslink = json["nyplAPI"]["response"]["capture"][0]["highResLink"]
    else
      highreslink = nil
    end
    
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
