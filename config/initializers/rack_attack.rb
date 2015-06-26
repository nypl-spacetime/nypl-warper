module Rack::Attack
  # Expose the warper app so we can call it
  class << self
    attr_accessor :app
    def app
      @app
    end
  end
end

Rack::Attack.cache.store = ActiveSupport::Cache::RedisStore.new("127.0.0.1")

#general rate limiting 300 requests in 5 minutes
#Rack::Attack.throttle('req/ip', :limit => 300, :period => 5.minutes) do |req|
#  req.ip + req.user_agent unless req.path.include?("/assets") || req.path.include?("/wms") || req.path.include?("/tile")
#end

#  Attacks on logins
Rack::Attack.throttle('logins/ip', :limit => 5, :period => 20.seconds) do |req|
  if req.path.include?('/u/sign_in') && req.post?
    req.ip + req.user_agent.to_s
  end
end

#  Limiting other requests, posts
Rack::Attack.throttle('warper/post_request', :limit => 5, :period => 20.seconds) do |req|
  if req.path.include?("/rectify") || 
      req.path.include?("/save_mask_and_warp") || 
      req.path.include?("/comments") ||
      req.path.include?("/gcps/add")  && req.post?
    req.ip + req.user_agent.to_s
  end
end

#  Limiting other requests, puts
Rack::Attack.throttle('warper/put_request', :limit => 5, :period => 20.seconds) do |req|
  if req.path.include?("/rectify") || req.path.include?("/gcps/update") | req.path.include?("/comments") && req.put?
    req.ip + req.user_agent.to_s
  end
end

#  Limiting requests, admin throttle test
Rack::Attack.throttle('admin/throttletest', :limit => 2, :period => 10.seconds) do |req|
  if req.path.include?('/admin/throttle_test') && req.get?
    req.ip + req.user_agent.to_s
  end
end

Rack::Attack.throttled_response = lambda do |env|
  throttled_delay = 2
  puts "throttled response with delay #{throttled_delay}" 
  sleep(throttled_delay)
  
  puts body = [
    env['rack.attack.matched'],
    env['rack.attack.match_type'],
    env['rack.attack.match_data']
  ].inspect
  
  if env['rack.attack.matched'] == "admin/throttletest" 
    puts "allowing call"
    Rack::Attack.app.call(env)
  else
    [ 503, {}, nil]
  end
  
end