module Tilestache
  require "open3"
  extend ActiveSupport::Concern
  
  def tilestache_seed
    secret = ENV['s3_tiles_secret_access_key'] || APP_CONFIG['s3_tiles_secret_access_key'] 
    key_id = ENV['s3_tiles_access_key_id'] || APP_CONFIG['s3_tiles_access_key_id'] 
    bucket_name = ENV['s3_tiles_bucket_name'] || APP_CONFIG['s3_tiles_bucket_name']
    bucket_path = ENV['s3_tiles_bucket_path'] || APP_CONFIG['s3_tiles_bucket_path']
    max_zoom = ENV['s3_tiles_max_zoom'] || APP_CONFIG['s3_tiles_max_zoom'] #i.e. 21
    
    if max_zoom == "" || max_zoom.to_i > 25
      max_zoom = 21
    end
    
    item_type  = self.class.to_s.downcase
    item_id =  self.id
    
    options = {
      :item_type => item_type, 
      :item_id => item_id, 
      :secret => secret, 
      :access => key_id, 
      :bucket => bucket_name,
      :path => bucket_path
      }
   
    config_json = tilestache_config_json(options)
    
    config_file = File.join(Rails.root, 'tmp', "#{options[:item_type]}_#{options[:item_id]}_tilestache.json")
    File.open(config_file, "w+") do |f|
      f.write(config_json)
    end

    bbox = self.bbox.split(",")
    tile_bbox = bbox[1],bbox[0],bbox[3],bbox[2]
    tile_bbox_str = tile_bbox.join(" ")
    
    layer_name = self.id.to_s
    layer_name = "map-"+ layer_name if options[:item_type] == "map"
    
    command = "cd #{APP_CONFIG['tilestache_path']}; python scripts/tilestache-seed.py -c #{config_file}" +
      " -l #{layer_name} -b #{tile_bbox_str} --enable-retries -x #{(1..max_zoom.to_i).to_a.join(' ')}"
    
    puts command
    
    t_stdout, t_stderr, t_status = Open3.capture3( command )

    unless t_status.success?
      
      puts t_stderr

      return nil
    else
       return true
    end
    
    
  end
  
  
  private
  
  def tilestache_config_json(options)

    url = "http://#{APP_CONFIG['host']}#{ActionController::Base.relative_url_root.to_s}/#{options[:item_type]}s/tile/#{options[:item_id]}/{Z}/{X}/{Y}.png"
    
    layer_name = options[:item_id].to_s
    layer_name = "map-"+ layer_name if options[:item_type] == "map"
    
    config = {
      "cache" => {
        "name" => "S3",
        "bucket" => options[:bucket],
        "access" => options[:access],
        "secret" => options[:secret],
        "path" => options[:path]
      },
      "layers" => {
        layer_name => {       
          "provider" => {
            "name" => "proxy", 
            "url" =>  url
          }
        }
      }
    }
    
#    test_config = {
#      "cache" => {
#        "name" => "Test",
#        "path" => "/tmp/stache"
#      },
#      "layers" => {
#        layer_name => {       
#          "provider" => {
#            "name" => "proxy", 
#            "url" =>  url
#          }
#        }
#      }
#    }
    
    JSON.pretty_generate(config)
  end
  
end 
