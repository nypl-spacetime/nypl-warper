namespace :warper do

  desc "seeds tiles using tilestache to S3 from a map or layer"
  task :tilestache_seed => :environment do
    
    unless  ENV["id"] && ENV["type"] && ["map", "layer"].include?(ENV["type"])
      puts "usage: rake warper:tilestache_seed  type=map|layer id=123"
      break
    end
    
    item = Map.find_by_id(ENV["id"]) if ENV["type"] == "map"
    item = Layer.find_by_id(ENV["id"]) if ENV["type"] == "layer"
    
    item.tilestache_seed
  end
end