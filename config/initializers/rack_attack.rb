class Rack::Attack
  # general rate limiting 300 requests in 5 minutes
  throttle('req/ip', :limit => 300, :period => 5.minutes) do |req|
    req.ip + req.user_agent unless req.path.include?("/assets") || req.path.include?("/wms") || req.path.include?("/tile")
  end

  throttle('logins/ip', :limit => 5, :period => 20.seconds) do |req|
    if req.path.include?('/u/sign_in') && req.post?
      req.ip + req.user_agent
    end
  end
  
  #rate limiting other requests 
  throttle('warper/post_request', :limit => 5, :period => 20.seconds) do |req|
    if req.path.include?("/rectify") || 
        req.path.include?("/save_mask_and_warp") || 
        req.path.include?("/comments") ||
        req.path.include?("/gcps/add")  && req.post?
      req.ip + req.user_agent
    end
  end
  
  
  throttle('warper/put_request', :limit => 5, :period => 20.seconds) do |req|
    if req.path.include?("/rectify") || req.path.include?("/gcps/update") | req.path.include?("/comments") && req.put?
      req.ip + req.user_agent
    end
  end
  
end