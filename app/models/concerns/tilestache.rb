require 'rmagick'

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

    # ==============================================================================
    # Code to compute max_zoom
    # uses width of map in pixels, and width of map in degrees
    if self.class.to_s == "Map"
      warped_filename = self.warped_filename
    else
      warped_filename = self.maps.select {|m| m.map_type == :is_map}.first.warped_filename
    end

    if warped_filename
      tile_width = 256.0
      im = Magick::Image.read(warped_filename).first
      bbox = RGeo::Cartesian::BoundingBox.create_from_geometry(self.bbox_geom)

      pixel_width = im.columns
      degree_width = bbox.x_span

      # TODO: OR FLOOR?!
      max_tiles_x = (pixel_width / tile_width).ceil # 39

      max_zoom = compute_max_zoom(max_tiles_x, degree_width)

      max_zoom= add_zoom_levels(max_zoom)
    end
    # ==============================================================================

    item_type  = self.class.to_s.downcase
    item_id =  self.id

    options = {
      :item_type => item_type,
      :item_id => item_id,
      :secret => secret,
      :access => key_id,
      :bucket => bucket_name,
      :max_zoom => max_zoom,
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

      send_tile_config(options)

      return true
    end


  end


  private

  def add_zoom_levels(zoom)
    # adds zoom levels to allow for deeper zoom despite the geotiff not being high-res enough
    new_zoom = zoom
    if zoom >= 1 && zoom <= 7
      new_zoom = new_zoom + 3
    elsif zoom >= 8 && zoom <= 10
      new_zoom = new_zoom + 2
    elsif zoom >= 11 && zoom <= 20
      new_zoom = new_zoom + 1
    end
    if new_zoom >= 19
      new_zoom = 21
    end
    return new_zoom
  end

  def compute_max_zoom(max_tiles_x, degree_width)
    n = max_tiles_x / (degree_width / 360.0)
    zoom = Math.log(n, 2).ceil

    # n = 39 / (0.009768375864808831 / 360)
    # n == 1437291.1315359962
    # n = 2.0 ** zoom
    # zoom = ln(n) / ln(2)

    # TODO: do for both lat and long? and then take minimum?

    return zoom
  end

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

    JSON.pretty_generate(config)
  end

  def send_tile_config(options)
    bucket_name = options[:bucket]
    access = options[:access]
    secret = options[:secret]
    path = options[:path]

    service = S3::Service.new(:access_key_id =>access, :secret_access_key => secret)
    bucket = service.buckets.find(bucket_name)

    layer_name = options[:item_id].to_s
    layer_name = "map-"+ layer_name if options[:item_type] == "map"

    tile_config_filename = "#{layer_name}spec.json"
    tile_config_file = layer_name + "/" + tile_config_filename
    tile_config_file = path + "/"+ tile_config_file unless path.blank?

    the_json = tile_config_json(options)

    config_file = File.join(Rails.root, 'tmp', tile_config_filename)
    File.open(config_file, "w+") do |f|
      f.write(the_json)
    end

    new_object = bucket.objects.build(tile_config_file)
    new_object.content = open("tmp/#{tile_config_filename}")
    new_object.save

  end

  #config file to be sent to s3 as well
  def tile_config_json(options)
    layer_name = options[:item_id].to_s
    layer_name = "map-"+ layer_name if options[:item_type] == "map"

    name = self.title if options[:item_type] == "map"
    name = self.name if options[:item_type] == "layer"
    max_zoom = options[:max_zoom].to_i || 21

    description  = self.description

    attribution ="From: <a href='http://digitalcollections.nypl.org/items/#{self.uuid}'>NYPL Digital Collections</a> | <a href='http://maps.nypl.org/warper/#{self.class.to_s.downcase}s/#{self.id}/'>Warper</a> "

    bbox = self.bbox.split(",")

    tile_bbox = [bbox[0].to_f,bbox[1].to_f,bbox[2].to_f,bbox[3].to_f]

    centroid_y = tile_bbox[1] + ((tile_bbox[3] -  tile_bbox[1]) / 2)
    centroid_x = tile_bbox[0] + ((tile_bbox[2] -  tile_bbox[0]) / 2)

    config = {
      "tilejson"      => "2.0.0",
      "autoscale"   => true,
      "name"        => "#{name}",
      "description" => "#{description}",
      "version"     => "1.5.0",
      "attribution" => "#{attribution}",
      "scheme"      => "xyz",
      "tiles"       => ["http://maptiles.nypl.org/#{layer_name}/{z}/{x}/{y}.png"],
      "minzoom"     => 1,
      "maxzoom"     => max_zoom,
      "bounds"      => tile_bbox,
      "center"      => [centroid_x, centroid_y, max_zoom ]
    }

    return JSON.pretty_generate(config)

  end
end
