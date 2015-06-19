namespace :warper do
  require "open3"

  def tilestache_config_json(options)
    
    url = "http://#{APP_CONFIG['host']}/#{options[:item_type]}s/tile/#{options[:item_id]}/{Z}/{X}/{Y}.png"
    
    config = {
      "cache" => {
        "name" => "S3",
        "bucket" => options[:bucket],
        "access" => options[:access],
        "secret" => options[:secret]
      },
      "layers" => {
        options[:item_id] => {       
          "provider" => {
            "name" => "proxy", 
            "url" =>  url
          }
        }
      }
    }
    
    JSON.pretty_generate(config)
  end
  
  desc "seeds tiles using tilestacshe from a map or layer"
  task :tilestache_seed => :environment do
    
    unless  ENV["id"] && ENV["type"] && ["map", "layer"].include?(ENV["type"])
      puts "usage: rake warper:tilestache_seed  type=map|layer id=123"
      break
    end
    
    secret = ENV['s3_tiles_secret_access_key'] || APP_CONFIG['s3_tiles_secret_access_key'] 
    key_id = ENV['s3_tiles_access_key_id'] || APP_CONFIG['s3_tiles_access_key_id'] 
    bucket_name = ENV['s3_tiles_bucket_name'] || APP_CONFIG['s3_tiles_bucket_name']
    
    options = {:item_type => ENV["type"], :item_id => ENV["id"], :secret => secret, :access => key_id, :bucket => bucket_name}
    config_json = tilestache_config_json(options)
    
    config_file = File.join(Rails.root, 'tmp', "#{options[:item_type]}_#{options[:item_id]}_tilestache.json")
    File.open(config_file, "w+") do |f|
      f.write(config_json)
    end
    item = Map.find_by_id(ENV["id"]) if ENV["type"] == "map"
    item = Layer.find_by_id(ENV["id"]) if ENV["type"] == "layer"
    bbox = item.bbox.split(",")
    tile_bbox = bbox[1],bbox[0],bbox[3],bbox[2]
    tile_bbox_str = tile_bbox.join(" ")
    
    command = "cd #{APP_CONFIG['tilestache_path']}; python scripts/tilestache-seed.py -c #{config_file} -l #{item.id} -b #{tile_bbox_str} --enable-retries -x 1 2 3 4 5 6 7 8 9 10 11 12 13"
    puts command
    
    t_stdout, t_stderr = Open3.capture3( command )
    
    puts t_stdout
    puts t_stderr
  end
end